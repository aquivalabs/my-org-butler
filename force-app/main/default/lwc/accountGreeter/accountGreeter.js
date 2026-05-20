import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import REVENUE_FIELD from '@salesforce/schema/Account.AnnualRevenue';

const FIELDS = [NAME_FIELD, REVENUE_FIELD];

export default class AccountGreeter extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    account;

    get greeting() {
        if (!this.account?.data) return null;
        const name = getFieldValue(this.account.data, NAME_FIELD);
        const revenue = getFieldValue(this.account.data, REVENUE_FIELD);
        const revenueStr = revenue != null
            ? new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(revenue)
            : 'an undisclosed amount';
        return `${name} generates ${revenueStr} annually.`;
    }
}
