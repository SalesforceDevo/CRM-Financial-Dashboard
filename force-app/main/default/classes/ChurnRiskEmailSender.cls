public class ChurnRiskEmailSender {
    public static void sendEmailsToHighRiskCustomers() {
        List<Customers__c> highRiskCustomers = [
            SELECT Id, Name, Email__c FROM Customers__c WHERE Churn_Risk__c = 'High' AND Email__c != NULL
        ];
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Customers__c customer : highRiskCustomers) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{customer.Email__c});
            email.setSubject('We Miss You, ' + customer.Name + '!');
            email.setPlainTextBody('Hello ' + customer.Name + ',\n\nWe noticed you haven’t engaged with us recently. We value your presence and would love to offer exclusive benefits. Reach out to us today!\n\nBest Regards,\nYour CRM Team');
            emails.add(email);
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}
