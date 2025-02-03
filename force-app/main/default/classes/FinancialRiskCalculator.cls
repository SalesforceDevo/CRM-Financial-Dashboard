public class FinancialRiskCalculator {
    public static void updateRiskScores(List<Id> customerIds) {
       
        Map<Id, Customers__c> customerUpdates = new Map<Id, Customers__c>();

       
        for (Customers__c customer : [
            SELECT Id, Name, 
            (SELECT Credit_Card_Balance__c, Credit_Limit__c FROM Credit_Cards__r LIMIT 1),
            (SELECT Transaction_Type__c, Transaction_Amount__c, Account_Balance_After_Transaction__c FROM Transactions__r)
            FROM Customers__c 
            WHERE Id IN :customerIds
        ]) {
            
            Credit_Cards__c creditDetails = customer.Credit_Cards__r.isEmpty() ? null : customer.Credit_Cards__r[0];
            List<Transactions__c> transactions = customer.Transactions__r;

            if (creditDetails != null && !transactions.isEmpty()) {
                
                Double creditUtilization = creditDetails.Credit_Limit__c > 0 ? 
                    (creditDetails.Credit_Card_Balance__c / creditDetails.Credit_Limit__c) * 100 : 0;
                Double transactionScore = 0;

                
                Double totalTransactionAmount = 0;
                Integer withdrawalCount = 0;
                Integer depositCount = 0;

               
                for (Transactions__c txn : transactions) {
                    totalTransactionAmount += txn.Transaction_Amount__c;

                    switch on txn.Transaction_Type__c {
                        when 'Withdrawal' {
                            transactionScore -= txn.Transaction_Amount__c * 0.5; 
                            withdrawalCount++;
                        }
                        when 'Transfer' {
                            transactionScore += txn.Transaction_Amount__c * 0.3; 
                        }
                        when 'Deposit' {
                            transactionScore += txn.Transaction_Amount__c * 1.0; 
                            depositCount++;
                        }
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

                // Normalize Risk Score Based on Transactions
                Double riskScore = (creditUtilization * 0.7 + transactionScore);
                riskScore = Math.round(riskScore * 100) / 100.0;

                // Loan Eligibility Logic 
                String loanEligibility;
                if (riskScore > 80 && creditUtilization < 30) {
                    loanEligibility = 'Eligible';
                } else {
                    loanEligibility = 'Not Eligible';
                }

                // Prepare Customer Update 
                Customers__c updateCustomer = new Customers__c(
                    Id = customer.Id, 
                    Risk_Score__c = riskScore,     
                    Credit_Utilization__c = creditUtilization, 
                    Loan_Eligibility__c = loanEligibility      
                );

                customerUpdates.put(customer.Id, updateCustomer);
            }
        }

        
        if (!customerUpdates.isEmpty()) {
            update customerUpdates.values();
        }
    }
}
