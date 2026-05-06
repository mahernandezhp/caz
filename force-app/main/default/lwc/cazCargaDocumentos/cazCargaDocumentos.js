import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getDocumentosRequeridos from '@salesforce/apex/CAZ_DocumentoSolicitudCtrl.getDocumentosRequeridos';
import etiquetarDocumento from '@salesforce/apex/CAZ_DocumentoSolicitudCtrl.etiquetarDocumento';
import getDocumentosCargados from '@salesforce/apex/CAZ_DocumentoSolicitudCtrl.getDocumentosCargados';
import eliminarDocumento from '@salesforce/apex/CAZ_DocumentoSolicitudCtrl.eliminarDocumento';

export default class CazCargaDocumentos extends NavigationMixin(LightningElement) {
    @api recordId;
    @api processName = 'Devolucion';
    @api title = 'Documentos Requeridos';
    @api readonlyMode = false;

    @track isLoading = true;
    @track errorMessage = '';
    @track documentosRequeridos = [];
    @track uploadedFiles = [];
    @track selectedTipoDocumento = '';

    acceptedFormats = ['.pdf'];

    /** Opciones para el combobox del tipo de documento */
    get tipoDocumentoOptions() {
        const uploadedTypes = this.uploadedFiles.map(f => f.tipoDocumento);
        return this.documentosRequeridos
            .filter(doc => !uploadedTypes.includes(doc.label))
            .map(doc => ({
                label: doc.label + (doc.obligatorio ? ' *' : ''),
                value: doc.label
            }));
    }

    get hasOpcionesDocumentos() {
        return this.tipoDocumentoOptions && this.tipoDocumentoOptions.length > 0;
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

    setDefaultTipoDocumento() {
        const options = this.tipoDocumentoOptions;
        if (options && options.length > 0) {
            const isValidSelection = options.some(opt => opt.value === this.selectedTipoDocumento);
            if (!isValidSelection || !this.selectedTipoDocumento) {
                this.selectedTipoDocumento = options[0].value;
            }
        } else {
            this.selectedTipoDocumento = '';
        }
    }

    async connectedCallback() {
        this.isLoading = true;
        try {
            await this.loadDocumentos();
            if (this.recordId) {
                await this.loadArchivosExistentes();
            }
        } finally {
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('documentosupdated', {
                detail: {
                    totalRequeridos: this.documentosRequeridos.filter(d => d.obligatorio).length,
                    totalCargados: this.uploadedFiles.length,
                    completo: !this.hayDocumentosFaltantes
                }
            }));
        }
    }

    loadArchivosExistentes() {
        return getDocumentosCargados({ recordId: this.recordId })
            .then(result => {
                if (result && result.length > 0) {
                    this.uploadedFiles = result.map(f => ({
                        ...f,
                        downloadUrl: `/sfc/servlet.shepherd/document/download/${f.documentId}`
                    }));
                    // Actualizar los íconos de la lista de requeridos si ya fueron cargados previamente
                    const uploadedTypes = this.uploadedFiles.map(f => f.tipoDocumento);
                    this.documentosRequeridos = this.documentosRequeridos.map(doc => ({
                        ...doc,
                        cargado: uploadedTypes.includes(doc.label) ? true : doc.cargado,
                        iconName: uploadedTypes.includes(doc.label) ? 'action:approval' : doc.iconName
                    }));
                    this.setDefaultTipoDocumento();
                }
            })
            .catch(error => {
                console.error('Error cargando archivos existentes:', error);
            });
    }

    loadDocumentos() {
        return getDocumentosRequeridos({ processName: this.processName, recordId: this.recordId })
            .then(result => {
                this.documentosRequeridos = result.map(doc => ({
                    label: doc.MasterLabel,
                    obligatorio: doc.CAZ_Obligatorio__c,
                    iconName: doc.CAZ_Obligatorio__c ? 'utility:error' : 'utility:info',
                    cargado: false
                }));
                this.setDefaultTipoDocumento();
            })
            .catch(() => {
                this.errorMessage = 'Error al cargar los documentos requeridos.';
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
                    tipoDocumento: tipoSeleccionado,
                    downloadUrl: `/sfc/servlet.shepherd/document/download/${file.documentId}`
                }));
                this.uploadedFiles = [...this.uploadedFiles, ...nuevosArchivos];

                // Marcar el documento como cargado en la lista de requeridos
                this.documentosRequeridos = this.documentosRequeridos.map(doc => ({
                    ...doc,
                    cargado: doc.label === tipoSeleccionado ? true : doc.cargado,
                    iconName: doc.label === tipoSeleccionado ? 'action:approval' : doc.iconName
                }));

                this.setDefaultTipoDocumento();
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

    handleDeleteDocument(event) {
        const documentId = event.target.dataset.id;
        const tipoDocumento = event.target.dataset.type;

        this.isLoading = true;
        eliminarDocumento({ documentId: documentId })
            .then(() => {
                this.uploadedFiles = this.uploadedFiles.filter(f => f.documentId !== documentId);

                const stillHasType = this.uploadedFiles.some(f => f.tipoDocumento === tipoDocumento);
                if (!stillHasType) {
                    this.documentosRequeridos = this.documentosRequeridos.map(doc => ({
                        ...doc,
                        cargado: doc.label === tipoDocumento ? false : doc.cargado,
                        iconName: doc.label === tipoDocumento 
                            ? (doc.obligatorio ? 'utility:error' : 'utility:info') 
                            : doc.iconName
                    }));
                }

                this.setDefaultTipoDocumento();

                this.isLoading = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Documento eliminado',
                    message: `El documento de tipo "${tipoDocumento}" fue eliminado exitosamente.`,
                    variant: 'success'
                }));

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
                    title: 'Error al eliminar',
                    message: error.body ? error.body.message : 'Error al procesar la solicitud.',
                    variant: 'error'
                }));
            });
    }


}