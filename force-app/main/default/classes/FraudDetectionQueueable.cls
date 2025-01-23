public class FraudDetectionQueueable implements Queueable, Database.AllowsCallouts {
    private List<Transactions__c> transactions;

    
    public FraudDetectionQueueable(List<Transactions__c> txnList) {
        this.transactions = txnList;
    }

    public void execute(QueueableContext context) {
       
        if (transactions == null || transactions.isEmpty()) {
            return; 
        }

       
        for (Transactions__c txn : transactions) {
            try {
              
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://fraud-detection-mycrm-b3cc67b1b034.herokuapp.com/fraud-detection');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');

               
                Map<String, Object> payload = new Map<String, Object>{
                    'transactionAmount' => txn.Transaction_Amount__c,
                    'transactionType' => txn.Transaction_Type__c,
                    'accountBalanceAfter' => txn.Account_Balance_After_Transaction__c
                };
                request.setBody(JSON.serialize(payload));

               
                HttpResponse response = http.send(request);

                // Process API response
                if (response.getStatusCode() == 200) {
                    Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    Boolean isFraudulent = ((String) responseBody.get('decision')).equalsIgnoreCase('Review');

                    // Update Fraud Flag
                    txn.Fraud_Flag__c = isFraudulent;
                }
            } catch (Exception e) {
                System.debug('Exception during API call: ' + e.getMessage());
            }
        }

        
        if (!transactions.isEmpty()) {
            update transactions;
        }
    }
}
