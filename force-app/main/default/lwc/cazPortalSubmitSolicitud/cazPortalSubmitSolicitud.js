import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import STATUS_FIELD from '@salesforce/schema/CAZ_SolicitudDevolucion__c.CAZ_Status__c';
import NAME_FIELD from '@salesforce/schema/CAZ_SolicitudDevolucion__c.Name';
import IMPORTE_FIELD from '@salesforce/schema/CAZ_SolicitudDevolucion__c.CAZ_ImporteDevolucion__c';
import MOTIVO_FIELD from '@salesforce/schema/CAZ_SolicitudDevolucion__c.CAZ_MotivoDevolucion__c';
import CUENTA_FIELD from '@salesforce/schema/CAZ_SolicitudDevolucion__c.CAZ_NumeroCuentaBancaria__c';
import DESC_FIELD from '@salesforce/schema/CAZ_SolicitudDevolucion__c.CAZ_Description__c';
import submitApprovalFromPortal from '@salesforce/apex/CAZ_SolicitudDevolucionController.submitApprovalFromPortal';

const FIELDS = [
    STATUS_FIELD,
    NAME_FIELD,
    IMPORTE_FIELD,
    MOTIVO_FIELD,
    CUENTA_FIELD,
    DESC_FIELD
];

export default class CazPortalSubmitSolicitud extends LightningElement {
    @api recordId;
    isLoading = false;
    isDocumentosCompletos = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    get isBorrador() {
        return this.currentStatus === 'Borrador';
    }

    get currentStatus() {
        return getFieldValue(this.record.data, STATUS_FIELD) || 'Borrador';
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

    get isCamposCompletos() {
        if (!this.record.data) return false;
        const importe = getFieldValue(this.record.data, IMPORTE_FIELD);
        const motivo = getFieldValue(this.record.data, MOTIVO_FIELD);
        const cuenta = getFieldValue(this.record.data, CUENTA_FIELD);
        const desc = getFieldValue(this.record.data, DESC_FIELD);
        
        return importe && motivo && cuenta && desc;
    }

    get isEnviarDisabled() {
        return !this.isDocumentosCompletos || !this.isCamposCompletos || this.isLoading;
    }

    get showFaltaDocumentosAlert() {
        return this.isBorrador && (!this.isDocumentosCompletos || !this.isCamposCompletos);
    }

    handleDocumentosUpdated(event) {
        this.isDocumentosCompletos = event.detail.completo;
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