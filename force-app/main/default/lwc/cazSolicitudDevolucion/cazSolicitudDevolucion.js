import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import CASE_OBJECT from '@salesforce/schema/Case';

export default class CazSolicitudDevolucion extends NavigationMixin(LightningElement) {
    @api title = 'Nueva Solicitud de Devolución';

    @track isLoading = false;
    @track isSubmitted = false;
    @track errorMessage = '';
    @track caseNumber = '';
    @track recordTypeId;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    handleObjectInfo({ data, error }) {
        if (data) {
            const rtis = data.recordTypeInfos;
            const devolucionRt = Object.values(rtis).find(rt => rt.name === 'Devolucion');
            if (devolucionRt) {
                this.recordTypeId = devolucionRt.recordTypeId;
            }
        }
        if (error) {
            this.errorMessage = 'Error al cargar el formulario.';
        }
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        this.errorMessage = '';
        const fields = event.detail.fields;
        fields.Status = 'Borrador';
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event) {
        this.isLoading = false;
        this.caseNumber = event.detail.fields.CaseNumber?.value || '';
        this.isSubmitted = true;
    }

    handleError(event) {
        this.isLoading = false;
        this.errorMessage = event.detail.message || 'Ocurrió un error al enviar la solicitud.';
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Home' }
        });
    }

    handleVerSolicitudes() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Mis_Solicitudes__c' }
        });
    }
}
