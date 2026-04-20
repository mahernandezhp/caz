@IsTest
private class CAZ_MultipagosPaymentServiceTest {

    /**
     * ============================================================================
     * Clase: CAZ_MultipagosPaymentServiceTest
     * ============================================================================
     * Propósito:
     * Cubrir todas las ramas de CAZ_MultipagosPaymentService sin depender de
     * un PaymentGateway real en la org.
     *
     * Estrategia de test data:
     * - CMT CAZ_MultipagosConfiguration__mdt.PREPROD ya existe en sandbox y es
     *   leído por la clase bajo prueba (Custom Metadata records son visibles
     *   desde Apex Tests por defecto).
     * - CAZ_MultipagosSecrets__c se inserta vía Custom Setting org default
     *   en cada test (Custom Settings SÍ son insertables en @IsTest).
     * - PaymentGateway se inyecta vía seam @TestVisible mockGateway + flag
     *   bypassPaymentGatewayAssignment para evitar la dependencia de
     *   PaymentGatewayProvider + ApexAdapter + NamedCredential.
     * - Order con TotalAmount > 0 se construye con Product2 + PricebookEntry
     *   + OrderItem contra el Standard Pricebook (Test.getStandardPricebookId).
     *
     * Cobertura objetivo:
     * - preparePayment camino feliz (DTO completo).
     * - preparePayment con orderId null → AuraHandledException.
     * - preparePayment sin secretKey → AuraHandledException.
     * - preparePayment con Order inexistente → AuraHandledException.
     * - preparePayment con Order sin TotalAmount → AuraHandledException.
     * - buildMultipagosOrder: ramas con OrderNumber presente y ausente.
     * - buildMultipagosReference: default prefix, prefix largo, longitud <= 30.
     * - getOrCreatePaymentGroup: reutilización de PaymentGroup existente.
     * ============================================================================
     */

    private static final String TEST_SECRET = 'multipagos-flap-test-secret-2026';

