// Currency.cs
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

class CurrencyConverter
{
    private static readonly HttpClient client = new HttpClient();
    private static readonly string ApiUrl = "https://api.exchangerate.host/latest?base=USD";
    private static readonly TimeSpan CacheTTL = TimeSpan.FromSeconds(60);
    private static Dictionary<string, double> _rates;
    private static DateTime _cacheTime;
    private static List<(double amount, string from, string to, double result, string time)> _history = new();

    static async Task<Dictionary<string, double>> GetRates()
    {
        var now = DateTime.UtcNow;
        if (_rates != null && (now - _cacheTime) < CacheTTL)
            return _rates;

        var response = await client.GetAsync(ApiUrl);
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<RatesResponse>(json);
        if (!data.Success)
            throw new Exception("API error");
        _rates = data.Rates;
        _cacheTime = now;
        return _rates;
    }

    public static async Task<double> ConvertAsync(double amount, string fromCur, string toCur)
    {
        var rates = await GetRates();
        if (!rates.ContainsKey(fromCur))
            throw new Exception($"Currency '{fromCur}' not supported.");
        if (!rates.ContainsKey(toCur))
            throw new Exception($"Currency '{toCur}' not supported.");
        double usdAmount = fromCur == "USD" ? amount : amount / rates[fromCur];
        return toCur == "USD" ? usdAmount : usdAmount * rates[toCur];
    }

    static void AddHistory(double amount, string fromCur, string toCur, double result)
    {
        _history.Add((amount, fromCur, toCur, result, DateTime.Now.ToString("HH:mm:ss")));
        if (_history.Count > 10) _history.RemoveAt(0);
    }

    static void ShowHistory()
    {
        if (_history.Count == 0)
        {
            Console.WriteLine("No conversions yet.");
            return;
        }
        Console.WriteLine("\n--- History ---");
        foreach (var h in _history)
            Console.WriteLine($"{h.time}  {h.amount:F2} {h.from} = {h.result:F2} {h.to}");
    }

    static async Task Interactive()
    {
        Console.WriteLine("=== Currency Converter ===");
        while (true)
        {
            Console.WriteLine("\n1. Convert");
            Console.WriteLine("2. Show history");
            Console.WriteLine("3. Exit");
            Console.Write("Choose: ");
            string choice = Console.ReadLine()?.Trim() ?? "";
            switch (choice)
            {
                case "1":
                    Console.Write("Amount: ");
                    if (!double.TryParse(Console.ReadLine(), out double amount) || amount < 0)
                    {
                        Console.WriteLine("Invalid amount.");
                        continue;
                    }
                    Console.Write("From (USD): ");
                    string fromCur = Console.ReadLine()?.Trim().ToUpper() ?? "USD";
                    if (string.IsNullOrEmpty(fromCur)) fromCur = "USD";
                    Console.Write("To: ");
                    string toCur = Console.ReadLine()?.Trim().ToUpper() ?? "";
                    if (string.IsNullOrEmpty(toCur))
                    {
                        Console.WriteLine("Please enter a target currency.");
                        continue;
                    }
                    try
                    {
                        double result = await ConvertAsync(amount, fromCur, toCur);
                        Console.WriteLine($"{amount:F2} {fromCur} = {result:F2} {toCur}");
                        AddHistory(amount, fromCur, toCur, result);
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine($"Error: {e.Message}");
                    }
                    break;
                case "2":
                    ShowHistory();
                    break;
                case "3":
                    Console.WriteLine("Goodbye!");
                    return;
                default:
                    Console.WriteLine("Invalid choice.");
                    break;
            }
        }
    }

    static async Task Cli(string[] args)
    {
        if (args.Length != 3)
        {
            Console.WriteLine("Usage: Currency.exe <amount> <from_currency> <to_currency>");
            return;
        }
        if (!double.TryParse(args[0], out double amount) || amount < 0)
        {
            Console.WriteLine("Invalid amount.");
            return;
        }
        string fromCur = args[1].ToUpper();
        string toCur = args[2].ToUpper();
        try
        {
            double result = await ConvertAsync(amount, fromCur, toCur);
            Console.WriteLine($"{amount:F2} {fromCur} = {result:F2} {toCur}");
        }
        catch (Exception e)
        {
            Console.WriteLine($"Error: {e.Message}");
        }
    }

    static async Task Main(string[] args)
    {
        if (args.Length == 0)
            await Interactive();
        else
            await Cli(args);
    }

    class RatesResponse
    {
        public bool Success { get; set; }
        public Dictionary<string, double> Rates { get; set; }
    }
}
