import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import CREDITO_OBJECT from '@salesforce/schema/CAZ_SolicitudCredito__c';

export default class CazSolicitudCredito extends NavigationMixin(LightningElement) {
    @api title = 'Nueva Solicitud de Ampliación de Crédito';

    @track isLoading = true;
    @track isSubmitted = false;
    @track errorMessage = '';
    @track recordName = '';
    @track newRecordId = '';
    
    objectApiName = CREDITO_OBJECT;

    handleLoad() {
        this.isLoading = false;
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        this.errorMessage = '';
        const fields = event.detail.fields;
        fields.CAZ_Estatus__c = 'Borrador';
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event) {
        this.isLoading = false;
        this.recordName = event.detail.fields.Name?.value || '';
        this.newRecordId = event.detail.id;
        this.isSubmitted = true;
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
