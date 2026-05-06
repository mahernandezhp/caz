import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import STATUS_FIELD from '@salesforce/schema/Case.Status';

export default class CazCreditRequestDetail extends LightningElement {
    @api recordId;
    
    @track isLoading = true;
    @track isEditable = false;
    @track hasError = false;
    @track recordName = '';
    @track currentStatus = 'New';
    @track isReadOnlyState = true;
    @track errorMessage = '';
    @track isSubmitDisabled = true;
    
    @track pathSteps = [];
    caseRecordTypeId;

    patchedRecordId;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && currentPageReference.state && currentPageReference.state.recordId) {
            this.patchedRecordId = currentPageReference.state.recordId;
            if(!this.recordId) {
                this.recordId = this.patchedRecordId;
            }
        }
    }

    wiredCase;

    @wire(getRecord, { recordId: '$recordId', fields: ['Case.Status', 'Case.CaseNumber', 'Case.RecordTypeId'] })
    wiredRecord(result) {
        this.wiredCase = result;
        const { data, error } = result;
        if (data) {
            const status = data.fields.Status?.value || 'New';
            this.currentStatus = status;
            this.recordName = data.fields.CaseNumber?.value || 'Detalle de Solicitud';
            this.caseRecordTypeId = data.fields.RecordTypeId?.value;
            
            // Si es New o Borrador permitimos editar y adjuntar
            if (status === 'New' || status === 'Borrador') {
                this.isEditable = true;
                this.isReadOnlyState = false;
            } else {
                this.isEditable = false;
                this.isReadOnlyState = true;
            }
            this.isLoading = false;
        } else if (error) {
            console.error('Error fetching case:', error);
            this.errorMessage = 'Hubo un error al cargar la información del caso.';
            this.hasError = true;
            this.isLoading = false;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$caseRecordTypeId', fieldApiName: STATUS_FIELD })
    wiredPicklist({ error, data }) {
        if (data) {
            // Definir el orden estricto del negocio con ApiNames exactos
            const ORDERED_STATUSES = [
                'New',
                'Borrador',
                'Por Autorizar',
                'Autorizado',
                'En Revisión',
                'Rechazado',
                'Aprobado',
                'Completado',
                'Closed'
            ];

            let steps = data.values.map(val => {
                return { label: val.label, value: val.value };
            });

            // Ordenamiento lógico
            steps.sort((a, b) => {
                let indexA = ORDERED_STATUSES.indexOf(a.value);
                let indexB = ORDERED_STATUSES.indexOf(b.value);
                if(indexA === -1) indexA = 999;
                if(indexB === -1) indexB = 999;
                return indexA - indexB;
            });

            this.pathSteps = steps;
        }
    }

    handleSubmit(event) {
        this.isLoading = true;
    }

    handleSuccess(event) {
        this.isLoading = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Éxito',
                message: 'Cambios guardados correctamente.',
                variant: 'success'
            })
        );
    }

    handleError(event) {
        this.isLoading = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: event.detail.detail || 'Hubo un error al guardar.',
                variant: 'error'
            })
        );
    }

    handleDocumentosUpdated(event) {
        // detail: { totalRequeridos, totalCargados, completo }
        const data = event.detail;
        if (data.completo) {
            this.isSubmitDisabled = false;
        } else {
            this.isSubmitDisabled = true;
        }
    }

    async handleEnviarRevision() {
        this.isLoading = true;
        try {
            const fields = {};
            fields['Id'] = this.recordId;
            fields['Status'] = 'En revisión'; 
            
            const recordInput = { fields };
            await updateRecord(recordInput);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Éxito',
                    message: 'Solicitud enviada a revisión correctamente.',
                    variant: 'success'
                })
            );
            
            // Refrescar al modo consulta
            this.isEditable = false;

        } catch (e) {
            console.error('Error enviando solicitud:', e);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No fue posible enviar la solicitud a revisión.',
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }
}