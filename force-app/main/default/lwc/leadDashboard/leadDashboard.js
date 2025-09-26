import { LightningElement, wire, api } from 'lwc';
import getLeadsWithScores from '@salesforce/apex/LeadValidationTriggerHandler.getLeadsWithScores';

export default class LeadDashboard extends LightningElement {
    @api threshold = 50;
    @wire(getLeadsWithScores, { threshold: '$threshold' }) leads;
}