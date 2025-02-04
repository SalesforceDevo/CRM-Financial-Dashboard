public class ChurnPrediction {
    public static void updateChurnRisk(List<Id> customerIds) {
        Date today = System.today();
        List<Customers__c> customerUpdates = new List<Customers__c>();

        // Query Customers with their Transactions
        for (Customers__c customer : [
            SELECT Id, Name, 
                (SELECT Transaction_Date__c, Transaction_Type__c 
                 FROM Transactions__r ORDER BY Transaction_Date__c DESC)
            FROM Customers__c WHERE Id IN :customerIds
        ]) {
            List<Transactions__c> transactions = customer.Transactions__r;

            
            String churnRisk = 'Low'; 
            Date lastTransactionDate = null;
            Integer withdrawals = 0;
            Integer deposits = 0;

            
            if (!transactions.isEmpty()) {
                lastTransactionDate = transactions[0].Transaction_Date__c; 

                for (Transactions__c txn : transactions) {
                    if (txn.Transaction_Type__c == 'Withdrawal') {
                        withdrawals++;
                    } else if (txn.Transaction_Type__c == 'Deposit') {
                        deposits++;
                    }
                }
            }

            
            Integer daysSinceLastTransaction = lastTransactionDate != null ? lastTransactionDate.daysBetween(today) : 9999;
            System.debug('Days Since Last Transaction: ' + daysSinceLastTransaction);

           
            if (lastTransactionDate == null || daysSinceLastTransaction > 365) {
                churnRisk = 'High'; 
            } else if (daysSinceLastTransaction > 90) {
                churnRisk = 'Medium'; 
            } else if (daysSinceLastTransaction > 30) {
                churnRisk = 'Medium'; 
            } else {
                churnRisk = 'Low'; 
            }

            
            if (withdrawals > deposits) {
                if (churnRisk == 'Low') {
                    churnRisk = 'Medium';
                } else if (churnRisk == 'Medium') {
                    churnRisk = 'High';
                }
            }

           
            Customers__c updateCustomer = new Customers__c(
                Id = customer.Id,
                Churn_Risk__c = churnRisk
            );
            customerUpdates.add(updateCustomer);
        }

       
        if (!customerUpdates.isEmpty()) {
            update customerUpdates;
        }
    }
}
