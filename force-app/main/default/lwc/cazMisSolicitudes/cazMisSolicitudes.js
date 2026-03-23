import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getMisSolicitudes from '@salesforce/apex/CAZ_SolicitudDevolucionController.getMisSolicitudes';

const STATUS_CLASSES = {
    'Borrador': 'slds-theme_shade',
    'Por atender': 'slds-theme_info',
    'En Proceso': 'slds-theme_warning',
    'Vencido': 'slds-theme_error',
    'Completado': 'slds-theme_success',
    'Rechazado': 'slds-theme_error'
};

export default class CazMisSolicitudes extends NavigationMixin(LightningElement) {
    @track isLoading = true;
    @track solicitudes = [];

    get hasSolicitudes() {
        return this.solicitudes && this.solicitudes.length > 0;
    }

    connectedCallback() {
        this.loadSolicitudes();
    }

    loadSolicitudes() {
        this.isLoading = true;
        getMisSolicitudes()
            .then(result => {
                this.solicitudes = result.map(caso => ({
                    ...caso,
                    statusClass: STATUS_CLASSES[caso.Status] || '',
                    importeFormatted: caso.CAZ_ImporteDevolucion__c
                        ? '$' + Number(caso.CAZ_ImporteDevolucion__c).toLocaleString('es-MX', { minimumFractionDigits: 2 })
                        : '-',
                    fechaFormatted: caso.CreatedDate
                        ? new Date(caso.CreatedDate).toLocaleDateString('es-MX')
                        : '-'
                }));
                this.isLoading = false;
            })
            .catch(() => {
                this.isLoading = false;
            });
    }

    handleNuevaSolicitud() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Nueva_Solicitud__c' }
        });
    }

    handleVerDetalle(event) {
        const caseId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                actionName: 'view'
            }
        });
    }
}
