# CRM Financial Dashboard

## Overview
This project demonstrates the development of a **Customer Relationship Management (CRM) dashboard** in **Salesforce** for financial services companies. It integrates **Oracle database** data into Salesforce using **MuleSoft**, calculates **customer financial risk scores**, and detects **fraudulent transactions** using an **external Flask API** deployed on **Heroku**. Additionally, **Salesforce dashboards** visualize fraud and risk insights.

### Key Features:
- **Oracle-Salesforce Integration**: Data is synchronized from **Oracle database** to Salesforce using **MuleSoft**.
- **Risk Score Calculation**: **Apex batch logic** evaluates customer **financial behavior** and assigns a **Risk_Score__c**.
- **Fraud Detection**: **Python Flask API** flags potential **fraudulent transactions** based on predefined rules.
- **Salesforce Dashboards**: Interactive reports for **fraud trends and high-risk customers**.

---

## Architecture
### 1. Data Integration Flow (Oracle to Salesforce)
The MuleSoft integration consists of the following steps:
1. **Oracle Database Query**:
   - Retrieves customer and financial data from the Oracle database.
2. **Data Transformation**:
   - Maps the data fields to match Salesforce objects.
3. **Salesforce Data Insertion**:
   - Inserts transformed data into Salesforce custom objects.
4. **Batch Processing**:
   - Processes large data efficiently in Salesforce.

### 2. Apex-Based Risk and Fraud Analysis
1. **Financial Risk Calculation**:
   - Evaluates a customer’s **credit utilization, transaction types, and account balances** to determine a **Risk Score**.
2. **Fraud Detection**:
   - Uses **Apex Queueable & Batch classes** to call an **external Flask API** hosted on **Heroku**.
   - API returns a **fraud score**, and transactions are flagged accordingly in **Salesforce (Fraud_Flag__c)**.

---

## Fraud Detection API
A **Python Flask API**, hosted on **Heroku**, determines **fraud risk** using transaction details.

### API Features:
- **Transaction Type Analysis**: Transfers and withdrawals have **higher fraud risk**.
- **Transaction Amount Monitoring**: Large transactions **increase fraud scores**.
- **Account Balance Evaluation**: Negative balances **raise fraud flags**.

### API Endpoint:
- **URL:** `https://fraud-detection-mycrm-b3cc67b1b034.herokuapp.com/fraud-detection`
- **Method:** `POST`
- **Request Body:**
  ```json
  {
    "transactionAmount": 5000,
    "transactionType": "Withdrawal",
    "accountBalanceAfter": 200
  }

# Fraud Detection API Documentation

## API Endpoint:
- **Base URL:** `https://fraud-detection-mycrm-b3cc67b1b034.herokuapp.com/fraud-detection`
- **Method:** `POST`
- **Content-Type:** `application/json`

---

## Request

### **Request Body:**
The API expects a **JSON payload** containing the following fields:

```json
{
  "transactionAmount": 5000,
  "transactionType": "Withdrawal",
  "accountBalanceAfter": 200
}
```

| Parameter             | Type    | Required | Description                                      |
|----------------------|--------|----------|--------------------------------------------------|
| `transactionAmount`  | Number | ✅ Yes    | The amount involved in the transaction.         |
| `transactionType`    | String | ✅ Yes    | Type of transaction (`Deposit`, `Withdrawal`, `Transfer`). |
| `accountBalanceAfter`| Number | ✅ Yes    | The account balance after the transaction.      |

---

## Response

### **Success Response:**
If the request is valid, the API returns a **JSON response** with the **fraud score** and a **decision** on whether the transaction needs further review.

```json
{
  "fraudScore": 80,
  "decision": "Review"
}
```

| Parameter   | Type    | Description                                      |
|------------|--------|--------------------------------------------------|
| `fraudScore` | Number | A calculated fraud score based on the rules.   |
| `decision`  | String | The decision (`Review` or `Approve`) based on the fraud score. |

---

## Fraud Detection Rules:
The fraud detection API follows predefined **business logic** to calculate the fraud score:

1. **Transaction Type:**
   - **Deposit** → Low fraud risk (**+10** points).
   - **Withdrawal** → Medium fraud risk (**+30** points).
   - **Transfer** → High fraud risk (**+50** points).

2. **Transaction Amount:**
   - **> $10,000** → **+50** fraud score.
   - **> $5,000** → **+30** fraud score.
   - **> $1,000** → **+10** fraud score.

3. **Account Balance After Transaction:**
   - **Balance < $0** → **+50** fraud score.
   - **Balance < $500** → **+30** fraud score.

### **Fraud Score Interpretation:**
- **`fraudScore <= 70`** → `"decision": "Approve"`
- **`fraudScore > 70`** → `"decision": "Review"`

---

## Example API Calls

### **1. Low-Risk Transaction (Deposit)**
#### **Request**
```json
{
  "transactionAmount": 500,
  "transactionType": "Deposit",
  "accountBalanceAfter": 2000
}
```
#### **Response**
```json
{
  "fraudScore": 10,
  "decision": "Approve"
}
```

---

### **2. High-Risk Transaction (Large Transfer)**
#### **Request**
```json
{
  "transactionAmount": 15000,
  "transactionType": "Transfer",
  "accountBalanceAfter": 100
}
```
#### **Response**
```json
{
  "fraudScore": 130,
  "decision": "Review"
}
```

---

## Error Handling

If there is an error in the request, the API returns an **HTTP 400 Bad Request** response.

#### **Example Error Response**
```json
{
  "error": "Invalid request data"
}
```

| Error Code  | Meaning                                      |
|------------|----------------------------------------------|
| `400`      | Bad request - missing or invalid parameters. |
| `500`      | Internal server error. |

---

## How to Deploy & Use

### **1. Clone the API Repository**
```bash
git clone <repo-link>
```
### **2. Navigate to the API Directory**
```bash
cd fraud-detection-api
```
### **3. Install Dependencies**
```bash
pip install flask
```
### **4. Run the API Locally**
```bash
python app.py
```
### **5. Deploy to Heroku**
```bash
heroku create
git push heroku main
```

---

## Technologies Used
- **Python (Flask)** – Backend API for fraud detection.
- **Heroku** – Cloud hosting for the API.
- **Salesforce** – CRM platform integrating fraud detection.
- **MuleSoft** – Data integration between Oracle and Salesforce.
- **Apex (Queueable & Batch)** – Calls API from Salesforce.

---

