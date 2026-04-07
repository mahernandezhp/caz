import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import basePath from '@salesforce/community/basePath';

export default class CazRecordHeader extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api backLabel = 'Regresar';
    @api objectLabel = 'Lista';
    @api objectListPath = '/';

    // Boolean @api props can't init to true (LWC1503). Use internal + getter.
    _showEditButton;
    _showBackButton;

    @api
    get showEditButton() {
        return this._showEditButton !== false;
    }
    set showEditButton(value) {
        this._showEditButton = value;
    }

    @api
    get showBackButton() {
        return this._showBackButton !== false;
    }
    set showBackButton(value) {
        this._showBackButton = value;
    }

    _recordData;
    _error;

    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Compact'], modes: ['View'] })
    wiredRecord({ data, error }) {
        if (data) {
            this._recordData = data;
            this._error = undefined;
        } else if (error) {
            this._error = error;
            this._recordData = undefined;
        }
    }

    // ── Computed Properties ──

    get isLoading() {
        return this.recordId && !this._recordData && !this._error;
    }

    get hasRecord() {
        return !!this._recordData;
    }

    get recordTitle() {
        if (!this._recordData) return '';
        const fields = this._recordData.fields;
        // Try common "name" fields across standard objects
        return fields?.CaseNumber?.value ||
               fields?.OrderNumber?.value ||
               fields?.Name?.value ||
               '';
    }

    get recordSubtitle() {
        if (!this._recordData) return '';
        const fields = this._recordData.fields;
        // For Case: show Subject under CaseNumber
        if (fields?.CaseNumber?.value && fields?.Subject?.value) {
            return fields.Subject.value;
        }
        // For Order: show Status
        if (fields?.OrderNumber?.value && fields?.Status?.value) {
            return `Estado: ${fields.Status.value}`;
        }
        return '';
    }

    get objectIconName() {
        if (!this.objectApiName) return 'standard:record';
        const iconMap = {
            'Case': 'standard:case',
            'Order': 'standard:orders',
            'Account': 'standard:account',
            'Contact': 'standard:contact',
            'Opportunity': 'standard:opportunity'
        };
        return iconMap[this.objectApiName] || 'standard:record';
    }

    get backUrl() {
        const path = this.objectListPath || '/';
        return (basePath || '') + path;
    }

    get displayBackLabel() {
        return this.objectLabel
            ? `${this.backLabel} a ${this.objectLabel}`
            : this.backLabel;
    }

    get breadcrumbItems() {
        const items = [
            { id: 'home', label: 'Inicio', url: basePath || '/' }
        ];
        if (this.objectLabel && this.objectLabel !== 'Lista') {
            items.push({
                id: 'list',
                label: this.objectLabel,
                url: this.backUrl
            });
        }
        if (this.recordTitle) {
            items.push({
                id: 'record',
                label: this.recordTitle,
                url: null // current page, no link
            });
        }
        return items;
    }

    get statusBadges() {
        if (!this._recordData) return [];
        const fields = this._recordData.fields;
        const badges = [];

        if (fields?.Status?.value) {
            badges.push({ id: 'status', label: fields.Status.value, variant: 'default' });
        }
        if (fields?.Priority?.value) {
            const p = fields.Priority.value;
            const variant = p === 'High' ? 'warning' : p === 'Critical' ? 'error' : 'default';
            badges.push({ id: 'priority', label: p, variant });
        }
        if (fields?.Type?.value) {
            badges.push({ id: 'type', label: fields.Type.value, variant: 'default' });
        }
        return badges;
    }

    // ── Event Handlers ──

    handleBack(event) {
        event.preventDefault();
        if (this.objectListPath && this.objectListPath !== '/') {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.backUrl
                }
            });
        } else {
            window.history.back();
        }
    }

    handleEdit() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.objectApiName,
                actionName: 'edit'
            }
        });
    }

    handleBreadcrumbClick(event) {
        event.preventDefault();
        const url = event.currentTarget.dataset.url;
        if (url) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url }
            });
        }
    }
}