import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMisSolicitudes from '@salesforce/apex/CAZ_SolicitudCreditoController.getMisSolicitudes';
import getTotalSolicitudes from '@salesforce/apex/CAZ_SolicitudCreditoController.getTotalSolicitudes';
import enviarSolicitud from '@salesforce/apex/CAZ_SolicitudCreditoController.enviarSolicitud';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const STATUS_CLASSES = {
    'Borrador': 'slds-theme_shade',
    'Por atender': 'slds-theme_info',
    'En Revisión': 'slds-theme_warning',
    'Autorizado': 'slds-theme_success',
    'Aprobado': 'slds-theme_success',
    'Rechazado': 'slds-theme_error',
    'Completado': 'slds-theme_success'
};

export default class CazMisSolicitudesCredito extends NavigationMixin(LightningElement) {
    @api title = 'Mis Solicitudes de Ampliación de Crédito';
    @api listPageSize = 10;

    @track pageNumber = 1;
    @track totalRecords = 0;
    @track totalPages = 1;
    isLoading = true;
    solicitudes = [];

    get hasSolicitudes() {
        return this.solicitudes && this.solicitudes.length > 0;
    }

    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber >= this.totalPages;
    }

    connectedCallback() {
        this.initPagination();
    }

    initPagination() {
        this.isLoading = true;
        getTotalSolicitudes()
            .then(result => {
                this.totalRecords = result;
                this.totalPages = Math.ceil(this.totalRecords / this.listPageSize) || 1;
                this.loadSolicitudes();
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error fetching total records', error);
            });
    }

    loadSolicitudes() {
        this.isLoading = true;
        const offset = (this.pageNumber - 1) * this.listPageSize;

        getMisSolicitudes({ limitSize: this.listPageSize, offsetSize: offset })
            .then(result => {
                this.solicitudes = result.map(sol => ({
                    ...sol,
                    statusClass: STATUS_CLASSES[sol.CAZ_Estatus__c] || '',
                    isBorrador: sol.CAZ_Estatus__c === 'Borrador',
                    montoFormatted: sol.CAZ_MontoSolicitado__c
                        ? '$' + Number(sol.CAZ_MontoSolicitado__c).toLocaleString('es-MX', { minimumFractionDigits: 2 })
                        : '-',
                    diasFormatted: sol.CAZ_Dias__c != null ? sol.CAZ_Dias__c + ' días' : '-',
                    fechaFormatted: sol.CreatedDate
                        ? new Date(sol.CreatedDate).toLocaleDateString('es-MX')
                        : '-'
                }));
                this.isLoading = false;
            })
            .catch(() => {
                this.isLoading = false;
            });
    }

    handlePreviousPage() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.loadSolicitudes();
        }
    }

    handleNextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.loadSolicitudes();
        }
    }

    @track showNewRequestModal = false;

    handleNuevaSolicitud() {
        this.showNewRequestModal = true;
    }

    closeNewRequestModal() {
        this.showNewRequestModal = false;
        this.initPagination();
    }

    handleVerDetalle(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    handleEnviar(event) {
        const recordId = event.currentTarget.dataset.id;
        this.isLoading = true;
        enviarSolicitud({ recordId: recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Éxito',
                        message: 'La solicitud ha sido enviada a revisión.',
                        variant: 'success'
                    })
                );
                this.loadSolicitudes();
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