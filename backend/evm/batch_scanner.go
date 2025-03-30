package evm

import (
	"fmt"
	"math/big"
	"os"
	"sync"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// ContractEventConfig represents a configuration for scanning events from a contract
type ContractEventConfig struct {
	ContractAddress common.Address
	EventTypes      []EventType
	FromBlock       *big.Int
	ToBlock         *big.Int
}

// BatchScanEvents scans multiple contracts for multiple event types in parallel and returns the results
func BatchScanEvents(configs []ContractEventConfig) ([]TransferEvent, []ApprovalEvent, error) {
	// Get RPC URL from environment variable
	rpcURL := os.Getenv("ETH_RPC_URL")
	if rpcURL == "" {
		return nil, nil, fmt.Errorf("ETH_RPC_URL environment variable not set")
	}

	// Connect to Ethereum client
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to connect to the Ethereum client: %v", err)
	}

	// Calculate appropriate buffer size based on number of contracts and event types
	totalEventTypes := 0
	for _, config := range configs {
		totalEventTypes += len(config.EventTypes)
	}
	bufferSize := totalEventTypes * 100 // Allocate space for ~100 events per contract/event type

	// Create a channel to receive events with dynamic buffer size
	eventChan := make(chan EventData, bufferSize)

	// Create a wait group to wait for all goroutines to finish
	var wg sync.WaitGroup

	// Start a goroutine for each contract and event type
	for _, config := range configs {
		for _, eventType := range config.EventTypes {
			wg.Add(1)
			go func(contract common.Address, evType EventType, from, to *big.Int) {
				defer wg.Done()
				scanForEvent(client, contract, from, to, evType, eventChan)
			}(config.ContractAddress, eventType, config.FromBlock, config.ToBlock)
		}
	}

	// Start a goroutine to close the channel when all scanners are done
	go func() {
		wg.Wait()
		close(eventChan)
	}()

	// Process events as they come in
	transferEvents, approvalEvents := processEvents(eventChan)

	return transferEvents, approvalEvents, nil
}

// ScanMultipleContracts scans multiple contracts and returns the results
func ScanMultipleContracts(contractAddresses []string, fromBlockStr, toBlockStr string) ([]TransferEvent, []ApprovalEvent, error) {
	// Parse block range
	var fromBlock, toBlock *big.Int
	if fromBlockStr != "" {
		fromBlock = new(big.Int)
		fromBlock.SetString(fromBlockStr, 10)
	} else {
		fromBlock = big.NewInt(0)
	}

	if toBlockStr != "" {
		toBlock = new(big.Int)
		toBlock.SetString(toBlockStr, 10)
	} else {
		toBlock = nil // Latest block
	}

	// Create configs for each contract
	var configs []ContractEventConfig
	for _, addrStr := range contractAddresses {
		addr := common.HexToAddress(addrStr)
		configs = append(configs, ContractEventConfig{
			ContractAddress: addr,
			EventTypes:      []EventType{TransferEventType, ApprovalEventType},
			FromBlock:       fromBlock,
			ToBlock:         toBlock,
		})
	}

	// Batch scan all contracts
	return BatchScanEvents(configs)
}
