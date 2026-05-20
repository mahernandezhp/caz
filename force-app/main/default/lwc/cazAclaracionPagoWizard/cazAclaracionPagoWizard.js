import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDistribuidoresDelUsuario from '@salesforce/apex/CAZ_AclaracionPagoController.getDistribuidoresDelUsuario';
import enviarSolicitud from '@salesforce/apex/CAZ_AclaracionPagoController.enviarSolicitud';

const ESTADO_INICIAL = 1;
const ESTADO_FORMULARIO = 2;
const ESTADO_CONFIRMACION = 3;

export default class CazAclaracionPagoWizard extends LightningElement {
    @track currentStep = ESTADO_INICIAL;
    @track isLoading = false;
    
    // Distribuidores
    @track distribuidores = [];
    selectedAccountId = '';
    
    // Formulario
    motivo = '';
    numeroFactura = '';
    monto = null;
    fechaPago = '';
    referencia = '';
    descripcion = '';
    comprobanteUrl = '';
    
    // Archivos subidos
    @track uploadedFiles = [];
    
    caseIdCreated = '';
    
    get isStep1() { return this.currentStep === ESTADO_INICIAL; }
    get isStep2() { return this.currentStep === ESTADO_FORMULARIO; }
    get isStep3() { return this.currentStep === ESTADO_CONFIRMACION; }
    
    get distribuidoresOptions() {
        return this.distribuidores.map(acc => {
            return { label: `${acc.AccountNumber} - ${acc.Name}`, value: acc.Id };
        });
    }
    
    get motivosOptions() {
        return [
            { label: 'Pago duplicado', value: 'Pago duplicado' },
            { label: 'No se ve reflejado en el portal', value: 'No se ve reflejado en el portal' },
            { label: 'Error en la referencia', value: 'Error en la referencia' },
            { label: 'Error en pago de convenio', value: 'Error en pago de convenio' },
            { label: 'Error en clave de distribuidor', value: 'Error en clave de distribuidor' }
        ];
    }
    
    get isNextStep1Disabled() {
        return !this.selectedAccountId;
    }
    
    @wire(getDistribuidoresDelUsuario)
    wiredDistribuidores({ error, data }) {
        if (data) {
            this.distribuidores = data;
            if (data.length === 1) {
                this.selectedAccountId = data[0].Id;
            }
        } else if (error) {
            this.showToast('Error', 'No se pudieron cargar los distribuidores asociados.', 'error');
            console.error(error);
        }
    }
    
    handleAccountChange(event) {
        this.selectedAccountId = event.detail.value;
    }
    
    handleInputChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
    }
    
    handleUploadFinished(event) {
        const files = event.detail.files;
        if (files.length > 0) {
            this.comprobanteUrl = files[0].documentId;
            this.uploadedFiles = files;
            this.showToast('Éxito', `Archivo ${files[0].name} cargado correctamente.`, 'success');
        }
    }
    
    removeFile() {
        this.comprobanteUrl = '';
        this.uploadedFiles = [];
    }
    
    get hasFile() {
        return this.uploadedFiles.length > 0;
    }
    
    get fileName() {
        return this.hasFile ? this.uploadedFiles[0].name : '';
    }
    
    goToStep2() {
        this.currentStep = ESTADO_FORMULARIO;
    }
    
    goToStep1() {
        this.currentStep = ESTADO_INICIAL;
    }
    
    validateForm() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
            
        if (!isInputsCorrect) {
            this.showToast('Atención', 'Por favor complete todos los campos requeridos.', 'warning');
        }
        return isInputsCorrect;
    }
    
    handleSubmit() {
        if (!this.validateForm()) return;
        
        this.isLoading = true;
        
        const params = {
            accountId: this.selectedAccountId,
            motivo: this.motivo,
            numeroFactura: this.numeroFactura,
            monto: this.monto,
            fechaPago: this.fechaPago,
            referencia: this.referencia,
            descripcion: this.descripcion,
            comprobanteUrl: this.comprobanteUrl
        };
        
        enviarSolicitud({ params: params })
            .then(result => {
                this.caseIdCreated = result;
                this.currentStep = ESTADO_CONFIRMACION;
                this.isLoading = false;
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', 'Hubo un problema al enviar la solicitud: ' + (error.body ? error.body.message : error.message), 'error');
                this.isLoading = false;
            });
    }
    
    resetForm() {
        this.currentStep = ESTADO_INICIAL;
        this.motivo = '';
        this.numeroFactura = '';
        this.monto = null;
        this.fechaPago = '';
        this.referencia = '';
        this.descripcion = '';
        this.comprobanteUrl = '';
        this.uploadedFiles = [];
        this.caseIdCreated = '';
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}