    /**
     * Inserta el Custom Setting org default con la llave requerida por
     * preparePayment. Los tests que quieran ejercitar la rama "secret blank"
     * simplemente NO llaman a este helper.
     */
    private static void setupSecret(String secretKey) {
        CAZ_MultipagosSecrets__c secrets = new CAZ_MultipagosSecrets__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CAZ_SecretKey__c = secretKey
        );
        insert secrets;
    }

    /**
     * Inyecta un PaymentGateway sintético (JSON deserialization, Id sintético)
     * y activa el flag de bypass para que createPayment NO intente asignar
     * PaymentGatewayId al Payment insertable (el Id es falso y reventaría FK).
     */
    private static void setupMockGateway() {
        String fakeGatewayJson =
            '{"attributes":{"type":"PaymentGateway"},'
            + '"Id":"' + buildFakeId(Schema.PaymentGateway.SObjectType) + '",'
            + '"PaymentGatewayName":"Multipagos Test Gateway",'
            + '"ExternalReference":"MULTIPAGOS_PREPROD",'
            + '"Status":"Active"}';
        CAZ_MultipagosPaymentService.mockGateway =
            (PaymentGateway) JSON.deserialize(fakeGatewayJson, PaymentGateway.class);
        CAZ_MultipagosPaymentService.bypassPaymentGatewayAssignment = true;
    }

    /**
     * Genera un Id válido en formato (keyPrefix + 12 ceros + "001") para el
     * SObjectType indicado. Útil para inyectar registros sintéticos en memoria
     * sin tocar la base de datos.
     */
    private static Id buildFakeId(Schema.SObjectType sot) {
        String prefix = sot.getDescribe().getKeyPrefix();
        return Id.valueOf(prefix + '000000000001');
    }

    /**
     * Crea un Account + Product2 + PricebookEntry + Order + OrderItem con
     * TotalAmount calculado como Quantity * UnitPrice. Retorna el Order
     * reconsultado con TotalAmount y OrderNumber poblados por la plataforma.
     */
    private static Order createOrderWithTotal(Decimal unitPrice, Integer quantity) {
        Account acc = new Account(Name = 'Test CAZ Account', clavejde__c = '1000001');
        insert acc;

        Product2 prod = new Product2(Name = 'Test CAZ Product', IsActive = true);
        insert prod;

        Id standardPbId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id   = prod.Id,
            UnitPrice    = unitPrice,
            IsActive     = true
        );
        insert pbe;

        Order ord = new Order(
            AccountId     = acc.Id,
            EffectiveDate = Date.today(),
            Status        = 'Draft',
            Pricebook2Id  = standardPbId
        );
        insert ord;

        OrderItem oi = new OrderItem(
            OrderId          = ord.Id,
            Quantity         = quantity,
            UnitPrice        = unitPrice,
            PricebookEntryId = pbe.Id
        );
        insert oi;

        return [
            SELECT Id, OrderNumber, AccountId, TotalAmount
            FROM Order
            WHERE Id = :ord.Id
            LIMIT 1
        ];
    }

    /**
     * Order sin OrderItems: TotalAmount queda en 0 y preparePayment debe
     * rechazarlo con AuraHandledException.
     */
    private static Order createOrderWithoutItems() {
        Account acc = new Account(Name = 'Test CAZ Account Empty', clavejde__c = '1000002');
        insert acc;

        Order ord = new Order(
            AccountId     = acc.Id,
            EffectiveDate = Date.today(),
            Status        = 'Draft',
            Pricebook2Id  = Test.getStandardPricebookId()
        );
        insert ord;

        return [
            SELECT Id, OrderNumber, AccountId, TotalAmount
            FROM Order
            WHERE Id = :ord.Id
            LIMIT 1
        ];
    }

    @IsTest
    static void preparePayment_happyPath_returnsCompleteDto() {
        setupSecret(TEST_SECRET);
        setupMockGateway();
        Order ord = createOrderWithTotal(150.00, 2);

        Test.startTest();
        CAZ_MultipagosPaymentService.PaymentRequestData dto =
            CAZ_MultipagosPaymentService.preparePayment(ord.Id);
        Test.stopTest();

        System.assertNotEquals(null, dto, 'El DTO no debe ser null');
        System.assertNotEquals(null, dto.paymentId, 'paymentId debe estar poblado');
        System.assertNotEquals(null, dto.paymentGroupId, 'paymentGroupId debe estar poblado');
        System.assertNotEquals(null, dto.paymentGatewayId, 'paymentGatewayId debe venir del mock');
        System.assertEquals('PREPROD', dto.environment);
        System.assertEquals('https://prepro.adquiracloud.mx', dto.multipagosEndpoint);
        System.assertEquals('12780', dto.mp_account);
        System.assertNotEquals(null, dto.mp_order);
        System.assert(!String.isBlank(dto.mp_reference));
        System.assert(dto.mp_reference.length() <= 30,
            'mp_reference debe respetar el límite de 30 chars de Multipagos. Got: ' + dto.mp_reference);
        System.assertEquals('300.00', dto.mp_amount,
            '2 * 150.00 = 300.00 con normalización a 2 decimales');
        System.assertNotEquals(null, dto.mp_signature);
        System.assertEquals(64, dto.mp_signature.length(), 'Firma hex SHA-256 = 64 chars');

        // Verifica que el Payment se creó en DB con los campos CAZ_* correctos.
        Payment persisted = [
            SELECT Id, Amount, AccountId, CAZ_Environment__c, CAZ_MultipagosOrder__c,
                   CAZ_RequestSignature__c, CAZ_SignatureValid__c, CAZ_RefererValid__c
            FROM Payment
            WHERE Id = :dto.paymentId
            LIMIT 1
        ];
        System.assertEquals(300.00, persisted.Amount);
        System.assertEquals(ord.AccountId, persisted.AccountId);
        System.assertEquals('PREPROD', persisted.CAZ_Environment__c);
        System.assertEquals(dto.mp_order, persisted.CAZ_MultipagosOrder__c);
        System.assertEquals(dto.mp_signature, persisted.CAZ_RequestSignature__c);
        System.assertEquals(false, persisted.CAZ_SignatureValid__c,
            'SignatureValid inicia en false; se actualiza en el ResponseHandler');
        System.assertEquals(false, persisted.CAZ_RefererValid__c);
    }

    @IsTest
    static void preparePayment_reusesExistingPaymentGroup() {
        setupSecret(TEST_SECRET);
        setupMockGateway();
        Order ord = createOrderWithTotal(100.00, 1);

        // Pre-crea un PaymentGroup para la Order: el servicio debe reutilizarlo.
        PaymentGroup preExisting = new PaymentGroup(SourceObjectId = ord.Id);
        insert preExisting;

        Test.startTest();
        CAZ_MultipagosPaymentService.PaymentRequestData dto =
            CAZ_MultipagosPaymentService.preparePayment(ord.Id);
        Test.stopTest();

        System.assertEquals(preExisting.Id, dto.paymentGroupId,
            'Debe reutilizar el PaymentGroup existente en lugar de crear otro');

        Integer totalGroups = [
            SELECT COUNT() FROM PaymentGroup WHERE SourceObjectId = :ord.Id
        ];
        System.assertEquals(1, totalGroups, 'Solo debe existir 1 PaymentGroup para la Order');
    }

    @IsTest
    static void preparePayment_nullOrderId_throws() {
        setupSecret(TEST_SECRET);
        setupMockGateway();

        Boolean thrown = false;
        try {
            CAZ_MultipagosPaymentService.preparePayment(null);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown, 'orderId null debe lanzar AuraHandledException');
    }

    @IsTest
    static void preparePayment_blankSecret_throws() {
        // No insertamos el Custom Setting → getSecretKey() retorna null.
        setupMockGateway();
        Order ord = createOrderWithTotal(100.00, 1);

        Boolean thrown = false;
        try {
            CAZ_MultipagosPaymentService.preparePayment(ord.Id);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown, 'SecretKey blank debe lanzar AuraHandledException');
    }

    @IsTest
    static void preparePayment_orderNotFound_throws() {
        setupSecret(TEST_SECRET);
        setupMockGateway();

        // Id sintético de Order que no existe en DB.
        Id fakeOrderId = buildFakeId(Schema.Order.SObjectType);

        Boolean thrown = false;
        try {
            CAZ_MultipagosPaymentService.preparePayment(fakeOrderId);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown, 'Order inexistente debe lanzar AuraHandledException');
    }

    @IsTest
    static void preparePayment_orderWithoutTotalAmount_throws() {
        setupSecret(TEST_SECRET);
        setupMockGateway();
        Order ord = createOrderWithoutItems();

        Boolean thrown = false;
        try {
            CAZ_MultipagosPaymentService.preparePayment(ord.Id);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown,
            'Order con TotalAmount = 0 debe lanzar AuraHandledException');
    }

    @IsTest
    static void getSecretKey_returnsConfiguredValue() {
        setupSecret('my-test-key');
        String key = CAZ_MultipagosPaymentService.getSecretKey();
        System.assertEquals('my-test-key', key);
    }

    @IsTest
    static void getSecretKey_withoutCustomSetting_returnsNullOrBlank() {
        // Sin insert: getOrgDefaults() retorna una instancia vacía con
        // CAZ_SecretKey__c = null.
        String key = CAZ_MultipagosPaymentService.getSecretKey();
        System.assert(String.isBlank(key), 'Sin org default, la llave debe ser null/blank');
    }

    /**
     * Construye un Order sintético en memoria poblando OrderNumber vía JSON
     * deserialization, porque OrderNumber es un campo auto-generado read-only
     * en Salesforce y no se puede asignar directamente con `new Order(...)`.
     */
    private static Order syntheticOrder(String orderNumber) {
        String fakeId = buildFakeId(Schema.Order.SObjectType);
        String payload = '{"attributes":{"type":"Order"},'
            + '"Id":"' + fakeId + '",'
            + (orderNumber == null ? '' : '"OrderNumber":"' + orderNumber + '",')
            + '"TotalAmount":100.00}';
        return (Order) JSON.deserialize(payload, Order.class);
    }

    @IsTest
    static void buildMultipagosOrder_withOrderNumber_stripsNonAlphanumeric() {
        // Construye una Order sintética en memoria para probar el método
        // utility directamente (sin DML).
        Order synthetic = syntheticOrder('SO-00123');
        String result = CAZ_MultipagosPaymentService.buildMultipagosOrder(synthetic);
        System.assertEquals('SO00123', result,
            'Debe remover caracteres no alfanuméricos del OrderNumber');
    }

    @IsTest
    static void buildMultipagosOrder_withoutOrderNumber_fallsBackToId() {
        Order synthetic = syntheticOrder(null);
        String result = CAZ_MultipagosPaymentService.buildMultipagosOrder(synthetic);
        System.assert(!String.isBlank(result), 'Debe derivar de Order.Id');
        System.assert(result.length() <= 30, 'Debe respetar límite de 30 chars');
    }

    @IsTest
    static void buildMultipagosReference_defaultsToCAZ_andRespects30Chars() {
        Order synthetic = syntheticOrder('SO-00000099');

        String withNullPrefix = CAZ_MultipagosPaymentService.buildMultipagosReference(synthetic, null);
        System.assert(!String.isBlank(withNullPrefix));
        System.assert(withNullPrefix.length() <= 30,
            'Longitud máxima 30. Got: ' + withNullPrefix.length());
        System.assert(withNullPrefix.startsWith('CAZ'),
            'Prefix null debe defaultear a CAZ. Got: ' + withNullPrefix);
    }

    @IsTest
    static void buildMultipagosReference_longPrefix_truncatedTo3Chars() {
        Order synthetic = syntheticOrder('SO001');

        String result = CAZ_MultipagosPaymentService.buildMultipagosReference(synthetic, 'PREFIXLONG');
        System.assert(result.startsWith('PRE'),
            'Prefix > 3 chars debe truncarse a 3. Got: ' + result);
        System.assert(result.length() <= 30);
    }

    @IsTest
    static void buildMultipagosReference_emptyPrefixAfterSanitize_fallsBackToCAZ() {
        Order synthetic = syntheticOrder('SO001');

        // Un prefix compuesto solo por caracteres no alfanuméricos queda vacío
        // tras el replaceAll → debe defaultear a 'CAZ'.
        String result = CAZ_MultipagosPaymentService.buildMultipagosReference(synthetic, '###');
        System.assert(result.startsWith('CAZ'),
            'Prefix inválido tras sanitize debe caer a CAZ. Got: ' + result);
    }
}