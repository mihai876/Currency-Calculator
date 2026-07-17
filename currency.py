# currency.py
import sys
import json
import time
import urllib.request
import urllib.error
from datetime import datetime

API_URL = "https://api.exchangerate.host/latest?base=USD"
CACHE_TTL = 60  # seconds
_cache = {"rates": None, "timestamp": 0}
_history = []

def get_rates():
    now = time.time()
    if _cache["rates"] is not None and (now - _cache["timestamp"]) < CACHE_TTL:
        return _cache["rates"]
    try:
        with urllib.request.urlopen(API_URL, timeout=5) as response:
            data = json.loads(response.read().decode())
            if data.get("success"):
                _cache["rates"] = data["rates"]
                _cache["timestamp"] = now
                return _cache["rates"]
            else:
                print("API error")
                return None
    except Exception as e:
        print(f"Error fetching rates: {e}")
        return None

def convert(amount, from_cur, to_cur):
    rates = get_rates()
    if rates is None:
        return None
    if from_cur not in rates:
        print(f"Currency '{from_cur}' not supported.")
        return None
    if to_cur not in rates:
        print(f"Currency '{to_cur}' not supported.")
        return None
    usd_amount = amount / rates[from_cur] if from_cur != "USD" else amount
    result = usd_amount * rates[to_cur] if to_cur != "USD" else usd_amount
    return result

def add_history(amount, from_cur, to_cur, result):
    _history.append((amount, from_cur, to_cur, result, datetime.now().strftime("%H:%M:%S")))
    if len(_history) > 10:
        _history.pop(0)

def show_history():
    if not _history:
        print("No conversions yet.")
        return
    print("\n--- History ---")
    for h in _history:
        print(f"{h[4]}  {h[0]:.2f} {h[1]} = {h[3]:.2f} {h[2]}")

def interactive():
    print("=== Currency Converter ===")
    while True:
        print("\n1. Convert")
        print("2. Show history")
        print("3. Exit")
        choice = input("Choose: ").strip()
        if choice == "1":
            try:
                amount = float(input("Amount: "))
                from_cur = input("From (USD): ").strip().upper() or "USD"
                to_cur = input("To: ").strip().upper()
                if not to_cur:
                    print("Please enter a target currency.")
                    continue
                result = convert(amount, from_cur, to_cur)
                if result is not None:
                    print(f"{amount:.2f} {from_cur} = {result:.2f} {to_cur}")
                    add_history(amount, from_cur, to_cur, result)
            except ValueError:
                print("Invalid amount.")
        elif choice == "2":
            show_history()
        elif choice == "3":
            print("Goodbye!")
            break
        else:
            print("Invalid choice.")

def cli():
    if len(sys.argv) != 4:
        print("Usage: python currency.py <amount> <from_currency> <to_currency>")
        sys.exit(1)
    try:
        amount = float(sys.argv[1])
        from_cur = sys.argv[2].upper()
        to_cur = sys.argv[3].upper()
        result = convert(amount, from_cur, to_cur)
        if result is not None:
            print(f"{amount:.2f} {from_cur} = {result:.2f} {to_cur}")
    except ValueError:
        print("Invalid amount.")

if __name__ == "__main__":
    if len(sys.argv) == 1:
        interactive()
    else:
        cli()
