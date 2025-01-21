public class FinancialRiskCalculator {
    public static void updateRiskScores(List<Id> customerIds) {
        // Map to store customers and their calculated risk scores
        Map<Id, Customers__c> customerUpdates = new Map<Id, Customers__c>();

        // Query each customer and related details
        for (Customers__c customer : [
            SELECT Id, Name, 
            (SELECT Credit_Card_Balance__c, Credit_Limit__c FROM Credit_Cards__r LIMIT 1),
            (SELECT Transaction_Type__c, Transaction_Amount__c, Account_Balance_After_Transaction__c FROM Transactions__r LIMIT 1)
            FROM Customers__c 
            WHERE Id IN :customerIds
        ]) {
            // Retrieve credit card and transaction details from subqueries
            Credit_Cards__c creditDetails = customer.Credit_Cards__r.isEmpty() ? null : customer.Credit_Cards__r[0];
            Transactions__c trns = customer.Transactions__r.isEmpty() ? null : customer.Transactions__r[0];

            if (creditDetails != null && trns != null) {
                // Calculate credit utilization
                Double creditUtilization = creditDetails.Credit_Card_Balance__c / creditDetails.Credit_Limit__c;

                Double transactionScore = 0;

                // Adjust scores based on transaction type
                switch on trns.Transaction_Type__c {
                    when 'Withdrawal' {
                        transactionScore -= trns.Transaction_Amount__c * 0.5; // Negative impact for withdrawals
                    }
                    when 'Transfer' {
                        transactionScore += trns.Transaction_Amount__c * 0.3; // Neutral impact for transfers
                    }
                    when 'Deposit' {
                        transactionScore += trns.Transaction_Amount__c * 1.0; // Positive impact for deposits
                    }
                }

                // Consider account balance after transaction
                if (trns.Account_Balance_After_Transaction__c < 100) {
                    transactionScore -= 50; // Penalize low balances
                } else {
                    transactionScore += 20; // Reward higher balances
                }

                // Combine credit utilization and transaction score for the final risk score
                Double riskScore = (creditUtilization * 0.7 + transactionScore); 
                riskScore = Math.round(riskScore * 100) / 100.0;


                // Prepare customer for update
                Customers__c updateCustomer = new Customers__c(Id = customer.Id, Risk_Score__c = riskScore);
                customerUpdates.put(customer.Id, updateCustomer);
            }
        }

        // Perform a single DML update outside the loop
        if (!customerUpdates.isEmpty()) {
            update customerUpdates.values();
        }
    }
}
