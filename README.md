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
   - **Classes Used:**
     - `FinancialRiskCalculator.cls`
     - `FinancialRiskBatch.cls`
2. **Fraud Detection**:
   - Uses **Apex Queueable & Batch classes** to call an **external Flask API** hosted on **Heroku**.
   - API returns a **fraud score**, and transactions are flagged accordingly in **Salesforce (Fraud_Flag__c)**.
   - **Classes Used:**
     - `FraudDetectionBatch.cls`
     - `FraudDetectionQueueable.cls`

---

## How Risk_Score__c and Fraud_Flag__c Are Calculated

### **Risk Score Calculation**
- **Credit Utilization**: `(Credit Card Balance / Credit Limit) * 0.7`
- **Transaction Type Weighting**:
  - **Withdrawals**: `-50%` of transaction amount.
  - **Transfers**: `+30%` of transaction amount.
  - **Deposits**: `+100%` of transaction amount.
- **Account Balance Consideration**:
  - If **balance after transaction < 100** → `-50 points`.
  - If **balance after transaction > 100** → `+20 points`.
- **Final Calculation**:
  ```math
  Risk_Score = (credit_utilization * 0.7) + transaction_score
  ```

### **Fraud Flag Calculation (Fraud_Flag__c)**
- Fraud detection API evaluates:
  - **Transaction Type** (`Deposit`, `Withdrawal`, `Transfer`)
  - **Transaction Amount**
  - **Account Balance After Transaction**
- If `fraudScore > 70` → **Fraud_Flag__c = True**.

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
  ```

---

## Screenshots

### 1. **Number of Fraud Transactions (By Month & Type)**
📊 **Chart:** Fraud transactions grouped by **month** and **transaction type**  
![Fraud Transactions by Month and Type](Number-of-Fraudtransactions-GroupedBy-Month,Type.png)

### 2. **Fraud Transactions (Monthly Summary)**
📊 **Chart:** Total **fraudulent transactions per month**  
![Fraud Transactions by Month](Number-of-Fraudtransactions-GroupedBy-Month.png)

### 3. **High-Risk Customers (Grouped by Age & City)**
📊 **Chart:** Distribution of **high-risk customers** across different **age groups** and **cities**  
![High-Risk Customers](Number-of-High-Risk-Customers-Groupedby-Age,City.png)

### 4. **Total Transactions (By Type & Month)**
📊 **Chart:** Monthly **transaction amounts** based on **transaction type**  
![Sum of Transactions by Type and Month](Sum-of-Transactions-GroupedBy-Type,Month.png)



---


