// currency.go
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

type RatesResponse struct {
	Success bool               `json:"success"`
	Rates   map[string]float64 `json:"rates"`
}

var (
	apiURL    = "https://api.exchangerate.host/latest?base=USD"
	cache     map[string]float64
	cacheTime time.Time
	ttl       = 60 * time.Second
	history   []struct {
		Amount   float64
		From, To string
		Result   float64
		Time     string
	}
)

func getRates() (map[string]float64, error) {
	now := time.Now()
	if cache != nil && now.Sub(cacheTime) < ttl {
		return cache, nil
	}
	resp, err := http.Get(apiURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	var data RatesResponse
	if err := json.Unmarshal(body, &data); err != nil {
		return nil, err
	}
	if !data.Success {
		return nil, fmt.Errorf("API error")
	}
	cache = data.Rates
	cacheTime = now
	return cache, nil
}

func convert(amount float64, fromCur, toCur string) (float64, error) {
	rates, err := getRates()
	if err != nil {
		return 0, err
	}
	fromRate, ok := rates[fromCur]
	if !ok {
		return 0, fmt.Errorf("currency '%s' not supported", fromCur)
	}
	toRate, ok := rates[toCur]
	if !ok {
		return 0, fmt.Errorf("currency '%s' not supported", toCur)
	}
	usdAmount := amount
	if fromCur != "USD" {
		usdAmount = amount / fromRate
	}
	result := usdAmount
	if toCur != "USD" {
		result = usdAmount * toRate
	}
	return result, nil
}

func addHistory(amount float64, fromCur, toCur string, result float64) {
	history = append(history, struct {
		Amount   float64
		From, To string
		Result   float64
		Time     string
	}{amount, fromCur, toCur, result, time.Now().Format("15:04:05")})
	if len(history) > 10 {
		history = history[1:]
	}
}

func showHistory() {
	if len(history) == 0 {
		fmt.Println("No conversions yet.")
		return
	}
	fmt.Println("\n--- History ---")
	for _, h := range history {
		fmt.Printf("%s  %.2f %s = %.2f %s\n", h.Time, h.Amount, h.From, h.Result, h.To)
	}
}

func interactive() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("=== Currency Converter ===")
	for {
		fmt.Println("\n1. Convert")
		fmt.Println("2. Show history")
		fmt.Println("3. Exit")
		fmt.Print("Choose: ")
		scanner.Scan()
		choice := strings.TrimSpace(scanner.Text())
		switch choice {
		case "1":
			fmt.Print("Amount: ")
			scanner.Scan()
			amountStr := strings.TrimSpace(scanner.Text())
			amount, err := strconv.ParseFloat(amountStr, 64)
			if err != nil {
				fmt.Println("Invalid amount.")
				continue
			}
			fmt.Print("From (USD): ")
			scanner.Scan()
			fromCur := strings.ToUpper(strings.TrimSpace(scanner.Text()))
			if fromCur == "" {
				fromCur = "USD"
			}
			fmt.Print("To: ")
			scanner.Scan()
			toCur := strings.ToUpper(strings.TrimSpace(scanner.Text()))
			if toCur == "" {
				fmt.Println("Please enter a target currency.")
				continue
			}
			result, err := convert(amount, fromCur, toCur)
			if err != nil {
				fmt.Println("Error:", err)
				continue
			}
			fmt.Printf("%.2f %s = %.2f %s\n", amount, fromCur, result, toCur)
			addHistory(amount, fromCur, toCur, result)
		case "2":
			showHistory()
		case "3":
			fmt.Println("Goodbye!")
			return
		default:
			fmt.Println("Invalid choice.")
		}
	}
}

func cli() {
	if len(os.Args) != 4 {
		fmt.Println("Usage: go run currency.go <amount> <from_currency> <to_currency>")
		os.Exit(1)
	}
	amount, err := strconv.ParseFloat(os.Args[1], 64)
	if err != nil {
		fmt.Println("Invalid amount.")
		os.Exit(1)
	}
	fromCur := strings.ToUpper(os.Args[2])
	toCur := strings.ToUpper(os.Args[3])
	result, err := convert(amount, fromCur, toCur)
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}
	fmt.Printf("%.2f %s = %.2f %s\n", amount, fromCur, result, toCur)
}

func main() {
	if len(os.Args) == 1 {
		interactive()
	} else {
		cli()
	}
}
