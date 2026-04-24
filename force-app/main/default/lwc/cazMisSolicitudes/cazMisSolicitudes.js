import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMisSolicitudes from '@salesforce/apex/CAZ_SolicitudDevolucionController.getMisSolicitudes';
import getTotalSolicitudes from '@salesforce/apex/CAZ_SolicitudDevolucionController.getTotalSolicitudes';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const STATUS_CLASSES = {
    'Borrador': 'slds-theme_shade',
    'Por atender': 'slds-theme_info',
    'En revisión Tesorería': 'slds-theme_warning',
    'Aprobado': 'slds-theme_success',
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
                this.solicitudes = result.map(caso => ({
                    ...caso,
                    statusClass: STATUS_CLASSES[caso.CAZ_Status__c] || '',
                    isBorrador: caso.CAZ_Status__c === 'Borrador',
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

    @track showNewRequestModal = false;

    handleNuevaSolicitud() {
        this.showNewRequestModal = true;
    }

    closeNewRequestModal(event) {
        this.showNewRequestModal = false;
        // Refrescar las solicitudes para que aparezca la nueva
        this.initPagination();

        // Si el evento de cierre trajo un id de registro nuevo, navegar al detalle
        if (event && event.detail && event.detail.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.detail.recordId,
                    objectApiName: 'CAZ_SolicitudDevolucion__c',
                    actionName: 'view'
                }
            });
        }
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
}