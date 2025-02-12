import { LightningElement, wire, track } from 'lwc';
import getLoans from '@salesforce/apex/LoanController.getLoans';
import updateLoanStatus from '@salesforce/apex/LoanController.updateLoanStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class LoanStatusManager extends LightningElement {
    @track loans = [];
    @track error;
    wiredData;

    @wire(getLoans)
    wiredLoans(result) {
        this.wiredData = result;
        if (result.data) {
            this.loans = result.data.map(record => ({
                ...record,
                rowActions: this.getRowActions(record)
            }));
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.loans = [];
        }
    }

    getRowActions(record) {
        const actions = [];
        if (record.Loan_Status__c === 'Pending') {
            actions.push({ label: 'Approve', name: 'approve' });
            actions.push({ label: 'Reject', name: 'reject' });
        }
        return actions;
    }

    handleRowAction(event) {
        const loanId = event.detail.row.Id;
        const actionType = event.detail.action.name === 'approve' ? 'Approved' : 'Rejected';

        updateLoanStatus({ loanId: loanId, status: actionType })
            .then(() => {
                this.showToast('Success', `Loan ${actionType}`, 'success');
                return refreshApex(this.wiredData);
            })
            .catch(error => {
                this.showToast('Error', `Failed to update loan status: ${error.body.message}`, 'error');
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    get columns() {
        return [
            { label: 'Loan Name', fieldName: 'Name', type: 'text' },
            { label: 'Loan Amount', fieldName: 'Loan_Amount__c', type: 'currency' },
            { label: 'Interest Rate', fieldName: 'Interest_Rate__c', type: 'percent' },
            { label: 'Loan Term', fieldName: 'Loan_Term__c', type: 'number' },
            { label: 'Loan Type', fieldName: 'Loan_Type__c', type: 'text' },
            { label: 'Status', fieldName: 'Loan_Status__c', type: 'text' },
            {
                type: 'action',
                typeAttributes: { rowActions: { fieldName: 'rowActions' } }
            }
        ];
    }
}
