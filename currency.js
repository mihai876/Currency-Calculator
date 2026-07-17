// currency.js
const https = require('https');
const readline = require('readline');

const API_URL = 'https://api.exchangerate.host/latest?base=USD';
const CACHE_TTL = 60 * 1000;
let cache = { rates: null, timestamp: 0 };
let history = [];

function getRates() {
    return new Promise((resolve, reject) => {
        const now = Date.now();
        if (cache.rates && (now - cache.timestamp) < CACHE_TTL) {
            resolve(cache.rates);
            return;
        }
        https.get(API_URL, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const json = JSON.parse(data);
                    if (json.success) {
                        cache.rates = json.rates;
                        cache.timestamp = now;
                        resolve(cache.rates);
                    } else {
                        reject(new Error('API error'));
                    }
                } catch (e) {
                    reject(e);
                }
            });
        }).on('error', reject);
    });
}

async function convert(amount, fromCur, toCur) {
    const rates = await getRates();
    if (!rates[fromCur]) throw new Error(`Currency '${fromCur}' not supported.`);
    if (!rates[toCur]) throw new Error(`Currency '${toCur}' not supported.`);
    const usdAmount = fromCur === 'USD' ? amount : amount / rates[fromCur];
    return toCur === 'USD' ? usdAmount : usdAmount * rates[toCur];
}

function addHistory(amount, fromCur, toCur, result) {
    const entry = { amount, fromCur, toCur, result, time: new Date().toLocaleTimeString() };
    history.push(entry);
    if (history.length > 10) history.shift();
}

function showHistory() {
    if (history.length === 0) {
        console.log('No conversions yet.');
        return;
    }
    console.log('\n--- History ---');
    history.forEach(h => {
        console.log(`${h.time}  ${h.amount.toFixed(2)} ${h.fromCur} = ${h.result.toFixed(2)} ${h.toCur}`);
    });
}

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function ask(question) {
    return new Promise(resolve => rl.question(question, resolve));
}

async function interactive() {
    console.log('=== Currency Converter ===');
    while (true) {
        console.log('\n1. Convert');
        console.log('2. Show history');
        console.log('3. Exit');
        const choice = await ask('Choose: ');
        switch (choice.trim()) {
            case '1':
                try {
                    const amountStr = await ask('Amount: ');
                    const amount = parseFloat(amountStr);
                    if (isNaN(amount) || amount < 0) {
                        console.log('Invalid amount.');
                        continue;
                    }
                    const fromCur = (await ask('From (USD): ')).trim().toUpperCase() || 'USD';
                    const toCur = (await ask('To: ')).trim().toUpperCase();
                    if (!toCur) {
                        console.log('Please enter a target currency.');
                        continue;
                    }
                    const result = await convert(amount, fromCur, toCur);
                    console.log(`${amount.toFixed(2)} ${fromCur} = ${result.toFixed(2)} ${toCur}`);
                    addHistory(amount, fromCur, toCur, result);
                } catch (err) {
                    console.log('Error:', err.message);
                }
                break;
            case '2':
                showHistory();
                break;
            case '3':
                console.log('Goodbye!');
                rl.close();
                return;
            default:
                console.log('Invalid choice.');
        }
    }
}

async function cli() {
    const args = process.argv.slice(2);
    if (args.length !== 3) {
        console.log('Usage: node currency.js <amount> <from_currency> <to_currency>');
        process.exit(1);
    }
    const amount = parseFloat(args[0]);
    if (isNaN(amount)) {
        console.log('Invalid amount.');
        process.exit(1);
    }
    const fromCur = args[1].toUpperCase();
    const toCur = args[2].toUpperCase();
    try {
        const result = await convert(amount, fromCur, toCur);
        console.log(`${amount.toFixed(2)} ${fromCur} = ${result.toFixed(2)} ${toCur}`);
    } catch (err) {
        console.log('Error:', err.message);
        process.exit(1);
    }
}

if (process.argv.length === 2) {
    interactive();
} else {
    cli();
}
