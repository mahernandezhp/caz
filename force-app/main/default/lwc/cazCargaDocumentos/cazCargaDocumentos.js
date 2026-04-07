import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDocumentosRequeridos from '@salesforce/apex/CAZ_DocumentoSolicitudController.getDocumentosRequeridos';
import etiquetarDocumento from '@salesforce/apex/CAZ_DocumentoSolicitudController.etiquetarDocumento';

export default class CazCargaDocumentos extends LightningElement {
    @api recordId;
    @api processName = 'Devolucion';
    @api title = 'Documentos Requeridos';

    @track isLoading = true;
    @track errorMessage = '';
    @track documentosRequeridos = [];
    @track uploadedFiles = [];
    @track selectedTipoDocumento = '';

    acceptedFormats = ['.pdf', '.jpg', '.jpeg', '.png', '.xlsx', '.xls'];

    /** Opciones para el combobox del tipo de documento */
    get tipoDocumentoOptions() {
        return this.documentosRequeridos.map(doc => ({
            label: doc.label + (doc.obligatorio ? ' *' : ''),
            value: doc.label
        }));
    }

    /** Desactiva el file-upload si no se ha seleccionado un tipo de documento */
    get isUploadDisabled() {
        return !this.selectedTipoDocumento;
    }

    /** Conteo de documentos obligatorios aún faltantes */
    get documentosFaltantes() {
        const uploadedTypes = this.uploadedFiles.map(f => f.tipoDocumento);
        return this.documentosRequeridos
            .filter(doc => doc.obligatorio && !uploadedTypes.includes(doc.label));
    }

    get hayDocumentosFaltantes() {
        return this.documentosFaltantes.length > 0;
    }

    get mensajeFaltantes() {
        if (!this.hayDocumentosFaltantes) return '';
        const nombres = this.documentosFaltantes.map(d => d.label).join(', ');
        return `Documentos obligatorios pendientes: ${nombres}`;
    }

    connectedCallback() {
        this.loadDocumentos();
    }

    loadDocumentos() {
        this.isLoading = true;
        getDocumentosRequeridos({ processName: this.processName })
            .then(result => {
                this.documentosRequeridos = result.map(doc => ({
                    label: doc.MasterLabel,
                    obligatorio: doc.CAZ_Obligatorio__c,
                    iconName: doc.CAZ_Obligatorio__c ? 'utility:error' : 'utility:info',
                    cargado: false
                }));
                this.isLoading = false;
            })
            .catch(() => {
                this.errorMessage = 'Error al cargar los documentos requeridos.';
                this.isLoading = false;
            });
    }

    handleTipoDocumentoChange(event) {
        this.selectedTipoDocumento = event.detail.value;
    }

    handleUploadFinished(event) {
        const files = event.detail.files;
        if (!files || files.length === 0) return;

        this.isLoading = true;
        const tipoSeleccionado = this.selectedTipoDocumento;

        // Etiquetar cada archivo subido con el tipo de documento seleccionado
        const promises = files.map(file =>
            etiquetarDocumento({
                contentDocumentId: file.documentId,
                tipoDocumento: tipoSeleccionado
            })
        );

        Promise.all(promises)
            .then(() => {
                // Agregar al listado de archivos cargados
                const nuevosArchivos = files.map(file => ({
                    documentId: file.documentId,
                    name: file.name,
                    tipoDocumento: tipoSeleccionado
                }));
                this.uploadedFiles = [...this.uploadedFiles, ...nuevosArchivos];

                // Marcar el documento como cargado en la lista de requeridos
                this.documentosRequeridos = this.documentosRequeridos.map(doc => ({
                    ...doc,
                    cargado: doc.label === tipoSeleccionado ? true : doc.cargado,
                    iconName: doc.label === tipoSeleccionado ? 'action:approval' : doc.iconName
                }));

                this.selectedTipoDocumento = '';
                this.isLoading = false;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Documento cargado',
                    message: `"${tipoSeleccionado}" adjuntado correctamente.`,
                    variant: 'success'
                }));

                // Notificar al componente padre el estado de carga
                this.dispatchEvent(new CustomEvent('documentosupdated', {
                    detail: {
                        totalRequeridos: this.documentosRequeridos.filter(d => d.obligatorio).length,
                        totalCargados: this.uploadedFiles.length,
                        completo: !this.hayDocumentosFaltantes
                    }
                }));
            })
            .catch(error => {
                this.isLoading = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error al etiquetar documento',
                    message: error.body ? error.body.message : 'Error desconocido.',
                    variant: 'error'
                }));
            });
    }
}