// Currency.java
import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.TimeUnit;
import com.google.gson.*;

public class Currency {
    private static final String API_URL = "https://api.exchangerate.host/latest?base=USD";
    private static final long CACHE_TTL_MS = TimeUnit.SECONDS.toMillis(60);
    private static Map<String, Double> rates = null;
    private static long cacheTime = 0;
    private static List<HistoryEntry> history = new ArrayList<>();
    private static Scanner scanner = new Scanner(System.in);
    private static Gson gson = new Gson();

    static class RatesResponse {
        boolean success;
        Map<String, Double> rates;
    }

    static class HistoryEntry {
        double amount;
        String fromCur, toCur;
        double result;
        String time;
        HistoryEntry(double a, String f, String t, double r, String tm) {
            amount = a; fromCur = f; toCur = t; result = r; time = tm;
        }
    }

    static Map<String, Double> getRates() throws Exception {
        long now = Instant.now().toEpochMilli();
        if (rates != null && (now - cacheTime) < CACHE_TTL_MS)
            return rates;

        URL url = new URL(API_URL);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        if (conn.getResponseCode() != 200) {
            throw new Exception("HTTP error: " + conn.getResponseCode());
        }
        try (BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream()))) {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) sb.append(line);
            RatesResponse resp = gson.fromJson(sb.toString(), RatesResponse.class);
            if (!resp.success) throw new Exception("API error");
            rates = resp.rates;
            cacheTime = now;
            return rates;
        }
    }

    static double convert(double amount, String fromCur, String toCur) throws Exception {
        Map<String, Double> rates = getRates();
        if (!rates.containsKey(fromCur))
            throw new Exception("Currency '" + fromCur + "' not supported.");
        if (!rates.containsKey(toCur))
            throw new Exception("Currency '" + toCur + "' not supported.");
        double usdAmount = fromCur.equals("USD") ? amount : amount / rates.get(fromCur);
        return toCur.equals("USD") ? usdAmount : usdAmount * rates.get(toCur);
    }

    static void addHistory(double amount, String fromCur, String toCur, double result) {
        history.add(new HistoryEntry(amount, fromCur, toCur, result, 
            java.time.LocalTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm:ss"))));
        if (history.size() > 10) history.remove(0);
    }

    static void showHistory() {
        if (history.isEmpty()) {
            System.out.println("No conversions yet.");
            return;
        }
        System.out.println("\n--- History ---");
        for (HistoryEntry h : history)
            System.out.printf("%s  %.2f %s = %.2f %s%n", h.time, h.amount, h.fromCur, h.result, h.toCur);
    }

    static void interactive() throws Exception {
        System.out.println("=== Currency Converter ===");
        while (true) {
            System.out.println("\n1. Convert");
            System.out.println("2. Show history");
            System.out.println("3. Exit");
            System.out.print("Choose: ");
            String choice = scanner.nextLine().trim();
            switch (choice) {
                case "1":
                    System.out.print("Amount: ");
                    String amountStr = scanner.nextLine().trim();
                    double amount;
                    try { amount = Double.parseDouble(amountStr); } catch (NumberFormatException e) {
                        System.out.println("Invalid amount.");
                        continue;
                    }
                    if (amount < 0) { System.out.println("Invalid amount."); continue; }
                    System.out.print("From (USD): ");
                    String fromCur = scanner.nextLine().trim().toUpperCase();
                    if (fromCur.isEmpty()) fromCur = "USD";
                    System.out.print("To: ");
                    String toCur = scanner.nextLine().trim().toUpperCase();
                    if (toCur.isEmpty()) { System.out.println("Please enter a target currency."); continue; }
                    try {
                        double result = convert(amount, fromCur, toCur);
                        System.out.printf("%.2f %s = %.2f %s%n", amount, fromCur, result, toCur);
                        addHistory(amount, fromCur, toCur, result);
                    } catch (Exception e) {
                        System.out.println("Error: " + e.getMessage());
                    }
                    break;
                case "2":
                    showHistory();
                    break;
                case "3":
                    System.out.println("Goodbye!");
                    return;
                default:
                    System.out.println("Invalid choice.");
            }
        }
    }

    static void cli(String[] args) throws Exception {
        if (args.length != 3) {
            System.out.println("Usage: java Currency <amount> <from_currency> <to_currency>");
            return;
        }
        double amount;
        try { amount = Double.parseDouble(args[0]); } catch (NumberFormatException e) {
            System.out.println("Invalid amount.");
            return;
        }
        if (amount < 0) { System.out.println("Invalid amount."); return; }
        String fromCur = args[1].toUpperCase();
        String toCur = args[2].toUpperCase();
        try {
            double result = convert(amount, fromCur, toCur);
            System.out.printf("%.2f %s = %.2f %s%n", amount, fromCur, result, toCur);
        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length == 0)
            interactive();
        else
            cli(args);
    }
}
