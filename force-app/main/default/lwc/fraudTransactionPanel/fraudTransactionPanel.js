import { LightningElement, wire, track } from 'lwc';
import getFraudulentTransactions from '@salesforce/apex/FraudTransactionController.getFraudulentTransactions';
import updateFraudStatus from '@salesforce/apex/FraudTransactionController.updateFraudStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class FraudTransactionPanel extends LightningElement {
    @track fraudTransactions = [];
    @track error;
    wiredData;

    // Fetch fraud transactions
    @wire(getFraudulentTransactions)
    wiredTransactions(result) {
        this.wiredData = result;
        if (result.data) {
            this.fraudTransactions = result.data.map(record => ({
                ...record,
                rowActions: [
                    { label: 'Approve', name: 'approve' },
                    { label: 'Reject', name: 'reject' }
                ]
            }));
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.fraudTransactions = [];
        }
    }

    // Handle Approve or Reject action
    handleRowAction(event) {
        console.log('handleRowAction triggered!'); // Debugging log
        console.log('Row Action Event:', JSON.stringify(event.detail, null, 2)); // Log event details

        const transactionId = event.detail.row.Id;
        const actionType = event.detail.action.name === 'approve' ? 'Approved' : 'Rejected';

        console.log('Transaction ID:', transactionId);
        console.log('Action Type:', actionType);

        updateFraudStatus({ transactionId: transactionId, status: actionType }) // ✅ Ensure correct parameter format
            .then(result => {
                if (result === 'Success') {
                    this.showToast('Success', `Transaction ${actionType}`, 'success');

                    // Remove the reviewed transaction from UI before refreshing
                    this.fraudTransactions = this.fraudTransactions.filter(txn => txn.Id !== transactionId);

                    // Force refresh of Apex data
                    return refreshApex(this.wiredData);
                } else {
                    this.showToast('Error', result, 'error');
                }
            })
            .catch(error => {
                console.error('Update Error:', error);
                this.showToast('Error', `Failed to update transaction: ${error.body.message}`, 'error');
            });
    }

    // Show toast message
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Define columns with Approve & Reject row actions
    columns = [
        { label: 'Transaction Name', fieldName: 'Name', type: 'text' },
        { label: 'Amount', fieldName: 'Transaction_Amount__c', type: 'currency' },
        { label: 'Type', fieldName: 'Transaction_Type__c', type: 'text' },
        { label: 'Fraud Status', fieldName: 'Fraud_Flag__c', type: 'boolean' },
        { label: 'Approval Status', fieldName: 'Approval_Status__c', type: 'text' },
        {
            type: 'action',
            typeAttributes: { rowActions: { fieldName: 'rowActions' } }
        }
    ];
}
