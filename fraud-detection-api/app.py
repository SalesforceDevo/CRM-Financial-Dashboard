from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/fraud-detection', methods=['POST'])
def fraud_detection():
    # Get JSON data from the request
    data = request.get_json()

    # Extract transaction details
    transaction_amount = data.get('transactionAmount', 0)
    transaction_type = data.get('transactionType', 'Unknown')
    account_balance_after = data.get('accountBalanceAfter', 0)

    # Initialize fraud score
    fraud_score = 0

    # Rule 1: Transaction Type
    if transaction_type == 'Deposit':
        fraud_score += 10
    elif transaction_type == 'Withdrawal':
        fraud_score += 30
    elif transaction_type == 'Transfer':
        fraud_score += 50

    # Rule 2: Transaction Amount
    if transaction_amount > 10000:
        fraud_score += 50
    elif transaction_amount > 5000:
        fraud_score += 30
    elif transaction_amount > 1000:
        fraud_score += 10

    # Rule 3: Account Balance After Transaction
    if account_balance_after < 0:
        fraud_score += 50
    elif account_balance_after < 500:
        fraud_score += 30

    # Return fraud score and decision
    return jsonify({
        'fraudScore': fraud_score,
        'decision': 'Review' if fraud_score > 70 else 'Approve'
    })

if __name__ == '__main__':
    app.run(debug=True)
