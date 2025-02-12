# CRM Financial Dashboard

## Overview

This project delivers a powerful **Customer Relationship Management (CRM) dashboard** in **Salesforce** tailored for financial services companies. Through a robust integration with an **Oracle database** via **MuleSoft**, it enables real-time data access and synchronization within Salesforce. The system is fortified with sophisticated **Apex classes** that compute critical metrics such as **customer financial risk scores**, **credit utilization**, **loan eligibility**, **fraud flags**, and **churn risk**. These metrics are crucial for dynamic risk management and customer retention strategies.

Key interactions within the CRM are facilitated by two purpose-built **Lightning Web Components (LWC)**: one allows financial officers to manually review and approve potentially fraudulent transactions, and the other manages the approval process for loans that are pending decision. These components significantly enhance operational responsiveness and user experience.

The backend functionality is extended with an **external Flask API** deployed on **Heroku**, designed to analyze transaction data and flag potential fraud. This integration provides seamless and efficient fraud detection capabilities within the dashboard.

**Salesforce dashboards** are efficiently designed to provide actionable insights, showcasing the results of the integrated data analysis with reports on fraud trends, risk assessments, and loan management in an interactive format.


### Key Features:
- **Oracle-Salesforce Integration**: Integrates **Oracle database** data into Salesforce using **MuleSoft** for real-time data synchronization, supporting accurate and up-to-date financial analysis.
- **Comprehensive Risk Management**: Utilizes sophisticated **Apex classes** to compute critical metrics such as **customer financial risk scores**, **credit utilization**, **loan eligibility**, **fraud flags**, and **churn risk**, essential for assessing risk and enhancing customer retention strategies.
- **Lightning Web Components for Enhanced Interaction**: Includes two **LWCs** specifically designed for operational efficiency:
  - A component for financial officers to review and approve or reject potentially fraudulent transactions.
  - A component to manage the approval processes for loans in pending status, streamlining decision-making and enhancing user interaction.
- **Fraud Detection via External API**: Employs an **external Flask API** hosted on **Heroku** to analyze transaction data and identify potential fraud, seamlessly integrated for effective fraud management within Salesforce.
- **Actionable Insights with Salesforce Dashboards**: Features well-designed dashboards that provide actionable insights through interactive reports on **fraud trends, risk assessments, and loan management**, helping financial services firms make informed decisions quickly.


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

### 2. Apex-Based Risk, Fraud Analysis and Churn Prediction
1. **Financial Risk Calculation**:
   - Evaluates a customer’s **credit utilization, Loan Eligibilty of a customer, transaction types, and account balances** to determine a **Risk Score**.
   - **Classes Used:**
     - `FinancialRiskCalculator.cls`
     - `FinancialRiskBatch.cls`
     - `ScheduleFinancialRiskBatch.cls` for scheduling the batch process to run at specified intervals.
   - **Test Class:**
     - `FinancialRiskCalculatorTest.cls` ensures comprehensive testing of the risk calculation logic.

2. **Fraud Detection**:
   - Uses **Apex Queueable & Batch classes** to call an **external Flask API** hosted on **Heroku**.
   - API returns a **fraud score**, and transactions are flagged accordingly in **Salesforce (Fraud_Flag__c)**.
   - **Classes Used:**
     - `FraudDetectionBatch.cls`
     - `FraudDetectionQueueable.cls`

3. **Churn Risk Prediction**:
   - Analyzes customer transaction patterns and activity levels to predict churn risk, updating **Churn_Risk__c** and engaging customers with targeted retention strategies.
   - **Classes Used:**
     - `ChurnPrediction.cls`
     - `ChurnPredictionBatch.cls`
     - `ScheduleChurnPredictionBatch.cls` for scheduling the batch process to assess churn risks at specified intervals.
   - **Email Notification System:**
     - `ChurnRiskEmailSender.cls` sends targeted emails to customers identified as high-risk, enhancing customer retention efforts.
       
### 3. LWC Based Components for Interactive Functionality
1. **Fraud Transaction Review Panel**:
   - This component allows financial officers to manually review and approve or reject potentially fraudulent transactions directly from the dashboard.
   - **Component Details**:
     - **JavaScript Controller**: `fraudTransactionPanel.js` 
     - **HTML Template**: `fraudTransactionPanel.html` 
     - **Apex Controller**: `FraudTransactionController.cls` 

