import LightningModal from 'lightning/modal';
import { api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import getDocumentosRequeridos from '@salesforce/apex/CAZ_DocumentoSolicitudCtrl.getDocumentosRequeridos';
import etiquetarDocumento from '@salesforce/apex/CAZ_DocumentoSolicitudCtrl.etiquetarDocumento';
import getDocumentosCargados from '@salesforce/apex/CAZ_DocumentoSolicitudCtrl.getDocumentosCargados';
import eliminarDocumento from '@salesforce/apex/CAZ_DocumentoSolicitudCtrl.eliminarDocumento';
import getSessionUserInfo from '@salesforce/apex/CAZ_DocumentoSolicitudCtrl.getSessionUserInfo';

export default class CazCreditRequestForm extends NavigationMixin(LightningModal) {
    @api recordTypeDevName = 'SolicitudCredito';
    
    @track isStep1 = true;
    @track isLoading = true;
    @track recordTypeIdLoaded = false;
    @track createdCaseId;
    @track recordTypeId;

    @track selectedDocType = '';
    @track docTypeOptions = [];
    @track uploadedDocs = [];
    @track missingDocsText = '';
    @track isSubmitDisabled = true;

    @track userName = '';
    @track accountName = '';
    @track userRFC = '';

    connectedCallback() {
        getSessionUserInfo()
            .then(result => {
                this.userName = result.ContactName;
                this.accountName = result.AccountName;
                this.userRFC = result.RFC;
            })
            .catch(error => console.error(error));
    }

    get hasMoreDocsToUpload() {
        return this.docTypeOptions && this.docTypeOptions.length > 0;
    }

    get rightColumnClass() {
        return this.hasMoreDocsToUpload 
            ? 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2' 
            : 'slds-col slds-size_1-of-1';
    }

    // Obtener RecordType dinamicamente usando Wire y uiObjectInfoApi sin Apex
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    wireObjectInfo({ error, data }) {
        if (data) {
            const rtis = data.recordTypeInfos;
            this.recordTypeId = Object.keys(rtis).find(rti => rtis[rti].developerName === this.recordTypeDevName) || null;
            this.recordTypeIdLoaded = true;
        } else if (error) {
            console.error('Error parsing object info', error);
            this.isLoading = false;
        }
    }

    get formStyle() {
        return this.isLoading ? 'opacity: 0; pointer-events: none;' : 'opacity: 1; transition: opacity 0.5s ease-in;';
    }

    get acceptedFormats() {
        return ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];
    }

    handleLoad() {
        this.isLoading = false;
    }

    handleCancel() {
        this.close('cancel');
    }

    handleSubmit(event) {
        event.preventDefault(); 
        this.isLoading = true;
        const fields = event.detail.fields;
        fields.Status = 'Borrador';
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    async handleSuccess(event) {
        this.createdCaseId = event.detail.id;
        this.isStep1 = false; 
        
        try {
            await this.loadDocumentInfo();
        } catch(e){
            console.error(e);
        }
        
        this.isLoading = false;
    }
    
    handleError(event) {
        this.isLoading = false;
    }

    async loadDocumentInfo() {
        try {
            // 1. Requeridos
            const metadataRequired = await getDocumentosRequeridos({ processName: this.recordTypeDevName, recordId: this.createdCaseId });

            // 2. Ya cargados
            const cargados = await getDocumentosCargados({ recordId: this.createdCaseId });
            this.uploadedDocs = cargados.map(d => {
                return {
                    id: d.documentId,
                    name: d.name,
                    tipoDocumento: d.tipoDocumento || 'Sin etiqueta'
                };
            });
            
            // Llenar combo de opciones omitiendo los ya subidos
            this.docTypeOptions = metadataRequired
                .filter(doc => !this.uploadedDocs.some(u => u.tipoDocumento === doc.MasterLabel))
                .map(doc => {
                    return { label: doc.MasterLabel, value: doc.MasterLabel };
                });
                
            if(this.docTypeOptions.length > 0) {
                // Mantener el seleccionado si aun existe, si no, tomar el primero
                if (!this.docTypeOptions.some(opt => opt.value === this.selectedDocType)) {
                    this.selectedDocType = this.docTypeOptions[0].value;
                }
            } else {
                this.selectedDocType = '';
            }

            // 3. Evaluar faltantes
            let missingArr = [];
            for(let req of metadataRequired) {
                if(req.CAZ_Obligatorio__c) {
                    let yaEsta = this.uploadedDocs.some(u => u.tipoDocumento === req.MasterLabel);
                    if(!yaEsta) {
                        missingArr.push(req.MasterLabel);
                    }
                }
            }

            if(missingArr.length > 0) {
                this.missingDocsText = missingArr.join(', ');
                this.isSubmitDisabled = true;
            } else {
                this.missingDocsText = '';
                this.isSubmitDisabled = false;
            }

        } catch (error) {
            console.error('Error loading documents:', error);
            throw error;
        }
    }

    handleDocTypeChange(event) {
        this.selectedDocType = event.detail.value;
    }

    async handleUploadFinished(event) {
        if(event.detail.files && event.detail.files.length > 0) {
            this.isLoading = true;
            try {
                // Tomar el ultimo subido (quitamos multiple del html)
                const uploadedFileId = event.detail.files[0].documentId;
                await etiquetarDocumento({
                    contentDocumentId: uploadedFileId,
                    tipoDocumento: this.selectedDocType
                });
                
                await this.loadDocumentInfo(); 

            } catch(e) {
                console.error('Error en upload', e);
            } finally {
                this.isLoading = false;
            }
        }
    }

    async deleteDoc(event) {
        this.isLoading = true;
        const docId = event.currentTarget.dataset.id;
        try {
            await eliminarDocumento({ documentId: docId });
            await this.loadDocumentInfo();
        } catch(e) {
            console.error(e);
        } finally {
            this.isLoading = false;
        }
    }

    previewDoc(event) {
        const docId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state : {
                selectedRecordId: docId
            }
        });
    }

    async handleFinish() {
        this.isLoading = true;
        try {
            const fields = {};
            fields['Id'] = this.createdCaseId;
            fields['Status'] = 'En revisión'; 
            
            const recordInput = { fields };
            await updateRecord(recordInput);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Éxito', message: 'Solicitud enviada a revisión.', variant: 'success'
                })
            );
            this.close('success');
        } catch(e) {
            console.error('Error enviando solicitud', e);
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Error', message: 'Hubo un error al actualizar el estatus.', variant: 'error'})
            );
            this.isLoading = false;
        }
    }
}