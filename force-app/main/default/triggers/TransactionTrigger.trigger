trigger TransactionTrigger on Transactions__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        // Run the Fraud Detection Batch on newly inserted transactions
        Database.executeBatch(new FraudDetectionBatch());
    }
}
