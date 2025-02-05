global class ChurnPredictionBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id FROM Customers__c
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Customers__c> scope) {
        List<Id> customerIds = new List<Id>();
        for (Customers__c cust : scope) {
            customerIds.add(cust.Id);
        }

        // Call the Churn Prediction Class
        ChurnPrediction.updateChurnRisk(customerIds);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Churn Prediction Batch Completed Successfully.');

        // Trigger email sending after batch completion
        try {
            ChurnRiskEmailSender.sendEmailsToHighRiskCustomers();
            System.debug('Emails sent successfully after churn prediction batch.');
        } catch (Exception e) {
            System.debug('Error sending emails: ' + e.getMessage());
        }
    }
}
