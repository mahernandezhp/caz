public with sharing class CAZ_MultipagosResponseHandler {

    /**
     * ============================================================================
     * Clase: CAZ_MultipagosResponseHandler
     * ============================================================================
     * Propósito:
     * Procesar la respuesta POST que Multipagos envía al portal de retorno
     * (Experience Cloud) tras una transacción, validar su autenticidad y
     * actualizar el Payment correspondiente en Salesforce.
     *
     * Responsabilidades:
     * - Deserializar el payload recibido desde el LWC de retorno.
     * - Validar el HTTP Referer contra el host esperado del ambiente activo.
     * - Recalcular y validar la firma HMAC SHA-256 del response.
     * - Localizar el Payment original por CAZ_MultipagosOrder__c.
     * - Actualizar los campos de respuesta del Payment y derivar el estado final.
     * - Manejar reentradas duplicadas: si el Payment ya no está Pending, se
     *   retorna el estado existente sin sobreescribir.
     * - Devolver un DTO con el resultado consolidado al LWC de retorno.
     *
     * Alcance:
     * - NO genera firmas de request (Fase de preparación).
     * - NO hace callouts hacia Multipagos (el flujo es POST-redirect).
     * - NO implementa lógica de UI: el LWC consume únicamente el DTO.
     *
     * Supuestos:
     * - Existe un registro activo en CAZ_MultipagosConfiguration__mdt.
     * - La llave privada HMAC está en CAZ_MultipagosSecrets__c (org default).
     * - El Payment fue creado previamente por CAZ_MultipagosPaymentService con
     *   CAZ_TransactionStatus__c = 'Pending'.
     * ============================================================================
     */

    private static final String LOG_PREFIX = 'CAZ_MultipagosResponseHandler';

    private static final String STATUS_PENDING           = 'Pending';
    private static final String STATUS_APPROVED          = 'Approved';
    private static final String STATUS_REJECTED          = 'Rejected';
    private static final String STATUS_ERROR             = 'Error';
    private static final String STATUS_SIGNATURE_INVALID = 'Signature_Invalid';
    private static final String STATUS_REFERER_INVALID   = 'Referer_Invalid';

    private static final String APPROVED_RESPONSE_CODE = '00';

    /**
     * ============================================================================
     * DTO: MultipagosResponseData
     * ============================================================================
     * Propósito:
     * Transportar los parámetros recibidos desde Multipagos (vía LWC de retorno)
     * hacia el handler para su procesamiento.
     * ============================================================================
     */
    public class MultipagosResponseData {
        @AuraEnabled public String mp_order;
        @AuraEnabled public String mp_reference;
        @AuraEnabled public String mp_amount;
        @AuraEnabled public String mp_response;
        @AuraEnabled public String mp_responsemsg;
        @AuraEnabled public String mp_authorization;
        @AuraEnabled public String mp_signature;
    }

    /**
     * ============================================================================
     * DTO: PaymentResultData
     * ============================================================================
     * Propósito:
     * Transportar el resultado final consolidado hacia el LWC de retorno.
     * ============================================================================
     */
    public class PaymentResultData {
        @AuraEnabled public Id paymentId;
        @AuraEnabled public String transactionStatus;
        @AuraEnabled public String responseCode;
        @AuraEnabled public String responseMessage;
        @AuraEnabled public String authorization;
        @AuraEnabled public Boolean signatureValid;
        @AuraEnabled public Boolean refererValid;
        @AuraEnabled public Boolean isApproved;
        @AuraEnabled public Boolean alreadyProcessed;
    }

    /**
     * ============================================================================
     * Método: processResponse
     * ============================================================================
     * Propósito:
     * Punto de entrada expuesto al LWC de retorno. Recibe el payload de Multipagos
     * ya deserializable a MultipagosResponseData, valida referer y firma,
     * actualiza el Payment y retorna el resultado.
     *
     * Flujo:
     * 1. Deserializar el JSON recibido.
     * 2. Validar que los parámetros mínimos estén presentes.
     * 3. Leer la configuración activa y la llave privada.
     * 4. Validar referer (warning, no bloquea).
     * 5. Validar firma HMAC del response.
     * 6. Localizar el Payment por CAZ_MultipagosOrder__c.
     * 7. Si el Payment ya no está Pending, retornar el estado actual.
     * 8. Determinar el estado final, actualizar el Payment y armar el DTO.
     *
     * Parámetros:
     * @param responseDataJson JSON serializado de MultipagosResponseData.
     * @param pageReferer      Valor del header HTTP Referer capturado en el LWC.
     *
     * Retorno:
     * @return PaymentResultData con el resultado consolidado.
     *
     * Excepciones:
     * Lanza AuraHandledException si el payload es inválido o no es posible
     * procesar la respuesta por condiciones de datos.
     * ============================================================================
     */
    @AuraEnabled
    public static PaymentResultData processResponse(
        String responseDataJson,
        String pageReferer
    ) {
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | processResponse | Inicio');
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | processResponse | pageReferer=' + pageReferer);

        MultipagosResponseData responseData = parseResponseData(responseDataJson);
        validateMinimumFields(responseData);

        CAZ_MultipagosConfiguration__mdt config = getActiveConfiguration();
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | processResponse | Configuración activa: ' + config.DeveloperName);

        String secretKey = getSecretKey();
        if (String.isBlank(secretKey)) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | processResponse | SecretKey no configurada');
            throw new AuraHandledException('La configuración de seguridad de Multipagos no está completa. Contacte al administrador.');
        }

        Boolean refererValid = validateReferer(pageReferer, config.CAZ_ExpectedRefererHost__c);
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | processResponse | refererValid=' + refererValid);

        Decimal amount = parseAmount(responseData.mp_amount);

        Boolean signatureValid = CAZ_MultipagosSignatureService.isResponseSignatureValid(
            responseData.mp_order,
            responseData.mp_reference,
            amount,
            responseData.mp_authorization,
            secretKey,
            responseData.mp_signature
        );
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | processResponse | signatureValid=' + signatureValid);

        Payment existingPayment = findPaymentByMultipagosOrder(responseData.mp_order);

        if (existingPayment == null) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | processResponse | Payment no encontrado para mp_order=' + responseData.mp_order);
            return buildErrorResult(responseData, signatureValid, refererValid);
        }

        if (existingPayment.CAZ_TransactionStatus__c != null
            && existingPayment.CAZ_TransactionStatus__c != STATUS_PENDING) {
            System.debug(LoggingLevel.WARN, LOG_PREFIX + ' | processResponse | Payment ya procesado, se retorna estado actual: ' + existingPayment.CAZ_TransactionStatus__c);
            return buildAlreadyProcessedResult(existingPayment);
        }

        String finalStatus = determineTransactionStatus(
            responseData.mp_response,
            signatureValid,
            refererValid
        );
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | processResponse | finalStatus=' + finalStatus);

        updatePaymentWithResponse(
            existingPayment,
            responseData,
            finalStatus,
            signatureValid,
            refererValid
        );

        PaymentResultData result = buildPaymentResult(
            existingPayment.Id,
            finalStatus,
            responseData.mp_response,
            responseData.mp_responsemsg,
            responseData.mp_authorization,
            signatureValid,
            refererValid,
            false
        );

        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | processResponse | Fin | status=' + finalStatus);
        return result;
    }

    /**
     * ============================================================================
     * Método: parseResponseData
     * ============================================================================
     * Propósito:
     * Deserializar el JSON recibido desde el LWC a MultipagosResponseData.
     * ============================================================================
     */
    private static MultipagosResponseData parseResponseData(String responseDataJson) {
        if (String.isBlank(responseDataJson)) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | parseResponseData | responseDataJson vacío');
            throw new AuraHandledException('No se recibió información de la respuesta de Multipagos.');
        }

        try {
            MultipagosResponseData data = (MultipagosResponseData) JSON.deserialize(
                responseDataJson,
                MultipagosResponseData.class
            );
            if (data == null) {
                throw new AuraHandledException('El payload de respuesta de Multipagos es inválido.');
            }
            return data;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | parseResponseData | Error al deserializar: ' + ex.getMessage());
            throw new AuraHandledException('No fue posible interpretar la respuesta de Multipagos.');
        }
    }

    /**
     * ============================================================================
     * Método: validateMinimumFields
     * ============================================================================
     * Propósito:
     * Garantizar que los parámetros indispensables del response estén presentes.
     * mp_authorization puede llegar vacío si la transacción fue rechazada.
     * ============================================================================
     */
    private static void validateMinimumFields(MultipagosResponseData data) {
        if (String.isBlank(data.mp_order)
            || String.isBlank(data.mp_reference)
            || String.isBlank(data.mp_amount)
            || String.isBlank(data.mp_response)) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | validateMinimumFields | Parámetros obligatorios faltantes');
            throw new AuraHandledException('La respuesta de Multipagos no contiene los campos obligatorios.');
        }
    }

    /**
     * ============================================================================
     * Método: getActiveConfiguration
     * ============================================================================
     * Propósito:
     * Leer el registro activo de CAZ_MultipagosConfiguration__mdt.
     * ============================================================================
     */
    private static CAZ_MultipagosConfiguration__mdt getActiveConfiguration() {
        List<CAZ_MultipagosConfiguration__mdt> configs = [
            SELECT DeveloperName,
                   CAZ_Environment__c,
                   CAZ_Active__c,
                   CAZ_ExpectedRefererHost__c
            FROM CAZ_MultipagosConfiguration__mdt
            WHERE CAZ_Active__c = true
            LIMIT 1
        ];

        if (configs.isEmpty()) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | getActiveConfiguration | No existe configuración activa');
            throw new AuraHandledException('No existe una configuración activa de Multipagos.');
        }

        return configs[0];
    }

    /**
     * ============================================================================
     * Método: getSecretKey
     * ============================================================================
     * Propósito:
     * Leer la llave privada HMAC SHA-256 del Custom Setting protegido.
     * ============================================================================
     */
    @TestVisible
    private static String getSecretKey() {
        CAZ_MultipagosSecrets__c secrets = CAZ_MultipagosSecrets__c.getOrgDefaults();
        if (secrets == null) {
            return null;
        }
        return secrets.CAZ_SecretKey__c;
    }

    /**
     * ============================================================================
     * Método: validateReferer
     * ============================================================================
     * Propósito:
     * Comparar el host del referer recibido contra el host esperado del CMT.
     *
     * Regla:
     * - Si el referer viene vacío (algunos navegadores lo omiten), NO se
     *   considera inválido de forma automática: se registra como warning y se
     *   devuelve false para que quede auditado.
     * - Si el expectedHost está vacío (config inválida), se registra warning
     *   y se retorna false.
     * - Se compara el host extraído en minúsculas.
     * ============================================================================
     */
    @TestVisible
    private static Boolean validateReferer(String pageReferer, String expectedHost) {
        if (String.isBlank(expectedHost)) {
            System.debug(LoggingLevel.WARN, LOG_PREFIX + ' | validateReferer | expectedHost no configurado en CMT');
            return false;
        }
        if (String.isBlank(pageReferer)) {
            System.debug(LoggingLevel.WARN, LOG_PREFIX + ' | validateReferer | Referer vacío');
            return false;
        }

        String host = extractHost(pageReferer);
        Boolean isValid = host != null && host.equalsIgnoreCase(expectedHost.trim());

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | validateReferer | host=' + host + ' | expected=' + expectedHost + ' | isValid=' + isValid);
        return isValid;
    }

    /**
     * ============================================================================
     * Método: extractHost
     * ============================================================================
     * Propósito:
     * Extraer el host (sin esquema, sin puerto, sin path) de un referer crudo.
     * Acepta valores como 'https://prepro.adquiracloud.mx/path' o
     * 'prepro.adquiracloud.mx'.
     * ============================================================================
     */
    private static String extractHost(String referer) {
        String value = referer.trim();

        Integer schemeIdx = value.indexOf('://');
        if (schemeIdx >= 0) {
            value = value.substring(schemeIdx + 3);
        }

        Integer slashIdx = value.indexOf('/');
        if (slashIdx >= 0) {
            value = value.substring(0, slashIdx);
        }

        Integer colonIdx = value.indexOf(':');
        if (colonIdx >= 0) {
            value = value.substring(0, colonIdx);
        }

        return String.isBlank(value) ? null : value.toLowerCase();
    }

    /**
     * ============================================================================
     * Método: parseAmount
     * ============================================================================
     * Propósito:
     * Convertir el string mp_amount recibido a Decimal para poder regenerar la
     * firma y comparar contra la recibida.
     * ============================================================================
     */
    private static Decimal parseAmount(String rawAmount) {
        try {
            return Decimal.valueOf(rawAmount.trim());
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | parseAmount | No se pudo convertir mp_amount=' + rawAmount);
            throw new AuraHandledException('El monto recibido de Multipagos es inválido.');
        }
    }

    /**
     * ============================================================================
     * Método: findPaymentByMultipagosOrder
     * ============================================================================
     * Propósito:
     * Localizar el Payment creado en la fase de preparación usando
     * CAZ_MultipagosOrder__c como clave natural.
     * ============================================================================
     */
    private static Payment findPaymentByMultipagosOrder(String multipagosOrder) {
        List<Payment> payments = [
            SELECT Id,
                   Amount,
                   CAZ_MultipagosOrder__c,
                   CAZ_TransactionStatus__c,
                   CAZ_ResponseCode__c,
                   CAZ_ResponseMessage__c,
                   CAZ_Authorization__c,
                   CAZ_ResponseSignature__c,
                   CAZ_SignatureValid__c,
                   CAZ_RefererValid__c
            FROM Payment
            WHERE CAZ_MultipagosOrder__c = :multipagosOrder
            LIMIT 1
        ];

        if (payments.isEmpty()) {
            return null;
        }
        return payments[0];
    }

    /**
     * ============================================================================
     * Método: determineTransactionStatus
     * ============================================================================
     * Propósito:
     * Aplicar la regla de negocio que deriva el estado final del Payment a
     * partir del código de respuesta, la validación de firma y la validación
     * de referer.
     *
     * Prioridad de reglas:
     * 1. Si mp_response == '00' y firma inválida → Signature_Invalid (posible fraude).
     * 2. Si mp_response == '00' y firma válida → Approved.
     *    (Referer inválido se registra pero no degrada una transacción aprobada
     *    con firma válida, porque algunos navegadores no envían referer.)
     * 3. Cualquier otro mp_response → Rejected.
     * ============================================================================
     */
    @TestVisible
    private static String determineTransactionStatus(
        String responseCode,
        Boolean signatureValid,
        Boolean refererValid
    ) {
        if (APPROVED_RESPONSE_CODE.equals(responseCode)) {
            if (!signatureValid) {
                return STATUS_SIGNATURE_INVALID;
            }
            return STATUS_APPROVED;
        }
        return STATUS_REJECTED;
    }

    /**
     * ============================================================================
     * Método: updatePaymentWithResponse
     * ============================================================================
     * Propósito:
     * Persistir en el Payment los datos de respuesta, el estado final y los
     * flags de validación.
     * ============================================================================
     */
    private static void updatePaymentWithResponse(
        Payment paymentRecord,
        MultipagosResponseData data,
        String finalStatus,
        Boolean signatureValid,
        Boolean refererValid
    ) {
        paymentRecord.CAZ_ResponseCode__c      = data.mp_response;
        paymentRecord.CAZ_ResponseMessage__c   = truncate(data.mp_responsemsg, 255);
        paymentRecord.CAZ_Authorization__c     = truncate(data.mp_authorization, 50);
        paymentRecord.CAZ_ResponseSignature__c = data.mp_signature;
        paymentRecord.CAZ_SignatureValid__c    = signatureValid;
        paymentRecord.CAZ_RefererValid__c      = refererValid;
        paymentRecord.CAZ_TransactionStatus__c = finalStatus;

        update paymentRecord;

        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | updatePaymentWithResponse | Payment actualizado: ' + paymentRecord.Id);
    }

    /**
     * ============================================================================
     * Método: truncate
     * ============================================================================
     * Propósito:
     * Recortar un String al máximo permitido por el campo destino.
     * ============================================================================
     */
    private static String truncate(String value, Integer maxLength) {
        if (value == null) {
            return null;
        }
        if (value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }

    /**
     * ============================================================================
     * Método: buildPaymentResult
     * ============================================================================
     * Propósito:
     * Ensamblar el DTO final que consumirá el LWC de retorno.
     * ============================================================================
     */
    private static PaymentResultData buildPaymentResult(
        Id paymentId,
        String finalStatus,
        String responseCode,
        String responseMessage,
        String authorization,
        Boolean signatureValid,
        Boolean refererValid,
        Boolean alreadyProcessed
    ) {
        PaymentResultData result = new PaymentResultData();
        result.paymentId         = paymentId;
        result.transactionStatus = finalStatus;
        result.responseCode      = responseCode;
        result.responseMessage   = responseMessage;
        result.authorization     = authorization;
        result.signatureValid    = signatureValid;
        result.refererValid      = refererValid;
        result.isApproved        = STATUS_APPROVED.equals(finalStatus);
        result.alreadyProcessed  = alreadyProcessed;
        return result;
    }

    /**
     * ============================================================================
     * Método: buildErrorResult
     * ============================================================================
     * Propósito:
     * Construir el DTO cuando no se encuentra un Payment asociado a mp_order.
     * No hay registro que actualizar, pero el LWC necesita una respuesta.
     * ============================================================================
     */
    private static PaymentResultData buildErrorResult(
        MultipagosResponseData data,
        Boolean signatureValid,
        Boolean refererValid
    ) {
        return buildPaymentResult(
            null,
            STATUS_ERROR,
            data.mp_response,
            data.mp_responsemsg,
            data.mp_authorization,
            signatureValid,
            refererValid,
            false
        );
    }

    /**
     * ============================================================================
     * Método: buildAlreadyProcessedResult
     * ============================================================================
     * Propósito:
     * Construir el DTO cuando el Payment ya fue procesado previamente. Se
     * devuelve el estado persistido sin reescribir el registro.
     * ============================================================================
     */
    private static PaymentResultData buildAlreadyProcessedResult(Payment paymentRecord) {
        return buildPaymentResult(
            paymentRecord.Id,
            paymentRecord.CAZ_TransactionStatus__c,
            paymentRecord.CAZ_ResponseCode__c,
            paymentRecord.CAZ_ResponseMessage__c,
            paymentRecord.CAZ_Authorization__c,
            paymentRecord.CAZ_SignatureValid__c,
            paymentRecord.CAZ_RefererValid__c,
            true
        );
    }
}