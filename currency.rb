# currency.rb
require 'net/http'
require 'json'
require 'time'

API_URL = 'https://api.exchangerate.host/latest?base=USD'
CACHE_TTL = 60
$rates = nil
$cache_time = 0
$history = []

def get_rates
  now = Time.now.to_i
  if $rates && (now - $cache_time) < CACHE_TTL
    return $rates
  end
  uri = URI(API_URL)
  begin
    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      if data['success']
        $rates = data['rates']
        $cache_time = now
        return $rates
      else
        raise "API error"
      end
    else
      raise "HTTP error: #{response.code}"
    end
  rescue => e
    puts "Error fetching rates: #{e.message}"
    nil
  end
end

def convert(amount, from_cur, to_cur)
  rates = get_rates
  return nil unless rates
  unless rates.key?(from_cur)
    puts "Currency '#{from_cur}' not supported."
    return nil
  end
  unless rates.key?(to_cur)
    puts "Currency '#{to_cur}' not supported."
    return nil
  end
  usd_amount = from_cur == 'USD' ? amount : amount / rates[from_cur]
  to_cur == 'USD' ? usd_amount : usd_amount * rates[to_cur]
end

def add_history(amount, from_cur, to_cur, result)
  $history << { amount: amount, from: from_cur, to: to_cur, result: result, time: Time.now.strftime('%H:%M:%S') }
  $history.shift if $history.size > 10
end

def show_history
  if $history.empty?
    puts "No conversions yet."
    return
  end
  puts "\n--- History ---"
  $history.each do |h|
    puts "#{h[:time]}  #{'%.2f' % h[:amount]} #{h[:from]} = #{'%.2f' % h[:result]} #{h[:to]}"
  end
end

def interactive
  puts "=== Currency Converter ==="
  loop do
    puts "\n1. Convert"
    puts "2. Show history"
    puts "3. Exit"
    print "Choose: "
    choice = gets.chomp.strip
    case choice
    when '1'
      print "Amount: "
      amount_str = gets.chomp.strip
      begin
        amount = Float(amount_str)
      rescue ArgumentError
        puts "Invalid amount."
        next
      end
      if amount < 0
        puts "Invalid amount."
        next
      end
      print "From (USD): "
      from_cur = gets.chomp.strip.upcase
      from_cur = 'USD' if from_cur.empty?
      print "To: "
      to_cur = gets.chomp.strip.upcase
      if to_cur.empty?
        puts "Please enter a target currency."
        next
      end
      result = convert(amount, from_cur, to_cur)
      if result
        puts "#{'%.2f' % amount} #{from_cur} = #{'%.2f' % result} #{to_cur}"
        add_history(amount, from_cur, to_cur, result)
      end
    when '2'
      show_history
    when '3'
      puts "Goodbye!"
      break
    else
      puts "Invalid choice."
    end
  end
end

def cli
  if ARGV.size != 3
    puts "Usage: ruby currency.rb <amount> <from_currency> <to_currency>"
    exit 1
  end
  begin
    amount = Float(ARGV[0])
  rescue ArgumentError
    puts "Invalid amount."
    exit 1
  end
  if amount < 0
    puts "Invalid amount."
    exit 1
  end
  from_cur = ARGV[1].upcase
  to_cur = ARGV[2].upcase
  result = convert(amount, from_cur, to_cur)
  if result
    puts "#{'%.2f' % amount} #{from_cur} = #{'%.2f' % result} #{to_cur}"
  end
end

if ARGV.empty?
  interactive
else
  cli
end
