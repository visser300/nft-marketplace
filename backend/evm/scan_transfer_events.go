package evm

import (
	"context"
	"fmt"
	"log"
	"math/big"
	"os"
	"sync"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// EventType represents the type of event to scan for
type EventType string

const (
	// TransferEvent represents an ERC20 transfer event
	TransferEventType EventType = "Transfer"
	// ApprovalEvent represents an ERC20 approval event
	ApprovalEventType EventType = "Approval"
)

// Event signatures
const (
	ERC20TransferSig = "Transfer(address,address,uint256)"
	ERC20ApprovalSig = "Approval(address,address,uint256)"
)

// EventData represents generic event data
type EventData struct {
	EventType    EventType
	ContractAddr common.Address
	BlockNumber  uint64
	TxHash       common.Hash
	Topics       []common.Hash
	Data         []byte
}

// TransferEvent represents an ERC20 transfer event
type TransferEvent struct {
	From         common.Address
	To           common.Address
	Value        *big.Int
	BlockNumber  uint64
	TxHash       common.Hash
	ContractAddr common.Address
}

// ApprovalEvent represents an ERC20 approval event
type ApprovalEvent struct {
	Owner        common.Address
	Spender      common.Address
	Value        *big.Int
	BlockNumber  uint64
	TxHash       common.Hash
	ContractAddr common.Address
}

// ScanTransferEvents scans for ERC20 transfer events and returns the results
func ScanTransferEvents(args []string) ([]TransferEvent, []ApprovalEvent, error) {
	if len(args) < 1 {
		return nil, nil, fmt.Errorf("usage: go run main.go <contract-address> [block-start] [block-end]")
	}

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

	// Parse contract address
	contractAddr := common.HexToAddress(args[0])

	// Parse block range
	var fromBlock, toBlock *big.Int
	if len(args) > 1 {
		fromBlock = new(big.Int)
		fromBlock.SetString(args[1], 10)
	} else {
		fromBlock = big.NewInt(0)
	}

	if len(args) > 2 {
		toBlock = new(big.Int)
		toBlock.SetString(args[2], 10)
	} else {
		toBlock = nil // Latest block
	}

	// Define event types to scan for
	eventTypes := []EventType{TransferEventType, ApprovalEventType}

	// Create a channel to receive events
	eventChan := make(chan EventData, 100)

	// Create a wait group to wait for all goroutines to finish
	var wg sync.WaitGroup

	// Start a goroutine for each event type
	for _, eventType := range eventTypes {
		wg.Add(1)
		go func(evType EventType) {
			defer wg.Done()
			scanForEvent(client, contractAddr, fromBlock, toBlock, evType, eventChan)
		}(eventType)
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

// scanForEvent scans for a specific event type and sends results to the channel
func scanForEvent(client *ethclient.Client, contractAddr common.Address, fromBlock, toBlock *big.Int, eventType EventType, eventChan chan<- EventData) {
	var eventSig string
	switch eventType {
	case TransferEventType:
		eventSig = ERC20TransferSig
	case ApprovalEventType:
		eventSig = ERC20ApprovalSig
	default:
		log.Printf("Unknown event type: %s", eventType)
		return
	}

	// Create event signature hash
	eventSigHash := crypto.Keccak256Hash([]byte(eventSig))

	// Create a query for the event
	query := ethereum.FilterQuery{
		FromBlock: fromBlock,
		ToBlock:   toBlock,
		Addresses: []common.Address{contractAddr},
		Topics:    [][]common.Hash{{eventSigHash}},
	}

	// Get logs
	logs, err := client.FilterLogs(context.Background(), query)
	if err != nil {
		log.Printf("Error filtering logs for %s events: %v", eventType, err)
		return
	}

	log.Printf("Found %d %s events for contract %s", len(logs), eventType, contractAddr.Hex())

	// Send events to channel
	for _, vLog := range logs {
		eventChan <- EventData{
			EventType:    eventType,
			ContractAddr: contractAddr,
			BlockNumber:  vLog.BlockNumber,
			TxHash:       vLog.TxHash,
			Topics:       vLog.Topics,
			Data:         vLog.Data,
		}
	}
}

// processEvents processes events from the channel and returns the results
func processEvents(eventChan <-chan EventData) ([]TransferEvent, []ApprovalEvent) {
	var transferEvents []TransferEvent
	var approvalEvents []ApprovalEvent

	// Process events as they come in
	for event := range eventChan {
		switch event.EventType {
		case TransferEventType:
			if transferEvent, ok := processTransferEvent(event, transferABI); ok {
				// Add block number and tx hash to the event
				transferEvent.BlockNumber = event.BlockNumber
				transferEvent.TxHash = event.TxHash
				transferEvent.ContractAddr = event.ContractAddr
				transferEvents = append(transferEvents, transferEvent)
			}
		case ApprovalEventType:
			if approvalEvent, ok := processApprovalEvent(event, approvalABI); ok {
				// Add block number and tx hash to the event
				approvalEvent.BlockNumber = event.BlockNumber
				approvalEvent.TxHash = event.TxHash
				approvalEvent.ContractAddr = event.ContractAddr
				approvalEvents = append(approvalEvents, approvalEvent)
			}
		}
	}

	return transferEvents, approvalEvents
}

// processTransferEvent processes a Transfer event and returns the event data
func processTransferEvent(event EventData, contractAbi abi.ABI) (TransferEvent, bool) {
	var transferEvent TransferEvent

	// The first topic is the event signature
	// The second topic is the 'from' address (indexed parameter)
	transferEvent.From = common.HexToAddress(event.Topics[1].Hex())
	// The third topic is the 'to' address (indexed parameter)
	transferEvent.To = common.HexToAddress(event.Topics[2].Hex())

	// Unpack the non-indexed parameters (value)
	err := contractAbi.UnpackIntoInterface(&transferEvent, "Transfer", event.Data)
	if err != nil {
		log.Printf("Error unpacking Transfer event: %v", err)
		return TransferEvent{}, false
	}

	return transferEvent, true
}

// processApprovalEvent processes an Approval event and returns the event data
func processApprovalEvent(event EventData, contractAbi abi.ABI) (ApprovalEvent, bool) {
	var approvalEvent ApprovalEvent

	// The first topic is the event signature
	// The second topic is the 'owner' address (indexed parameter)
	approvalEvent.Owner = common.HexToAddress(event.Topics[1].Hex())
	// The third topic is the 'spender' address (indexed parameter)
	approvalEvent.Spender = common.HexToAddress(event.Topics[2].Hex())

	// Unpack the non-indexed parameters (value)
	err := contractAbi.UnpackIntoInterface(&approvalEvent, "Approval", event.Data)
	if err != nil {
		log.Printf("Error unpacking Approval event: %v", err)
		return ApprovalEvent{}, false
	}

	return approvalEvent, true
}
