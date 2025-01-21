@isTest
public class FinancialRiskCalculatorTest {
    @testSetup
    static void setupTestData() {
        // Insert test Customers__c records
        List<Customers__c> testCustomers = new List<Customers__c>();
        for (Integer i = 1; i <= 4; i++) {
            testCustomers.add(new Customers__c(
                Name = 'Test Customer ' + i,
                Risk_Score__c = 0 
            ));
        }
        insert testCustomers;

        // Insert related Credit_Cards__c and Transactions__c records
        List<Credit_Cards__c> testCreditCards = new List<Credit_Cards__c>();
        List<Transactions__c> testTransactions = new List<Transactions__c>();

        Integer counter = 1;
        for (Customers__c customer : testCustomers) {
           
            testCreditCards.add(new Credit_Cards__c(
                Customer_ID__c = customer.Id,
                Credit_Card_Balance__c = 500.0, // Fixed for simplicity
                Credit_Limit__c = 1000.0 // Fixed for simplicity
            ));

            
            String transactionType;
            Double transactionAmount;
            Double accountBalanceAfterTransaction;

            if (counter == 1) {
                transactionType = 'Withdrawal'; 
                transactionAmount = 300.0;
                accountBalanceAfterTransaction = 50.0; 
            } else if (counter == 2) {
                transactionType = 'Transfer';
                transactionAmount = 200.0;
                accountBalanceAfterTransaction = 150.0; 
            } else if (counter == 3) {
                transactionType = 'Deposit';
                transactionAmount = 100.0;
                accountBalanceAfterTransaction = 200.0; 
            } else {
                transactionType = 'Withdrawal';
                transactionAmount = 100.0;
                accountBalanceAfterTransaction = 80.0;
            }

            testTransactions.add(new Transactions__c(
                Customer_ID__c = customer.Id,
                Transaction_Type__c = transactionType,
                Transaction_Amount__c = transactionAmount,
                Account_Balance_After_Transaction__c = accountBalanceAfterTransaction
            ));

            counter++;
        }

        insert testCreditCards;
        insert testTransactions;
    }

    // Unit Test: Test for a Single Record
    @isTest
    static void testSingleRecord() {
        
        Customers__c testCustomer = [SELECT Id FROM Customers__c LIMIT 1];
        List<Id> singleCustomerId = new List<Id>{testCustomer.Id};

        // Start test
        Test.startTest();
        FinancialRiskCalculator.updateRiskScores(singleCustomerId);
        Test.stopTest();

        
        Credit_Cards__c creditCard = [
            SELECT Credit_Card_Balance__c, Credit_Limit__c
            FROM Credit_Cards__c
            WHERE Customer_ID__c = :testCustomer.Id LIMIT 1
        ];
        Transactions__c transdtls = [
            SELECT Transaction_Type__c, Transaction_Amount__c, Account_Balance_After_Transaction__c
            FROM Transactions__c
            WHERE Customer_ID__c = :testCustomer.Id LIMIT 1
        ];

      
        Double creditUtilization = creditCard.Credit_Card_Balance__c / creditCard.Credit_Limit__c;
        Double transactionScore = 0;

        if (transdtls.Transaction_Type__c == 'Withdrawal') {
            transactionScore -= transdtls.Transaction_Amount__c * 0.5;
        } else if (transdtls.Transaction_Type__c == 'Transfer') {
            transactionScore += transdtls.Transaction_Amount__c * 0.3;
        } else if (transdtls.Transaction_Type__c == 'Deposit') {
            transactionScore += transdtls.Transaction_Amount__c * 1.0;
        }

        if (transdtls.Account_Balance_After_Transaction__c < 100) {
            transactionScore -= 50;
        } else {
            transactionScore += 20;
        }

        Double expectedRiskScore = Math.round((creditUtilization * 0.7 + transactionScore) * 100) / 100.0;

        // Assert the calculated risk score
        Customers__c updatedCustomer = [SELECT Id, Risk_Score__c FROM Customers__c WHERE Id = :testCustomer.Id];
        System.assertEquals(expectedRiskScore, updatedCustomer.Risk_Score__c,
            'Risk score for the single customer is incorrect.');
    }

    // Bulk Test: Test for Multiple Records
    @isTest
    static void testBulkRecords() {
        
        List<Id> customerIds = new List<Id>();
        for (Customers__c customer : [SELECT Id FROM Customers__c]) {
            customerIds.add(customer.Id);
        }

        
        Test.startTest();
        FinancialRiskCalculator.updateRiskScores(customerIds);
        Test.stopTest();

        
        List<Customers__c> updatedCustomers = [SELECT Id, Risk_Score__c FROM Customers__c];
        for (Customers__c customer : updatedCustomers) {
            Transactions__c transdtls = [
                SELECT Transaction_Type__c, Transaction_Amount__c, Account_Balance_After_Transaction__c
                FROM Transactions__c
                WHERE Customer_ID__c = :customer.Id LIMIT 1
            ];

            Credit_Cards__c creditCard = [
                SELECT Credit_Card_Balance__c, Credit_Limit__c
                FROM Credit_Cards__c
                WHERE Customer_ID__c = :customer.Id LIMIT 1
            ];

           
            Double creditUtilization = creditCard.Credit_Card_Balance__c / creditCard.Credit_Limit__c;
            Double transactionScore = 0;

            if (transdtls.Transaction_Type__c == 'Withdrawal') {
                transactionScore -= transdtls.Transaction_Amount__c * 0.5;
            } else if (transdtls.Transaction_Type__c == 'Transfer') {
                transactionScore += transdtls.Transaction_Amount__c * 0.3;
            } else if (transdtls.Transaction_Type__c == 'Deposit') {
                transactionScore += transdtls.Transaction_Amount__c * 1.0;
            }

            if (transdtls.Account_Balance_After_Transaction__c < 100) {
                transactionScore -= 50;
            } else {
                transactionScore += 20;
            }

            Double expectedRiskScore = Math.round((creditUtilization * 0.7 + transactionScore) * 100) / 100.0;

            
            System.assertEquals(expectedRiskScore, customer.Risk_Score__c,
                'Risk score for customer ' + customer.Id + ' is incorrect.');
        }
    }
}