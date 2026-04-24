import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import CREDITO_OBJECT from '@salesforce/schema/CAZ_SolicitudCredito__c';
import getUserContext from '@salesforce/apex/CAZ_SolicitudCreditoController.getUserContext';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CazSolicitudCredito extends NavigationMixin(LightningElement) {
    @api title = 'Nueva Solicitud de Crédito';

    @track isLoading = true;
    @track isSubmitted = false;
    @track errorMessage = '';
    @track recordName = '';
    @track newRecordId = '';
    
    accountId;
    contactId;

    objectApiName = CREDITO_OBJECT;

    @wire(getUserContext)
    wiredUserContext({ error, data }) {
        if (data) {
            this.accountId = data.AccountId;
            this.contactId = data.ContactId;
        } else if (error) {
            console.error('Error getting user context', error);
        }
    }

    handleLoad() {
        this.isLoading = false;
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        this.errorMessage = '';
        const fields = event.detail.fields;
        
        fields.CAZ_Estatus__c = 'Borrador';
        
        if (this.accountId) {
            fields.CAZ_Cuenta__c = this.accountId;
            fields.CAZ_Distribuidor__c = this.accountId;
        }
        if (this.contactId) {
            fields.CAZ_ContactoSolicitante__c = this.contactId;
        }

        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event) {
        this.isLoading = false;
        this.recordName = event.detail.fields.Name?.value || '';
        this.newRecordId = event.detail.id;
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Solicitud Creada',
                message: `Tu solicitud ${this.recordName} fue guardada. Por favor, procede a adjuntar los documentos requeridos.`,
                variant: 'success'
            })
        );

        this.dispatchEvent(new CustomEvent('close', {
            detail: { recordId: this.newRecordId }
        }));
    }

    handleError(event) {
        this.isLoading = false;
        this.errorMessage = event.detail.message || 'Ocurrió un error al enviar la solicitud.';
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleVerSolicitudes() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}