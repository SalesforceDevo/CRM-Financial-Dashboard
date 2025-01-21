global class FinancialRiskBatch implements Database.Batchable<SObject> {
    // Define the start method to query the records
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query to fetch all Customers__c records
        return Database.getQueryLocator('SELECT Id FROM Customers__c');
    }

    // Define the execute method to process records in batches
    global void execute(Database.BatchableContext bc, List<Customers__c> scope) {
        // Collect customer IDs from the current batch
        List<Id> customerIds = new List<Id>();
        for (Customers__c customer : scope) {
            customerIds.add(customer.Id);
        }

        // Call the FinancialRiskCalculator to update risk scores
        FinancialRiskCalculator.updateRiskScores(customerIds);

        // Debug log: Confirm processing of the batch
        System.debug('Batch execution completed for ' + customerIds.size() + ' customers.');
    }

    // Define the finish method for post-processing (optional)
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch job completed successfully!');
    }
}
