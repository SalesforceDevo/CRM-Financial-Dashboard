public with sharing class FraudTransactionController {
    
    @AuraEnabled(cacheable=true)
    public static List<Transactions__c> getFraudulentTransactions() {
        return [
            SELECT Id, Name, Transaction_Amount__c, Transaction_Type__c, Fraud_Flag__c, Approval_Status__c, Checked__c
            FROM Transactions__c
            WHERE Fraud_Flag__c = true AND Checked__c = false
            ORDER BY Transaction_Amount__c DESC
        ];
    }

    @AuraEnabled
    public static String updateFraudStatus(Id transactionId, String status) {
        try {
            List<Transactions__c> txnList = [
                SELECT Id, Fraud_Flag__c, Approval_Status__c, Checked__c 
                FROM Transactions__c 
                WHERE Id = :transactionId
                LIMIT 1
            ];
            
            if (txnList.isEmpty()) {
                throw new AuraHandledException('Transaction not found');
            }
            
            Transactions__c txn = txnList[0];

            // Update transaction status
            txn.Approval_Status__c = status;
            txn.Fraud_Flag__c = (status == 'Rejected'); // If rejected, keep flagged; if approved, remove fraud flag
            txn.Checked__c = true; // Mark as reviewed

            update txn;
            return 'Success';

        } catch (Exception e) {
            throw new AuraHandledException('Error updating transaction: ' + e.getMessage());
        }
    }
}
