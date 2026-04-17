import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import DEVOLUCION_OBJECT from '@salesforce/schema/CAZ_SolicitudDevolucion__c';
import enviarSolicitud from '@salesforce/apex/CAZ_SolicitudDevolucionController.enviarSolicitud';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CazSolicitudDevolucion extends NavigationMixin(LightningElement) {
    @api title = 'Nueva Solicitud de Devolución';
    @api targetPageName = 'Mis_Solicitudes__c';

    @track isLoading = true; // Inicia cargando
    @track isSubmitted = false;
    @track errorMessage = '';
    @track recordName = '';
    @track newRecordId = '';
    @track isEnviarDisabled = true;
    
    objectApiName = DEVOLUCION_OBJECT;

    handleLoad() {
        // Se dispara cuando el record-edit-form termina de renderizar
        this.isLoading = false;
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        this.errorMessage = '';
        const fields = event.detail.fields;
        fields.CAZ_Status__c = 'Borrador';
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

    handleDocumentosUpdated(event) {
        this.isEnviarDisabled = !event.detail.completo;
    }

    handleEnviar() {
        this.isLoading = true;
        enviarSolicitud({ recordId: this.newRecordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Éxito',
                        message: 'La solicitud ha sido enviada a revisión.',
                        variant: 'success'
                    })
                );
                
                // Navegar al registro recién creado
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.newRecordId,
                        actionName: 'view'
                    }
                });
                
                // Conservar dispatch para quick actions
                this.dispatchEvent(new CustomEvent('close'));
            })
            .catch(error => {
                this.isLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body ? error.body.message : 'No se pudo enviar la solicitud.',
                        variant: 'error'
                    })
                );
            });
    }
}