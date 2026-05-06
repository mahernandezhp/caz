import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCaseData from '@salesforce/apex/CAZ_CaseListCtrl.getCaseData';
import CazCreditRequestForm from 'c/cazCreditRequestForm';

// Alternativa para pintar estatus nativamente
const STATUS_CLASSES = {
    'Borrador': 'status-borrador',
    'New': 'status-borrador',
    'Por Autorizar': 'status-por-autorizar',
    'Autorizado': 'status-autorizado',
    'En Revisión': 'status-en-revision',
    'En revisión': 'status-en-revision',
    'Rechazado': 'status-rechazado',
    'Aprobado': 'status-aprobado',
    'Completado': 'status-completado',
    'Closed': 'status-completado'
};

export default class CazMyCases extends NavigationMixin(LightningElement) {
    @api title = 'My Cases';
    @api recordTypeDevName = '';
    @api fieldsToShow = 'CaseNumber,Subject,Status,CreatedDate';
    @api emptyMessage = 'No cases found.';
    @api listPageSize = 10;
    @api targetPageName = 'solicitudCreditoDetail__c';
    
    @track pageNumber = 1;
    @track totalRecords = 0;
    @track totalPages = 1;
    @track isLoading = true;
    
    @track records = [];

    get hasRecords() {
        return this.records && this.records.length > 0;
    }

    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber >= this.totalPages;
    }

    connectedCallback() {
        this.loadCases();
    }

    loadCases() {
        this.isLoading = true;
        
        let size = parseInt(this.listPageSize, 10);
        if(isNaN(size)) size = 10;
        
        const offset = (this.pageNumber - 1) * size;
        
        getCaseData({
            recordTypeDevName: this.recordTypeDevName,
            fieldsToShow: this.fieldsToShow,
            limitSize: size,
            offsetSize: offset
        })
        .then(result => {
            this.records = result.records.map(record => {
                let statusClass = 'slds-badge ';
                if(record.Status && STATUS_CLASSES[record.Status]) {
                    statusClass += STATUS_CLASSES[record.Status];
                } else {
                    statusClass += 'status-default';
                }
                
                return {
                    ...record,
                    statusCssClass: statusClass
                };
            });

            this.totalRecords = result.totalRecords;
            this.totalPages = Math.ceil(this.totalRecords / size) || 1;
            this.isLoading = false;
        })
        .catch(error => {
            console.error('Error fetching Case data', error);
            this.isLoading = false;
        });
    }

    handlePreviousPage() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.loadCases();
        }
    }

    handleNextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.loadCases();
        }
    }

    async handleNewRequest() {
        await CazCreditRequestForm.open({
            size: 'small',
            description: 'Nueva Solicitud Form',
            recordTypeDevName: this.recordTypeDevName
        });
        
        // Always refresh: a Case might have been drafted (Step 1) but modal was closed before "Finish" (Step 2).
        this.pageNumber = 1;
        this.loadCases();
    }
    
    handleVerDetalle(event) {
        event.preventDefault();
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: this.targetPageName
            },
            state: {
                recordId: recordId
            }
        });
    }
}