2. **Loan Status Manager Panel**:
   - Enables loan officers to manage and update the approval status of loans that are in pending status.
   - **Component Details**:
     - **JavaScript Controller**: `loanStatusManager.js` 
     - **HTML Template**: `loanStatusManager.html` 
     - **Apex Controller**: `LoanController.cls`

---

## How Risk_Score__c, Credit Utilization, Loan Eligibility, Churn Risk and  Fraud_Flag__c Are Calculated

### **Risk Score Calculation**
- **Credit Utilization**: Calculated as `(Credit Card Balance / Credit Limit) * 100`. This metric reflects how much of their available credit the customer is using, which is a critical indicator of financial health.
- **Transaction Type Weighting**:
  - **Withdrawals**: Reduces the score by `50%` of the transaction amount.
  - **Transfers**: Increases the score by `30%` of the transaction amount.
  - **Deposits**: Increases the score by `100%` of the transaction amount.
- **Account Balance Consideration**:
  - Deduct `50 points` if the **balance after transaction is less than $100**.
  - Add `20 points` if the **balance after transaction is more than $100**.
- **Final Calculation**:
  - The **Risk Score** combines the credit utilization and transaction impacts:
  ```math
  RiskScore = (credit utilization * 0.7) + transaction score

### **Loan Eligibility Determination**
- **Loan Eligibility** is determined based on the calculated **Risk Score** and **Credit Utilization**:
  - **Eligible**: If the **Risk Score is greater than 80** and **Credit Utilization is less than 30%**.
  - **Not Eligible**: Otherwise. This criteria ensures that loans are granted to customers who demonstrate financial stability and a low risk of default.

### **Churn Prediction Logic**

The churn prediction logic identifies customers at risk of disengagement by analyzing their transaction patterns and frequency:

- **Customer Data Retrieval**: For each customer specified by their Salesforce ID, the system retrieves the most recent transaction records.
- **Transaction Analysis**:
  - The algorithm examines the dates and types of the last transactions for each customer.
  - It counts the number of withdrawals and deposits to assess transaction behavior.
- **Churn Risk Assessment**:
  - **High Risk**: If the most recent transaction date is over a year ago (more than 365 days) or if withdrawals outnumber deposits and the current risk level is already 'Medium'.
  - **Medium Risk**: If the most recent transaction occurred between 30 and 365 days ago.
  - **Low Risk**: If the last transaction was less than 30 days ago and deposits are equal to or more than withdrawals.
- **Update Customer Records**: The system updates each customer's record in Salesforce with the calculated churn risk level (`Churn_Risk__c`), which can trigger targeted marketing strategies to enhance retention.

This method ensures timely identification of customers who may require additional engagement efforts to prevent churn, thus helping to maintain a stable customer base.  

### **Fraud Flag Calculation Logic (Fraud_Flag__c)**
- Fraud detection API evaluates:
  - **Transaction Type** (`Deposit`, `Withdrawal`, `Transfer`)
  - **Transaction Amount**
  - **Account Balance After Transaction**
- If `fraudScore > 70` → **Fraud_Flag__c = True**.

---

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
# Fraud Transaction Review Panel logic

## Overview

The **Fraud Transaction Review Panel** is a Salesforce Lightning Web Component (LWC) that enables users to manage transactions flagged as potentially fraudulent. The component integrates with Salesforce data using Apex controllers to fetch and update these transactions, providing a user-friendly interface for managing fraud alerts.

## Functionality

### Data Handling

- **Fetching Transactions**: Utilizes the `getFraudulentTransactions` Apex method to retrieve a list of transactions where `Fraud_Flag__c` is true and `Checked__c` is false, indicating unreviewed, potentially fraudulent transactions.

### User Interface

- **Display**: Transactions are displayed in a `lightning-datatable` which includes columns for transaction details such as name, amount, type, and status.
- **Actions**: Each row in the datatable includes actionable buttons for 'Approve' and 'Reject', allowing users to resolve each fraud alert.

### Processing Actions

- **Action Handling**: When an action button is clicked, the `handleRowAction` function is triggered, determining whether the transaction was approved or rejected based on user input.
- **Update Transactions**: Calls the `updateFraudStatus` Apex function to update the `Fraud_Flag__c`, `Approval_Status__c`, and `Checked__c` fields based on the action taken, marking the transaction as reviewed and setting its approval status.

### Notifications

- **Feedback**: Uses the `ShowToastEvent` to provide feedback to the user after each action, indicating successful updates or errors.

## Apex Controller

- **Data Fetch Logic**: The `getFraudulentTransactions` method filters transactions based on fraud flags and checked status, sorted by amount.
- **Update Logic**: The `updateFraudStatus` method handles the updating of transaction records in Salesforce based on user actions from the component.

## Error Handling

- **Errors**: Displayed to the user through the interface if there is an issue fetching or updating transactions.

  # Loan Status Manager

## Overview

The **Loan Status Manager** is a Salesforce Lightning Web Component (LWC) designed to allow users to manage the status of loan applications. It provides a streamlined interface for viewing and updating loan statuses, using Salesforce Apex to interact with loan records.

## Component Structure

### HTML Template

- **Lightning Card**: The main container with a title "Loan Status Manager" and a custom icon. It encloses the datatable.
- **Lightning Datatable**: Displays loan data with columns for loan details such as name, amount, interest rate, term, type, and status. It also includes dynamic row actions for loans with a status of 'Pending' to approve or reject the loan.
- **Error Handling**: Displays errors if there is an issue fetching the loans from the server.

### JavaScript Controller

#### Data Fetching

- **Apex Wire Method**: Uses the `@wire` service to call the `getLoans` method from `LoanController`, fetching the latest loans ordered by creation date.
- **Data Mapping**: Maps the fetched data to include dynamic row actions for approving or rejecting loans, based on the loan's current status.

#### Row Actions

- **Dynamic Actions**: Depending on the loan's status, 'Approve' and 'Reject' actions are added for loans marked as 'Pending'.
- **Action Handler**: Implements `handleRowAction` to process user actions (approve/reject), updating the loan's status via the `updateLoanStatus` Apex method.

#### Notifications

- **Toast Notifications**: Utilizes the `ShowToastEvent` to provide feedback on the success or failure of loan status updates.

### Apex Controller

#### Loan Retrieval

- **getLoans Method**: Fetches a list of all loans, sorted by their creation date, including details like the loan amount, status, interest rate, term, type, and associated customer ID.

#### Loan Update

- **updateLoanStatus Method**: Receives a loan ID and a new status ('Approved' or 'Rejected'). Updates the `Loan_Status__c` field of the specified loan and commits the change to the database.

## Error Handling

- **Apex Methods**: Both `getLoans` and `updateLoanStatus` include error handling to manage and relay issues that might occur during data fetching or updating.





---


# Advanced Reports & Dashboards in Salesforce

I leveraged **my expertise in Salesforce Reports & Dashboards** to create **interactive visualizations** that provide actionable insights into **customer financial behavior and fraud detection trends**.

### **Key Dashboard Insights:**
1. **Fraud Trends Analysis**  
   - Used **Fraud_Flag__c** to create a **row-level summary** to count flagged transactions.
   - Grouped transactions by **month and type** using **bucket fields**.
   - Helps in identifying **seasonal fraud trends**.

2. **High-Risk Customer Segmentation**  
   - Utilized **Risk_Score__c** with **formula fields** to categorize customers into **risk groups**.
   - Created **bar charts grouped by age and city** to visualize **geographical fraud risks**.

3. **Transaction Volume Breakdown**  
   - **Formula fields** were used to calculate the **total sum of transactions** by type.
   - **Row-level summaries** helped in aggregating **monthly transaction trends**.

4. **Fraud Score-Based Review Reports**  
   - Created reports that dynamically **highlight transactions exceeding fraud thresholds**.
   - Designed **dashboard filters** for quick **drill-down analysis**.

### **Salesforce Reporting Techniques Used:**
- **Row-Level Summary Fields**: Aggregating fraud transactions & financial data.
- **Formula Fields**: Categorizing customers based on **risk score brackets**.
- **Bucket Fields**: Grouping transactions into **fraud risk categories**.
- **Dashboard Filters**: Enabling **dynamic data exploration**.
- **Conditional Formatting**: Highlighting **high-risk transactions**.




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


