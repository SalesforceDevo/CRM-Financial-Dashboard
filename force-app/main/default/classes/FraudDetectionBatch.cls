global class FraudDetectionBatch implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Transaction_Amount__c, Transaction_Type__c, Account_Balance_After_Transaction__c
            FROM Transactions__c
            WHERE Fraud_Flag__c = FALSE OR Fraud_Flag__c = NULL
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Transactions__c> txnBatch = new List<Transactions__c>();

        for (SObject sObj : scope) {
            txnBatch.add((Transactions__c) sObj);

            // Process in chunks of 50
            if (txnBatch.size() == 50) {
                System.enqueueJob(new FraudDetectionQueueable(txnBatch));
                txnBatch.clear(); 
            }
        }

        // Process any remaining records
        if (!txnBatch.isEmpty()) {
            System.enqueueJob(new FraudDetectionQueueable(txnBatch));
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch job completed successfully.');
    }
}
