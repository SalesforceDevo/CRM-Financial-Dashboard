public with sharing class LoanController {
    @AuraEnabled(cacheable=true)
    public static List<Loans__c> getLoans() {
       
        return [
            SELECT Id, Name, Loan_Amount__c, Loan_Status__c, Interest_Rate__c, Loan_Term__c, Loan_Type__c, Customer_ID__c
            FROM Loans__c
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static String updateLoanStatus(Id loanId, String status) {
       
        Loans__c loan = [SELECT Id, Loan_Status__c FROM Loans__c WHERE Id = :loanId LIMIT 1];
        loan.Loan_Status__c = status; 
        update loan;
        return 'Success'; 
    }
}
