import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import STATUS_FIELD from '@salesforce/schema/CAZ_SolicitudDevolucion__c.CAZ_Status__c';
import NAME_FIELD from '@salesforce/schema/CAZ_SolicitudDevolucion__c.Name';
import submitApprovalFromPortal from '@salesforce/apex/CAZ_SolicitudDevolucionController.submitApprovalFromPortal';

export default class CazPortalSubmitSolicitud extends LightningElement {
    @api recordId;
    isLoading = false;

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD, NAME_FIELD] })
    record;

    get isBorrador() {
        return getFieldValue(this.record.data, STATUS_FIELD) === 'Borrador';
    }

    get formMode() {
        return this.isBorrador ? 'view' : 'readonly';
    }

    get isReadOnlyState() {
        return !this.isBorrador;
    }

    get recordName() {
        return getFieldValue(this.record.data, NAME_FIELD);
    }

    handleEnviar() {
        this.isLoading = true;
        submitApprovalFromPortal({ recordId: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Éxito',
                        message: 'La solicitud ha sido enviada a revisión correctamente.',
                        variant: 'success'
                    })
                );
                // Notificar a LDS para que refresque el componente
                notifyRecordUpdateAvailable([{recordId: this.recordId}]);
            })
            .catch(error => {
                let errorMessage = 'Hubo un error al procesar la solicitud.';
                if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error de Envío',
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}