import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getMisSolicitudes from '@salesforce/apex/CAZ_SolicitudDevolucionController.getMisSolicitudes';
import getTotalSolicitudes from '@salesforce/apex/CAZ_SolicitudDevolucionController.getTotalSolicitudes';
import enviarSolicitud from '@salesforce/apex/CAZ_SolicitudDevolucionController.enviarSolicitud';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const STATUS_CLASSES = {
    'Borrador': 'slds-theme_shade',
    'Por atender': 'slds-theme_info',
    'En Proceso': 'slds-theme_warning',
    'Vencido': 'slds-theme_error',
    'Completado': 'slds-theme_success',
    'Rechazado': 'slds-theme_error'
};

export default class CazMisSolicitudes extends NavigationMixin(LightningElement) {
    @api title = 'Mis Solicitudes de Devolución';
    @api listPageSize = 10;
    @api newRequestPageName = 'Nueva_Solicitud__c';

    // Paginated logic variables
    @track pageNumber = 1;
    @track totalRecords = 0;
    @track totalPages = 1;

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
                this.solicitudes = result.map(caso => ({
                    ...caso,
                    statusClass: STATUS_CLASSES[caso.Status] || '',
                    isBorrador: caso.Status === 'Borrador',
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

    handleNuevaSolicitud() {
        if (this.newRequestPageName === 'SPA') {
            this.dispatchEvent(new CustomEvent('navigatetopage', { detail: { target: 'nueva_solicitud' } }));
        } else {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: { name: this.newRequestPageName }
            });
        }
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

    handleEnviar(event) {
        const caseId = event.currentTarget.dataset.id;
        this.isLoading = true;
        enviarSolicitud({ caseId: caseId })
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
