package main

import (
	"bufio"
	"context"
	"encoding/hex"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	_ "github.com/mattn/go-sqlite3"
	"github.com/mdp/qrterminal/v3"
	"go.mau.fi/whatsmeow"
	"go.mau.fi/whatsmeow/proto/waE2E"
	"go.mau.fi/whatsmeow/store/sqlstore"
	"go.mau.fi/whatsmeow/types"
	"go.mau.fi/whatsmeow/types/events"
	waLog "go.mau.fi/whatsmeow/util/log"
	"google.golang.org/protobuf/proto"
)

var client *whatsmeow.Client

func eventHandler(evt interface{}) {
	switch v := evt.(type) {
	case *events.Message:
		fmt.Printf("\n📩 Received message from %s\n", v.Info.Sender)
		if v.Message.GetConversation() != "" {
			fmt.Printf("   Text: %s\n", v.Message.GetConversation())
		}
	case *events.Receipt:
		fmt.Printf("\n✅ Receipt: %s from %s\n", v.Type, v.Chat)
	case *events.Connected:
		fmt.Println("\n✅ Connected!")
	case *events.Disconnected:
		fmt.Println("\n❌ Disconnected!")
	case *events.LoggedOut:
		fmt.Printf("\n🚪 Logged out: %+v\n", v)
	}
}

func main() {
	// Enable debug logging - set to DEBUG to see Signal protocol details
	dbLog := waLog.Stdout("Database", "INFO", true)
	clientLog := waLog.Stdout("Client", "DEBUG", true)

	ctx := context.Background()

	// Create database for storing session
	container, err := sqlstore.New(ctx, "sqlite3", "file:debug_session.db?_foreign_keys=on", dbLog)
	if err != nil {
		panic(err)
	}

	// Get device store
	deviceStore, err := container.GetFirstDevice(ctx)
	if err != nil {
		panic(err)
	}

	// Create client
	client = whatsmeow.NewClient(deviceStore, clientLog)
	client.AddEventHandler(eventHandler)

	// Connect
	if client.Store.ID == nil {
		// No ID stored, need to login via QR
		qrChan, _ := client.GetQRChannel(context.Background())
		err = client.Connect()
		if err != nil {
			panic(err)
		}

		for evt := range qrChan {
			if evt.Event == "code" {
				fmt.Println("\n📱 Scan this QR code with WhatsApp:")
				qrterminal.GenerateHalfBlock(evt.Code, qrterminal.L, os.Stdout)
			} else {
				fmt.Printf("QR event: %s\n", evt.Event)
			}
		}
	} else {
		// Already logged in
		fmt.Printf("Already logged in as: %s\n", client.Store.ID)
		err = client.Connect()
		if err != nil {
			panic(err)
		}
	}

	// Wait for connection to stabilize
	fmt.Println("\n⏳ Waiting for connection to stabilize...")
	time.Sleep(3 * time.Second)

	// Interactive mode
	go interactiveMode()

	// Wait for interrupt signal
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	<-c

	client.Disconnect()
	fmt.Println("\nGoodbye!")
}

func interactiveMode() {
	reader := bufio.NewReader(os.Stdin)
	fmt.Println("\n📤 Interactive Mode")
	fmt.Println("Commands:")
	fmt.Println("  send <phone> <message>  - Send a message (e.g., send 393791383728 Hello)")
	fmt.Println("  quit                    - Exit")
	fmt.Println("")

	for {
		fmt.Print("> ")
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(input)

		if input == "" {
			continue
		}

		parts := strings.SplitN(input, " ", 3)
		cmd := parts[0]

		switch cmd {
		case "quit", "exit", "q":
			os.Exit(0)

		case "send":
			if len(parts) < 3 {
				fmt.Println("Usage: send <phone> <message>")
				continue
			}
			phone := parts[1]
			message := parts[2]
			sendMessage(phone, message)

		default:
			fmt.Printf("Unknown command: %s\n", cmd)
		}
	}
}

func sendMessage(phone, text string) {
	// Parse JID
	targetJID := types.NewJID(phone, types.DefaultUserServer)

	fmt.Printf("\n🔐 Sending message to: %s\n", targetJID)
	fmt.Printf("📝 Message: %s\n", text)

	// Create a simple text message
	msg := &waE2E.Message{
		Conversation: proto.String(text),
	}

	// Marshal the message to see its protobuf representation
	msgBytes, _ := proto.Marshal(msg)
	fmt.Printf("\n📦 Message protobuf (%d bytes):\n", len(msgBytes))
	fmt.Println(hex.Dump(msgBytes))

	// Send with detailed logging
	resp, err := client.SendMessage(context.Background(), targetJID, msg)
	if err != nil {
		fmt.Printf("❌ Error sending message: %v\n", err)
	} else {
		fmt.Printf("✅ Message sent! ID: %s, Timestamp: %v\n", resp.ID, resp.Timestamp)
	}
}

// Helper to dump bytes as hex
func dumpHex(name string, data []byte) {
	fmt.Printf("\n=== %s (%d bytes) ===\n", name, len(data))
	fmt.Println(hex.Dump(data))
}
