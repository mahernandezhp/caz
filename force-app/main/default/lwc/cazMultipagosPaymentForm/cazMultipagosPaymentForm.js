import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import preparePayment from '@salesforce/apex/CAZ_MultipagosPaymentService.preparePayment';

/**
 * cazMultipagosPaymentForm
 *
 * LWC que invoca CAZ_MultipagosPaymentService.preparePayment(orderId),
 * recibe el DTO PaymentRequestData, construye un <form> HTML oculto con
 * los parámetros mp_* y hace submit() nativo para redirigir el navegador
 * a Multipagos (BBVA / Flap).
 *
 * Flujo:
 *   1. Usuario hace click en "Pagar"
 *   2. handlePagar() → imperativo preparePayment({ orderId })
 *   3. Al recibir el DTO, buildAndSubmitForm() inyecta un <form> en el DOM
 *      (fuera del shadow root para que el submit navegue realmente) y lo
 *      envía vía submit() nativo del navegador.
 *
 * Notas Experience Cloud / CSRF:
 *   - El manual técnico de Multipagos obliga a que el submit sea una
 *     navegación full-page (no fetch/AJAX) para evitar que Chrome bloquee
 *     la respuesta por CSRF. form.submit() nativo cumple con esto.
 *   - El <form> se monta en document.body (no en el shadow root) porque
 *     los forms dentro de shadowRoot pueden ser filtrados por el runtime
 *     de LWC locker. Montarlo en document.body garantiza que el submit se
 *     ejecute como un form HTML estándar. 
 */
export default class CazMultipagosPaymentForm extends NavigationMixin(LightningElement) {
    @api recordId;
    @api buttonLabel = 'Pagar con Multipagos';

    isLoading = false;
    errorMessage;

    get isDisabled() {
        return this.isLoading || !this.recordId;
    }

    get hasError() {
        return !!this.errorMessage;
    }

    handlePagar() {
        if (!this.recordId) {
            this.showToast('Error', 'No se recibió el ID de la orden.', 'error');
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;

        preparePayment({ orderId: this.recordId })
            .then((dto) => {
                if (!dto) {
                    throw new Error('Respuesta vacía del servicio de preparación de pago.');
                }
                this.buildAndSubmitForm(dto);
            })
            .catch((error) => {
                this.isLoading = false;
                const message = this.extractErrorMessage(error);
                this.errorMessage = message;
                this.showToast('Error al preparar el pago', message, 'error');
            });
    }

    buildAndSubmitForm(dto) {
        const endpoint = dto.multipagosEndpoint;
        if (!endpoint) {
            this.isLoading = false;
            const message = 'La configuración de Multipagos no tiene endpoint definido.';
            this.errorMessage = message;
            this.showToast('Error de configuración', message, 'error');
            return;
        }

        const fields = {
            mp_account: dto.mp_account,
            mp_product: dto.mp_product,
            mp_order: dto.mp_order,
            mp_reference: dto.mp_reference,
            mp_node: dto.mp_node,
            mp_concept: dto.mp_concept,
            mp_amount: dto.mp_amount,
            mp_currency: dto.mp_currency,
            mp_signature: dto.mp_signature,
            mp_urlsuccess: dto.mp_urlsuccess,
            mp_urlfailure: dto.mp_urlfailure
        };
        const formFields = Object.entries(fields).reduce((acc, [name, value]) => {
            if (value !== null && value !== undefined) {
                acc[name] = String(value);
            }
            return acc;
        }, {});
        console.log(
            'Multipagos POST payload:',
            JSON.stringify(
                {
                    method: 'POST',
                    action: endpoint,
                    fields: formFields
                },
                null,
                2
            )
        );

        const form = document.createElement('form');
        form.setAttribute('method', 'POST');
        form.setAttribute('action', endpoint);
        form.setAttribute('target', '_self');
        form.style.display = 'none';

        Object.keys(formFields).forEach((name) => {
            const input = document.createElement('input');
            input.setAttribute('type', 'hidden');
            input.setAttribute('name', name);
            input.setAttribute('value', formFields[name]);
            form.appendChild(input);
        });

        document.body.appendChild(form);
        //form.submit();
    }

    extractErrorMessage(error) {
        if (!error) {
            return 'Error desconocido al contactar con Multipagos.';
        }
        if (error.body && error.body.message) {
            return error.body.message;
        }
        if (error.message) {
            return error.message;
        }
        return 'Error desconocido al contactar con Multipagos.';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}