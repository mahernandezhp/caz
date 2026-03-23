import { LightningElement, api, wire, track } from 'lwc';
import { getRecords } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDocumentosRequeridos from '@salesforce/apex/CAZ_DocumentoSolicitudController.getDocumentosDevolucion';

export default class CazCargaDocumentos extends LightningElement {
    @api recordId;

    @track isLoading = true;
    @track errorMessage = '';
    @track documentosRequeridos = [];
    @track uploadedFiles = [];

    acceptedFormats = ['.pdf', '.jpg', '.jpeg', '.png', '.xlsx', '.xls'];

    connectedCallback() {
        this.loadDocumentos();
    }

    loadDocumentos() {
        this.isLoading = true;
        getDocumentosRequeridos()
            .then(result => {
                this.documentosRequeridos = result.map(doc => ({
                    label: doc.MasterLabel,
                    obligatorio: doc.CAZ_Obligatorio__c,
                    iconName: doc.CAZ_Obligatorio__c ? 'utility:error' : 'utility:info'
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.errorMessage = 'Error al cargar los documentos requeridos.';
                this.isLoading = false;
            });
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        this.uploadedFiles = [...this.uploadedFiles, ...uploadedFiles];
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Documentos cargados',
                message: `${uploadedFiles.length} documento(s) adjuntado(s) correctamente.`,
                variant: 'success'
            })
        );
    }
}
