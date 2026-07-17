// currency.swift
import Foundation

let API_URL = "https://api.exchangerate.host/latest?base=USD"
let CACHE_TTL: TimeInterval = 60
var ratesCache: [String: Double]? = nil
var cacheTime: Date? = nil
var history: [(amount: Double, fromCur: String, toCur: String, result: Double, time: String)] = []

func getRates() -> [String: Double]? {
    let now = Date()
    if let rates = ratesCache, let time = cacheTime, now.timeIntervalSince(time) < CACHE_TTL {
        return rates
    }
    guard let url = URL(string: API_URL) else { return nil }
    let semaphore = DispatchSemaphore(value: 0)
    var resultRates: [String: Double]? = nil
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        defer { semaphore.signal() }
        guard let data = data, error == nil else { return }
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success,
               let rates = json["rates"] as? [String: Double] {
                ratesCache = rates
                cacheTime = now
                resultRates = rates
            }
        } catch {}
    }
    task.resume()
    semaphore.wait()
    return resultRates
}

func convert(amount: Double, fromCur: String, toCur: String) -> Double? {
    guard let rates = getRates() else { return nil }
    guard let fromRate = rates[fromCur] else {
        print("Currency '\(fromCur)' not supported.")
        return nil
    }
    guard let toRate = rates[toCur] else {
        print("Currency '\(toCur)' not supported.")
        return nil
    }
    let usdAmount = fromCur == "USD" ? amount : amount / fromRate
    return toCur == "USD" ? usdAmount : usdAmount * toRate
}

func addHistory(amount: Double, fromCur: String, toCur: String, result: Double) {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    let timeStr = formatter.string(from: Date())
    history.append((amount, fromCur, toCur, result, timeStr))
    if history.count > 10 { history.removeFirst() }
}

func showHistory() {
    if history.isEmpty {
        print("No conversions yet.")
        return
    }
    print("\n--- History ---")
    for h in history {
        print("\(h.time)  \(String(format: "%.2f", h.amount)) \(h.fromCur) = \(String(format: "%.2f", h.result)) \(h.toCur)")
    }
}

func interactive() {
    print("=== Currency Converter ===")
    while true {
        print("\n1. Convert")
        print("2. Show history")
        print("3. Exit")
        print("Choose: ", terminator: "")
        guard let choice = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
        switch choice {
        case "1":
            print("Amount: ", terminator: "")
            guard let amountStr = readLine(), let amount = Double(amountStr), amount >= 0 else {
                print("Invalid amount.")
                continue
            }
            print("From (USD): ", terminator: "")
            let fromCur = readLine()?.trimmingCharacters(in: .whitespaces).uppercased() ?? "USD"
            print("To: ", terminator: "")
            guard let toCur = readLine()?.trimmingCharacters(in: .whitespaces).uppercased(), !toCur.isEmpty else {
                print("Please enter a target currency.")
                continue
            }
            if let result = convert(amount: amount, fromCur: fromCur, toCur: toCur) {
                print(String(format: "%.2f %@ = %.2f %@", amount, fromCur, result, toCur))
                addHistory(amount: amount, fromCur: fromCur, toCur: toCur, result: result)
            }
        case "2":
            showHistory()
        case "3":
            print("Goodbye!")
            return
        default:
            print("Invalid choice.")
        }
    }
}

func cli() {
    let args = CommandLine.arguments.dropFirst()
    if args.count != 3 {
        print("Usage: swift currency.swift <amount> <from_currency> <to_currency>")
        exit(1)
    }
    guard let amount = Double(args[0]), amount >= 0 else {
        print("Invalid amount.")
        exit(1)
    }
    let fromCur = args[1].uppercased()
    let toCur = args[2].uppercased()
    if let result = convert(amount: amount, fromCur: fromCur, toCur: toCur) {
        print(String(format: "%.2f %@ = %.2f %@", amount, fromCur, result, toCur))
    }
}

if CommandLine.arguments.count == 1 {
    interactive()
} else {
    cli()
}
