import { LightningElement, api } from 'lwc';
import processResponse from '@salesforce/apex/CAZ_MultipagosResponseHandler.processResponse';

/**
 * cazMultipagosPaymentResult
 *
 * LWC de retorno desde Multipagos (BBVA / Flap). Se monta en las páginas de
 * Experience Cloud configuradas como mp_urlsuccess y mp_urlfailure del CMT
 * CAZ_MultipagosConfiguration__mdt.
 *
 * Flujo:
 *   1. connectedCallback() extrae los parámetros mp_* desde window.location.search
 *      (Multipagos hace POST-redirect pero Experience Cloud materializa el payload
 *      como query params en la URL de retorno).
 *   2. Si no hay parámetros mínimos, se muestra un estado "sin información de
 *      transacción" — caso típico cuando un usuario navega directo a la página.
 *   3. Si los parámetros existen, se envían vía Apex imperativo a
 *      CAZ_MultipagosResponseHandler.processResponse(JSON, document.referrer).
 *   4. El DTO PaymentResultData retornado por el handler se mapea a una vista
 *      con variantes Approved / Rejected / Signature_Invalid / Error.
 *   5. El flag alreadyProcessed se muestra como nota informativa cuando el
 *      Payment ya no estaba Pending en el momento de la re-entrada (refresh).
 *
 * Notas:
 *   - El componente NO re-calcula firmas ni toca datos: delega todo al handler.
 *   - document.referrer se pasa al handler para la validación de referer; si el
 *     browser lo omite (algunas políticas de privacidad lo hacen), el handler
 *     degrada el flag refererValid pero no falla.
 */

const MP_PARAMS = [
    'mp_order',
    'mp_reference',
    'mp_amount',
    'mp_response',
    'mp_responsemsg',
    'mp_authorization',
    'mp_signature'
];

const STATUS_APPROVED          = 'Approved';
const STATUS_REJECTED          = 'Rejected';
const STATUS_SIGNATURE_INVALID = 'Signature_Invalid';
const STATUS_REFERER_INVALID   = 'Referer_Invalid';
const STATUS_ERROR             = 'Error';

export default class CazMultipagosPaymentResult extends LightningElement {
    @api homeUrl = '/';
    @api ordersUrl = '/my-orders';

    isLoading = true;
    result;
    errorMessage;
    noParams = false;

    connectedCallback() {
        const responseData = this.extractQueryParams();

        if (!responseData.mp_order || !responseData.mp_response) {
            this.isLoading = false;
            this.noParams = true;
            return;
        }

        processResponse({
            responseDataJson: JSON.stringify(responseData),
            pageReferer: document.referrer || ''
        })
            .then((dto) => {
                this.isLoading = false;
                this.result = dto;
            })
            .catch((error) => {
                this.isLoading = false;
                this.errorMessage = this.extractErrorMessage(error);
            });
    }

    extractQueryParams() {
        const params = new URLSearchParams(window.location.search);
        const data = {};
        MP_PARAMS.forEach((key) => {
            const value = params.get(key);
            data[key] = value === null ? '' : value;
        });
        return data;
    }

    extractErrorMessage(error) {
        if (!error) {
            return 'Error desconocido al procesar la respuesta de Multipagos.';
        }
        if (error.body && error.body.message) {
            return error.body.message;
        }
        if (error.message) {
            return error.message;
        }
        return 'Error desconocido al procesar la respuesta de Multipagos.';
    }

    get hasResult() {
        return !!this.result;
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get isApproved() {
        return this.hasResult && this.result.transactionStatus === STATUS_APPROVED;
    }

    get isRejected() {
        return this.hasResult && this.result.transactionStatus === STATUS_REJECTED;
    }

    get isSignatureInvalid() {
        return this.hasResult && this.result.transactionStatus === STATUS_SIGNATURE_INVALID;
    }

    get isRefererInvalid() {
        return this.hasResult && this.result.transactionStatus === STATUS_REFERER_INVALID;
    }

    get isErrorStatus() {
        return this.hasResult && this.result.transactionStatus === STATUS_ERROR;
    }

    get isAlreadyProcessed() {
        return this.hasResult && this.result.alreadyProcessed === true;
    }

    get hasResponseCode() {
        return this.hasResult && !!this.result.responseCode;
    }

    get hasResponseMessage() {
        return this.hasResult && !!this.result.responseMessage;
    }

    get hasAuthorization() {
        return this.hasResult && !!this.result.authorization;
    }

    get headerTitle() {
        if (this.isApproved) {
            return '¡Pago aprobado!';
        }
        if (this.isRejected) {
            return 'Pago rechazado';
        }
        if (this.isSignatureInvalid) {
            return 'No se pudo validar la transacción';
        }
        if (this.isRefererInvalid) {
            return 'Origen de la respuesta no reconocido';
        }
        return 'Resultado del pago';
    }

    get headerIcon() {
        if (this.isApproved) {
            return 'utility:success';
        }
        if (this.isSignatureInvalid || this.isRefererInvalid) {
            return 'utility:warning';
        }
        return 'utility:error';
    }

    get headerVariant() {
        if (this.isApproved) {
            return 'success';
        }
        if (this.isSignatureInvalid || this.isRefererInvalid) {
            return 'warning';
        }
        return 'error';
    }

    get containerClass() {
        const base = 'caz-result-card slds-box slds-p-around_large';
        if (this.isApproved) {
            return `${base} caz-result-card_success`;
        }
        if (this.isSignatureInvalid || this.isRefererInvalid) {
            return `${base} caz-result-card_warning`;
        }
        if (this.hasResult || this.hasError) {
            return `${base} caz-result-card_error`;
        }
        return base;
    }

    handleGoHome() {
        window.location.href = this.homeUrl;
    }

    handleGoOrders() {
        window.location.href = this.ordersUrl;
    }
}