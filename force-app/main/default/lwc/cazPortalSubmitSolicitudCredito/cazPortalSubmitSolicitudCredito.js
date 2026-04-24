import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import STATUS_FIELD from '@salesforce/schema/CAZ_SolicitudCredito__c.CAZ_Estatus__c';
import NAME_FIELD from '@salesforce/schema/CAZ_SolicitudCredito__c.Name';
import MONTO_FIELD from '@salesforce/schema/CAZ_SolicitudCredito__c.CAZ_MontoSolicitado__c';
import DIAS_FIELD from '@salesforce/schema/CAZ_SolicitudCredito__c.CAZ_Dias__c';
import JUSTIFICACION_FIELD from '@salesforce/schema/CAZ_SolicitudCredito__c.CAZ_Justificacion__c';

import enviarSolicitud from '@salesforce/apex/CAZ_SolicitudCreditoController.enviarSolicitud';

const FIELDS = [
    STATUS_FIELD,
    NAME_FIELD,
    MONTO_FIELD,
    DIAS_FIELD,
    JUSTIFICACION_FIELD
];

export default class CazPortalSubmitSolicitudCredito extends LightningElement {
    @api recordId;
    isLoading = false;
    isDocumentosCompletos = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    get currentStatus() {
        return getFieldValue(this.record.data, STATUS_FIELD) || 'Borrador';
    }

    get isBorrador() {
        return this.currentStatus === 'Borrador';
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
        const monto = getFieldValue(this.record.data, MONTO_FIELD);
        const dias = getFieldValue(this.record.data, DIAS_FIELD);
        const justificacion = getFieldValue(this.record.data, JUSTIFICACION_FIELD);
        
        return monto && dias && justificacion;
    }

    get isEnviarDisabled() {
        return !this.isDocumentosCompletos || !this.isCamposCompletos || this.isLoading;
    }

    get showFaltaDocumentosAlert() {
        return this.isBorrador && (!this.isDocumentosCompletos || !this.isCamposCompletos);
    }

    get alertaMensaje() {
        if (!this.isCamposCompletos && !this.isDocumentosCompletos) {
            return 'Para habilitar el botón de envío, asegúrate de llenar todos los campos requeridos en el formulario y adjuntar los documentos obligatorios.';
        } else if (!this.isCamposCompletos) {
            return 'Para habilitar el botón de envío, asegúrate de llenar todos los campos requeridos en el formulario (Monto Solicitado, Días, Justificación).';
        } else {
            return 'Para habilitar el botón de envío, asegúrate de adjuntar los documentos obligatorios en la sección inferior.';
        }
    }

    handleDocumentosUpdated(event) {
        this.isDocumentosCompletos = event.detail.completo;
    }

    handleEnviar() {
        this.isLoading = true;
        enviarSolicitud({ recordId: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Éxito',
                        message: 'La solicitud ha sido enviada a revisión correctamente.',
                        variant: 'success'
                    })
                );
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
