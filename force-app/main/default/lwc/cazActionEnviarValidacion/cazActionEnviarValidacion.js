import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CazActionEnviarValidacion extends LightningElement {
    @api recordId;

    @api invoke() {
        const fields = {};
        fields['Id'] = this.recordId;
        fields['CAZ_Status__c'] = 'Por atender';
        
        const recordInput = { fields };
        
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Éxito',
                        message: 'La solicitud ha sido enviada a revisión correctamente.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                let errorMessage = 'Hubo un error al procesar la solicitud.';
                
                // Extraer el error del Trigger de Salesforce
                if (error.body && error.body.output && error.body.output.errors && error.body.output.errors.length > 0) {
                    errorMessage = error.body.output.errors[0].message;
                } else if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Validación de Documentos Requerida',
                        message: errorMessage,
                        variant: 'error',
                        mode: 'sticky' // Permite que se quede abierto para el usuario lo lea
                    })
                );
            });
    }
}