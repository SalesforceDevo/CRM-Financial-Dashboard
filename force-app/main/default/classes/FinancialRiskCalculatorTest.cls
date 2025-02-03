@isTest
public class FinancialRiskCalculatorTest {
    @testSetup
    static void setupTestData() {
        // Insert test Customers__c records
        List<Customers__c> testCustomers = new List<Customers__c>();
        for (Integer i = 1; i <= 4; i++) {
            testCustomers.add(new Customers__c(
                Name = 'Test Customer ' + i,
                Risk_Score__c = 0, // Initial risk score
                Credit_Utilization__c = 0, // Initial Credit Utilization
                Loan_Eligibility__c = 'Not Eligible' // Default Loan Eligibility
            ));
        }
        insert testCustomers;

        // Insert related Credit_Cards__c and Transactions__c records
        List<Credit_Cards__c> testCreditCards = new List<Credit_Cards__c>();
        List<Transactions__c> testTransactions = new List<Transactions__c>();

        for (Customers__c customer : testCustomers) {
            // Credit card details
            testCreditCards.add(new Credit_Cards__c(
                Customer_ID__c = customer.Id,
                Credit_Card_Balance__c = 500.0, // Fixed for simplicity
                Credit_Limit__c = 1000.0 // Fixed for simplicity
            ));

            // Create multiple transactions per customer
            testTransactions.add(new Transactions__c(
                Customer_ID__c = customer.Id,
                Transaction_Type__c = 'Withdrawal',
                Transaction_Amount__c = 300.0,
                Account_Balance_After_Transaction__c = 50.0
            ));
            testTransactions.add(new Transactions__c(
                Customer_ID__c = customer.Id,
                Transaction_Type__c = 'Deposit',
                Transaction_Amount__c = 200.0,
                Account_Balance_After_Transaction__c = 250.0
            ));
        }

        insert testCreditCards;
        insert testTransactions;
    }

    // Unit Test: Test for a Single Customer
    @isTest
    static void testSingleRecord() {
        // Fetch a single test customer
        Customers__c testCustomer = [SELECT Id FROM Customers__c LIMIT 1];
        List<Id> singleCustomerId = new List<Id>{testCustomer.Id};

        // Execute risk score update
        Test.startTest();
        FinancialRiskCalculator.updateRiskScores(singleCustomerId);
        Test.stopTest();

        // Fetch updated customer data
        Customers__c updatedCustomer = [SELECT Risk_Score__c, Credit_Utilization__c, Loan_Eligibility__c FROM Customers__c WHERE Id = :testCustomer.Id];

        // Fetch related credit card data
        Credit_Cards__c creditCard = [SELECT Credit_Card_Balance__c, Credit_Limit__c FROM Credit_Cards__c WHERE Customer_ID__c = :testCustomer.Id LIMIT 1];

        // Fetch all transactions
        List<Transactions__c> transactions = [SELECT Transaction_Type__c, Transaction_Amount__c, Account_Balance_After_Transaction__c FROM Transactions__c WHERE Customer_ID__c = :testCustomer.Id];

        // Calculate expected Credit Utilization
        Double creditUtilization = (creditCard.Credit_Card_Balance__c / creditCard.Credit_Limit__c) * 100;

        // Calculate expected transaction score considering ALL transactions
        Double transactionScore = 0;
        Integer withdrawalCount = 0;
        Integer depositCount = 0;

        for (Transactions__c txn : transactions) {
            if (txn.Transaction_Type__c == 'Withdrawal') {
                transactionScore -= txn.Transaction_Amount__c * 0.5;
                withdrawalCount++;
            } else if (txn.Transaction_Type__c == 'Transfer') {
                transactionScore += txn.Transaction_Amount__c * 0.3;
            } else if (txn.Transaction_Type__c == 'Deposit') {
                transactionScore += txn.Transaction_Amount__c * 1.0;
                depositCount++;
            }

            if (txn.Account_Balance_After_Transaction__c < 100) {
                transactionScore -= 50;
            } else {
                transactionScore += 20;
            }
        }

        // Adjust for withdrawal-heavy behavior
        if (withdrawalCount > depositCount) {
            transactionScore -= 20;
        }

        // Expected Risk Score Calculation
        Double expectedRiskScore = Math.round((creditUtilization * 0.7 + transactionScore) * 100) / 100.0;

        // Expected Loan Eligibility
        String expectedLoanEligibility = (expectedRiskScore > 80 && creditUtilization < 30) ? 'Eligible' : 'Not Eligible';

        // Assertions
        System.assertEquals(expectedRiskScore, updatedCustomer.Risk_Score__c, 'Risk score calculation is incorrect.');
        System.assertEquals(creditUtilization, updatedCustomer.Credit_Utilization__c, 'Credit utilization calculation is incorrect.');
        System.assertEquals(expectedLoanEligibility, updatedCustomer.Loan_Eligibility__c, 'Loan eligibility decision is incorrect.');
    }

    // Bulk Test: Test for Multiple Customers
    @isTest
    static void testBulkRecords() {
        // Fetch all customer IDs
        List<Id> customerIds = new List<Id>();
        for (Customers__c customer : [SELECT Id FROM Customers__c]) {
            customerIds.add(customer.Id);
        }

        // Execute bulk update
        Test.startTest();
        FinancialRiskCalculator.updateRiskScores(customerIds);
        Test.stopTest();

        // Verify risk scores for all customers
        List<Customers__c> updatedCustomers = [SELECT Id, Risk_Score__c, Credit_Utilization__c, Loan_Eligibility__c FROM Customers__c];

        for (Customers__c customer : updatedCustomers) {
            List<Transactions__c> transactions = [SELECT Transaction_Type__c, Transaction_Amount__c, Account_Balance_After_Transaction__c FROM Transactions__c WHERE Customer_ID__c = :customer.Id];

            Credit_Cards__c creditCard = [SELECT Credit_Card_Balance__c, Credit_Limit__c FROM Credit_Cards__c WHERE Customer_ID__c = :customer.Id LIMIT 1];

            // Compute expected credit utilization
            Double creditUtilization = (creditCard.Credit_Card_Balance__c / creditCard.Credit_Limit__c) * 100;

            // Compute transaction score considering ALL transactions
            Double transactionScore = 0;
            Integer withdrawalCount = 0;
            Integer depositCount = 0;

            for (Transactions__c txn : transactions) {
                if (txn.Transaction_Type__c == 'Withdrawal') {
                    transactionScore -= txn.Transaction_Amount__c * 0.5;
                    withdrawalCount++;
                } else if (txn.Transaction_Type__c == 'Transfer') {
                    transactionScore += txn.Transaction_Amount__c * 0.3;
                } else if (txn.Transaction_Type__c == 'Deposit') {
                    transactionScore += txn.Transaction_Amount__c * 1.0;
                    depositCount++;
                }

                if (txn.Account_Balance_After_Transaction__c < 100) {
                    transactionScore -= 50;
                } else {
                    transactionScore += 20;
                }
            }

            if (withdrawalCount > depositCount) {
                transactionScore -= 20;
            }

            Double expectedRiskScore = Math.round((creditUtilization * 0.7 + transactionScore) * 100) / 100.0;
            String expectedLoanEligibility = (expectedRiskScore > 80 && creditUtilization < 30) ? 'Eligible' : 'Not Eligible';

            // Assertions
            System.assertEquals(expectedRiskScore, customer.Risk_Score__c);
            System.assertEquals(creditUtilization, customer.Credit_Utilization__c);
            System.assertEquals(expectedLoanEligibility, customer.Loan_Eligibility__c);
        }
    }
}
