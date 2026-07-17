💱 Currency Calculator – Multi‑Language Edition
A versatile currency converter that fetches live exchange rates from the free ExchangeRate.host API, caches them for 60 seconds, and supports both interactive and command‑line modes.
Built in 7 programming languages – each implementation shares the same core features.

✨ Features
Live rates – real‑time exchange rates from a free API (no API key required).

Smart caching – rates are cached for 60 seconds to reduce network calls.

Interactive mode – step‑by‑step conversion with history.

Command‑line mode – quick conversion: convert 100 USD EUR.

History – keeps track of the last 10 conversions (per session).

Supports 160+ currencies – all currencies supported by the API.

Cross‑platform – works on Windows, macOS, Linux.

🗂 Languages & Files
Language	File
Python	currency.py
Go	currency.go
JavaScript (Node)	currency.js
C#	Currency.cs
Java	Currency.java
Ruby	currency.rb
Swift	currency.swift
🚀 How to Run
Each file is standalone – run it with the appropriate interpreter/compiler.

Language	Command
Python	python currency.py
Go	go run currency.go
JavaScript	node currency.js
C#	dotnet run (or csc Currency.cs && Currency.exe)
Java	javac Currency.java && java Currency
Ruby	ruby currency.rb
Swift	swift currency.swift
📊 Example Usage
Interactive Mode
text
$ python currency.py
=== Currency Converter ===
1. Convert
2. Show history
3. Exit
Choose: 1
Amount: 100
From (USD): USD
To (EUR): EUR
100.00 USD = 92.45 EUR
Command‑Line Mode
text
$ python currency.py 100 USD EUR
100.00 USD = 92.45 EUR
🔧 API
Endpoint: https://api.exchangerate.host/latest?base=USD

Rate limit: free tier (no key) – up to 1500 requests per month.

📜 License
MIT – use freely.

