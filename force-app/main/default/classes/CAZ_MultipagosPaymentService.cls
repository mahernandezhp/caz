public with sharing class CAZ_MultipagosPaymentService {

    /**
     * ============================================================================
     * Clase: CAZ_MultipagosPaymentService
     * ============================================================================
     * Propósito:
     * Preparar una transacción de pago para Multipagos a partir de una Order.
     *
     * Responsabilidades:
     * - Leer la configuración activa de Multipagos.
     * - Obtener la Order a pagar.
     * - Obtener o crear el PaymentGroup relacionado con la Order.
     * - Crear el Payment inicial en Salesforce.
     * - Generar los valores mp_order, mp_reference, mp_amount y mp_signature.
     * - Devolver un DTO con todos los parámetros necesarios para construir el POST.
     *
     * Alcance:
     * - NO realiza el POST a Multipagos.
     * - NO procesa el retorno del gateway.
     * - NO valida la respuesta de Multipagos.
     *
     * Supuestos:
     * - Existe un registro activo en CAZ_MultipagosConfiguration__mdt.
     * - PaymentGroup usa SourceObjectId para relacionarse con Order.
     * - PaymentGateway se localiza por ExternalReference con el patrón:
     *   'MULTIPAGOS_' + Environment
     *   Ejemplo: MULTIPAGOS_PREPROD
     *
     * Nota importante:
     * - La secretKey se recibe como parámetro porque aún no se ha definido
     *   en qué repositorio seguro se almacenará.
     * ============================================================================
     */

    private static final String LOG_PREFIX = 'CAZ_MultipagosPaymentService';

    /**
     * ============================================================================
     * DTO: PaymentRequestData
     * ============================================================================
     * Propósito:
     * Transportar todos los datos necesarios para construir el formulario POST
     * hacia Multipagos y conservar identificadores de los registros creados.
     * ============================================================================
     */
    public class PaymentRequestData {
        @AuraEnabled public Id paymentId;
        @AuraEnabled public Id paymentGroupId;
        @AuraEnabled public Id paymentGatewayId;

        @AuraEnabled public String environment;
        @AuraEnabled public Boolean simulationMode;

        @AuraEnabled public String multipagosEndpoint;
        @AuraEnabled public String mp_account;
        @AuraEnabled public String mp_product;
        @AuraEnabled public String mp_order;
        @AuraEnabled public String mp_reference;
        @AuraEnabled public String mp_node;
        @AuraEnabled public String mp_concept;
        @AuraEnabled public String mp_amount;
        @AuraEnabled public String mp_currency;
        @AuraEnabled public String mp_signature;
        @AuraEnabled public String mp_urlsuccess;
        @AuraEnabled public String mp_urlfailure;
    }

    /**
     * ============================================================================
     * Método: preparePayment
     * ============================================================================
     * Propósito:
     * Preparar toda la información necesaria para iniciar una transacción
     * hacia Multipagos a partir de una Order.
     *
     * Flujo:
     * 1. Leer configuración activa.
     * 2. Consultar la Order.
     * 3. Obtener o crear el PaymentGroup.
     * 4. Localizar el PaymentGateway.
     * 5. Construir mp_order, mp_reference y mp_amount.
     * 6. Generar mp_signature.
     * 7. Crear el Payment.
     * 8. Regresar el DTO con los parámetros del POST.
     *
     * Parámetros:
     * @param orderId   Id de la Order a pagar.
     * @param secretKey Llave secreta para generar la firma HMAC SHA-256.
     *
     * Retorno:
     * @return PaymentRequestData con los datos necesarios para el POST.
     * ============================================================================
     */
    @AuraEnabled
    public static PaymentRequestData preparePayment(Id orderId) {
        String secretKey = '';
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | preparePayment | Inicio');
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | preparePayment | orderId=' + orderId);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | preparePayment | secretKeyProvided=' + !String.isBlank(secretKey));

        if (orderId == null) {
            throw new AuraHandledException('El orderId es obligatorio.');
        }
        if (String.isBlank(secretKey)) {
            throw new AuraHandledException('La secretKey es obligatoria para preparar el pago.');
        }

        CAZ_MultipagosConfiguration__mdt config = getActiveConfiguration();
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | preparePayment | Configuración activa encontrada: ' + config.DeveloperName);

        Order ord = getOrder(orderId);
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | preparePayment | Order encontrada: ' + ord.Id);

        PaymentGroup paymentGroup = getOrCreatePaymentGroup(ord.Id);
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | preparePayment | PaymentGroup listo: ' + paymentGroup.Id);

        PaymentGateway paymentGateway = getPaymentGateway(config.CAZ_Environment__c);
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | preparePayment | PaymentGateway encontrado: ' + paymentGateway.Id);

        String multipagosOrder = buildMultipagosOrder(ord);
        String multipagosReference = buildMultipagosReference(ord, config.CAZ_ReferencePrefix__c);
        Decimal amount = buildAmount(ord);
        String normalizedAmount = normalizeAmount(amount);

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | preparePayment | multipagosOrder=' + multipagosOrder);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | preparePayment | multipagosReference=' + multipagosReference);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | preparePayment | amount=' + amount);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | preparePayment | normalizedAmount=' + normalizedAmount);

        String requestSignature = CAZ_MultipagosSignatureService.generateRequestSignature(
            multipagosOrder,
            multipagosReference,
            amount,
            secretKey
        );

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | preparePayment | requestSignature=' + requestSignature);

        Payment paymentRecord = createPayment(
            ord,
            paymentGroup,
            paymentGateway,
            config,
            multipagosOrder,
            multipagosReference,
            amount,
            requestSignature
        );

        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | preparePayment | Payment creado: ' + paymentRecord.Id);

        PaymentRequestData dto = new PaymentRequestData();
        dto.paymentId = paymentRecord.Id;
        dto.paymentGroupId = paymentGroup.Id;
        dto.paymentGatewayId = paymentGateway.Id;

        dto.environment = config.CAZ_Environment__c;
        dto.simulationMode = config.CAZ_SimulationMode__c;

        dto.multipagosEndpoint = config.CAZ_MultipagosEndpoint__c;
        dto.mp_account = config.CAZ_Account__c;
        dto.mp_product = config.CAZ_Product__c;
        dto.mp_order = multipagosOrder;
        dto.mp_reference = multipagosReference;
        dto.mp_node = config.CAZ_Node__c;
        dto.mp_concept = config.CAZ_Concept__c;
        dto.mp_amount = normalizedAmount;
        dto.mp_currency = config.CAZ_Currency__c;
        dto.mp_signature = requestSignature;
        dto.mp_urlsuccess = config.CAZ_SuccessUrl__c;
        dto.mp_urlfailure = config.CAZ_FailureUrl__c;

        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | preparePayment | DTO preparado correctamente');
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | preparePayment | DTO=' + JSON.serialize(dto));

        return dto;
    }

    /**
     * ============================================================================
     * Método: getActiveConfiguration
     * ============================================================================
     * Propósito:
     * Obtener el registro activo de configuración de Multipagos.
     * ============================================================================
     */
    private static CAZ_MultipagosConfiguration__mdt getActiveConfiguration() {
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | getActiveConfiguration | Buscando configuración activa');

        List<CAZ_MultipagosConfiguration__mdt> configs = [
            SELECT DeveloperName,
                   CAZ_Environment__c,
                   CAZ_Active__c,
                   CAZ_MultipagosEndpoint__c,
                   CAZ_Account__c,
                   CAZ_Product__c,
                   CAZ_Node__c,
                   CAZ_Concept__c,
                   CAZ_Currency__c,
                   CAZ_SuccessUrl__c,
                   CAZ_FailureUrl__c,
                   CAZ_ExpectedRefererHost__c,
                   CAZ_SimulationMode__c,
                   CAZ_ReferencePrefix__c,
                   CAZ_MerchantName__c
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
     * Método: getOrder
     * ============================================================================
     * Propósito:
     * Consultar la Order base para preparar el pago.
     *
     * Nota:
     * Se usa TotalAmount como monto del pago. Si en tu org el monto real viene
     * de otro campo, aquí es donde debes ajustarlo.
     * ============================================================================
     */
    private static Order getOrder(Id orderId) {
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | getOrder | Consultando Order');

        List<Order> orders = [
            SELECT Id, OrderNumber, AccountId, TotalAmount
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];

        if (orders.isEmpty()) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | getOrder | Order no encontrada');
            throw new AuraHandledException('No se encontró la Order indicada.');
        }

        return orders[0];
    }

    /**
     * ============================================================================
     * Método: getOrCreatePaymentGroup
     * ============================================================================
     * Propósito:
     * Obtener el PaymentGroup asociado a la Order o crearlo si no existe.
     * ============================================================================
     */
    private static PaymentGroup getOrCreatePaymentGroup(Id orderId) {
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | getOrCreatePaymentGroup | orderId=' + orderId);

        List<PaymentGroup> groups = [
            SELECT Id, SourceObjectId
            FROM PaymentGroup
            WHERE SourceObjectId = :orderId
            LIMIT 1
        ];

        if (!groups.isEmpty()) {
            System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | getOrCreatePaymentGroup | PaymentGroup existente encontrado');
            return groups[0];
        }

        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | getOrCreatePaymentGroup | No existe PaymentGroup, se creará uno nuevo');

        PaymentGroup newGroup = new PaymentGroup();
        newGroup.SourceObjectId = orderId;
        insert newGroup;

        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | getOrCreatePaymentGroup | PaymentGroup creado: ' + newGroup.Id);

        return newGroup;
    }

    /**
     * ============================================================================
     * Método: getPaymentGateway
     * ============================================================================
     * Propósito:
     * Obtener el PaymentGateway correspondiente al ambiente activo.
     *
     * Regla:
     * Busca por ExternalReference usando el patrón:
     * MULTIPAGOS_<ENVIRONMENT>
     *
     * Ejemplo:
     * MULTIPAGOS_PREPROD
     * ============================================================================
     */
    private static PaymentGateway getPaymentGateway(String environment) {
        String gatewayReference = 'MULTIPAGOS_' + environment;
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | getPaymentGateway | gatewayReference=' + gatewayReference);

        List<PaymentGateway> gateways = [
            SELECT Id,
                   PaymentGatewayName,
                   ExternalReference,
                   Status,
                   MerchantCredentialId,
                   PaymentGatewayProviderId,
                   Comments
            FROM PaymentGateway
            WHERE ExternalReference = :gatewayReference
            LIMIT 1
        ];

        if (gateways.isEmpty()) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | getPaymentGateway | No se encontró PaymentGateway para ' + gatewayReference);
            throw new AuraHandledException(
                'No se encontró un PaymentGateway con ExternalReference = ' + gatewayReference
            );
        }

        return gateways[0];
    }

    /**
     * ============================================================================
     * Método: buildMultipagosOrder
     * ============================================================================
     * Propósito:
     * Construir el valor de mp_order.
     *
     * Estrategia:
     * Usa OrderNumber y elimina espacios. Si no existe, usa una versión derivada
     * del Id de la Order.
     * ============================================================================
     */
    private static String buildMultipagosOrder(Order ord) {
        String baseValue;

        if (!String.isBlank(ord.OrderNumber)) {
            baseValue = ord.OrderNumber.replaceAll('[^a-zA-Z0-9]', '');
        } else {
            baseValue = String.valueOf(ord.Id).replaceAll('[^a-zA-Z0-9]', '');
        }

        if (String.isBlank(baseValue)) {
            throw new AuraHandledException('No fue posible construir mp_order.');
        }

        String result = baseValue.length() > 30 ? baseValue.substring(0, 30) : baseValue;

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | buildMultipagosOrder | result=' + result);

        return result;
    }

    /**
     * ============================================================================
     * Método: buildMultipagosReference
     * ============================================================================
     * Propósito:
     * Construir el valor de mp_reference.
     *
     * Estrategia:
     * Combina prefijo + OrderNumber/Id + timestamp corto para volverlo único.
     * ============================================================================
     */
    private static String buildMultipagosReference(Order ord, String prefix) {
        String safePrefix = String.isBlank(prefix) ? 'CAZ' : prefix.replaceAll('[^a-zA-Z0-9]', '');
        String baseOrder = !String.isBlank(ord.OrderNumber)
            ? ord.OrderNumber.replaceAll('[^a-zA-Z0-9]', '')
            : String.valueOf(ord.Id).replaceAll('[^a-zA-Z0-9]', '');

        String timePart = String.valueOf(DateTime.now().getTime());
        String raw = safePrefix + baseOrder + timePart;
        String result = raw.length() > 50 ? raw.substring(0, 50) : raw;

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | buildMultipagosReference | result=' + result);

        return result;
    }

    /**
     * ============================================================================
     * Método: buildAmount
     * ============================================================================
     * Propósito:
     * Obtener el monto que se enviará a Multipagos.
     *
     * Nota:
     * Actualmente usa Order.TotalAmount.
     * Si tu modelo real usa otro campo, aquí debe ajustarse.
     * ============================================================================
     */
    private static Decimal buildAmount(Order ord) {
        if (ord.TotalAmount == null || ord.TotalAmount <= 0) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | buildAmount | TotalAmount inválido: ' + ord.TotalAmount);
            throw new AuraHandledException('La Order no tiene un monto válido para pago.');
        }

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | buildAmount | amount=' + ord.TotalAmount);

        return ord.TotalAmount;
    }

    /**
     * ============================================================================
     * Método: normalizeAmount
     * ============================================================================
     * Propósito:
     * Normalizar el monto al formato de dos decimales requerido por Multipagos.
     * ============================================================================
     */
    private static String normalizeAmount(Decimal amount) {
        Decimal scaled = amount.setScale(2);
        String normalized = String.valueOf(scaled);

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | normalizeAmount | original=' + amount + ' | normalized=' + normalized);

        return normalized;
    }

    /**
     * ============================================================================
     * Método: createPayment
     * ============================================================================
     * Propósito:
     * Crear el registro Payment inicial en Salesforce con la información
     * transaccional necesaria para la fase de preparación del pago.
     * ============================================================================
     */
    private static Payment createPayment(
        Order ord,
        PaymentGroup paymentGroup,
        PaymentGateway paymentGateway,
        CAZ_MultipagosConfiguration__mdt config,
        String multipagosOrder,
        String multipagosReference,
        Decimal amount,
        String requestSignature
    ) {
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | createPayment | Creando Payment');

        Payment paymentRecord = new Payment();
        paymentRecord.Amount = amount;
        paymentRecord.Date = System.now();
        paymentRecord.AccountId = ord.AccountId;
        paymentRecord.PaymentGatewayId = paymentGateway.Id;
        paymentRecord.PaymentGroupId = paymentGroup.Id;
        paymentRecord.GatewayRefNumber = multipagosReference;
        paymentRecord.GatewayRefDetails = 'mp_order=' + multipagosOrder;
        paymentRecord.Comments = 'Pago preparado para envío a Multipagos';

        paymentRecord.CAZ_Environment__c = config.CAZ_Environment__c;
        paymentRecord.CAZ_SimulationMode__c = config.CAZ_SimulationMode__c;
        paymentRecord.CAZ_MultipagosOrder__c = multipagosOrder;
        paymentRecord.CAZ_RequestSignature__c = requestSignature;
        paymentRecord.CAZ_SignatureValid__c = false;
        paymentRecord.CAZ_RefererValid__c = false;

        insert paymentRecord;

        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | createPayment | Payment insertado correctamente');
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | createPayment | paymentId=' + paymentRecord.Id);

        return paymentRecord;
    }
}