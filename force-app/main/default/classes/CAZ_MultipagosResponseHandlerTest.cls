@IsTest
private class CAZ_MultipagosResponseHandlerTest {

    /**
     * ============================================================================
     * Clase: CAZ_MultipagosResponseHandlerTest
     * ============================================================================
     * Propósito:
     * Cubrir todas las ramas de CAZ_MultipagosResponseHandler.processResponse
     * más los @TestVisible validateReferer y determineTransactionStatus.
     *
     * Test data:
     * - CMT CAZ_MultipagosConfiguration__mdt.PREPROD existe en sandbox con
     *   CAZ_ExpectedRefererHost__c = 'prepro.adquiracloud.mx'.
     * - CAZ_MultipagosSecrets__c se inserta por test (Custom Setting).
     * - Account + Order + PaymentGroup + Payment se insertan directamente con
     *   CAZ_MultipagosOrder__c y CAZ_TransactionStatus__c = 'Pending'.
     * - La firma de response se calcula en el propio test invocando al
     *   SignatureService, de modo que el DTO enviado al handler viene con
     *   un mp_signature que el handler valida positivamente.
     *
     * Cobertura objetivo:
     * - processResponse camino aprobado (mp_response=00 + firma válida + referer válido).
     * - processResponse rechazado (mp_response distinto de 00).
     * - processResponse firma inválida (mp_response=00 pero sig distinta).
     * - processResponse referer inválido (host incorrecto) pero firma OK: Approved.
     * - processResponse referer en blanco: flag false pero no degrada estado.
     * - processResponse Payment no encontrado: Error + paymentId null.
     * - processResponse Payment ya procesado: alreadyProcessed=true, sin update.
     * - processResponse con JSON blank → throws.
     * - processResponse con JSON mal formado → throws.
     * - processResponse con campos mínimos faltantes → throws.
     * - processResponse con mp_amount inválido → throws.
     * - processResponse sin secretKey → throws.
     * - validateReferer: ramas blank-expected, blank-referer, host match, host mismatch.
     * - determineTransactionStatus: ramas approved, signature invalid, rejected.
     * ============================================================================
     */

    private static final String TEST_SECRET   = 'multipagos-flap-test-secret-2026';
    private static final String MP_ORDER      = 'TESTORDER001';
    private static final String MP_REFERENCE  = 'CAZTESTORDER0011234567890';
    private static final Decimal TEST_AMOUNT  = 250.00;
    private static final String MP_AUTH       = 'AUTH9988';
    private static final String EXPECTED_HOST = 'prepro.adquiracloud.mx';
    private static final String VALID_REFERER = 'https://prepro.adquiracloud.mx/mp/return';

    /**
     * Inserta el Custom Setting con la llave esperada por el handler.
     */
    private static void setupSecret(String key) {
        insert new CAZ_MultipagosSecrets__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CAZ_SecretKey__c = key
        );
    }

    /**
     * Inserta Account + Order + PaymentGroup + Payment con
     * CAZ_MultipagosOrder__c = MP_ORDER y CAZ_TransactionStatus__c = 'Pending'.
     * Retorna el Id del Payment insertado para que los tests puedan reconsultar.
     */
    private static Id setupPendingPayment() {
        Account acc = new Account(Name = 'Test CAZ Account RH', clavejde__c = '2000001');
        insert acc;

        Order ord = new Order(
            AccountId     = acc.Id,
            EffectiveDate = Date.today(),
            Status        = 'Draft',
            Pricebook2Id  = Test.getStandardPricebookId()
        );
        insert ord;

        PaymentGroup pg = new PaymentGroup(SourceObjectId = ord.Id);
        insert pg;

        Payment payment = new Payment(
            Status                    = 'Pending',
            Type                      = 'Sale',
            ProcessingMode            = 'External',
            Amount                    = TEST_AMOUNT,
            Date                      = System.now(),
            AccountId                 = acc.Id,
            PaymentGroupId            = pg.Id,
            CAZ_Environment__c        = 'PREPROD',
            CAZ_MultipagosOrder__c    = MP_ORDER,
            CAZ_TransactionStatus__c  = 'Pending',
            CAZ_SignatureValid__c     = false,
            CAZ_RefererValid__c       = false
        );
        insert payment;

        return payment.Id;
    }

    /**
     * Construye el JSON que el LWC enviaría a processResponse. La firma se
     * calcula aquí mismo vía el SignatureService para que el handler la
     * valide como correcta. Si el test necesita una firma inválida, puede
     * sustituir el valor después de llamar a este helper.
     */
    private static String buildResponseJson(
        String mpOrder,
        String mpReference,
        String mpAmount,
        String mpResponse,
        String mpResponseMsg,
        String mpAuthorization,
        String mpSignature
    ) {
        Map<String, String> payload = new Map<String, String>{
            'mp_order'         => mpOrder,
            'mp_reference'     => mpReference,
            'mp_amount'        => mpAmount,
            'mp_response'      => mpResponse,
            'mp_responsemsg'   => mpResponseMsg,
            'mp_authorization' => mpAuthorization,
            'mp_signature'     => mpSignature
        };
        return JSON.serialize(payload);
    }

    /**
     * Calcula la firma esperada para el happy path.
     */
    private static String computeValidSignature() {
        return CAZ_MultipagosSignatureService.generateResponseSignature(
            MP_ORDER, MP_REFERENCE, TEST_AMOUNT, MP_AUTH, TEST_SECRET
        );
    }

    @IsTest
    static void processResponse_approvedPath_updatesPaymentAndReturnsApproved() {
        setupSecret(TEST_SECRET);
        Id paymentId = setupPendingPayment();
        String validSig = computeValidSignature();
        String json = buildResponseJson(
            MP_ORDER, MP_REFERENCE, '250.00',
            '00', 'Aprobada', MP_AUTH, validSig
        );

        Test.startTest();
        CAZ_MultipagosResponseHandler.PaymentResultData result =
            CAZ_MultipagosResponseHandler.processResponse(json, VALID_REFERER);
        Test.stopTest();

        System.assertEquals(paymentId, result.paymentId);
        System.assertEquals('Approved', result.transactionStatus);
        System.assertEquals('00', result.responseCode);
        System.assertEquals('Aprobada', result.responseMessage);
        System.assertEquals(MP_AUTH, result.authorization);
        System.assertEquals(true, result.signatureValid);
        System.assertEquals(true, result.refererValid);
        System.assertEquals(true, result.isApproved);
        System.assertEquals(false, result.alreadyProcessed);

        Payment persisted = [
            SELECT CAZ_TransactionStatus__c, CAZ_ResponseCode__c, CAZ_Authorization__c,
                   CAZ_SignatureValid__c, CAZ_RefererValid__c, CAZ_ResponseSignature__c
            FROM Payment
            WHERE Id = :paymentId
        ];
        System.assertEquals('Approved', persisted.CAZ_TransactionStatus__c);
        System.assertEquals('00', persisted.CAZ_ResponseCode__c);
        System.assertEquals(MP_AUTH, persisted.CAZ_Authorization__c);
        System.assertEquals(true, persisted.CAZ_SignatureValid__c);
        System.assertEquals(true, persisted.CAZ_RefererValid__c);
        System.assertEquals(validSig, persisted.CAZ_ResponseSignature__c);
    }

    @IsTest
    static void processResponse_rejectedResponse_marksAsRejected() {
        setupSecret(TEST_SECRET);
        Id paymentId = setupPendingPayment();
        // Firma calculada sobre los mismos datos (válida), pero mp_response != '00'.
        String validSig = computeValidSignature();
        String json = buildResponseJson(
            MP_ORDER, MP_REFERENCE, '250.00',
            '54', 'Tarjeta expirada', MP_AUTH, validSig
        );

        Test.startTest();
        CAZ_MultipagosResponseHandler.PaymentResultData result =
            CAZ_MultipagosResponseHandler.processResponse(json, VALID_REFERER);
        Test.stopTest();

        System.assertEquals('Rejected', result.transactionStatus);
        System.assertEquals(false, result.isApproved);
        System.assertEquals(true, result.signatureValid,
            'La firma sigue siendo válida; solo el mp_response es de rechazo');

        Payment persisted = [
            SELECT CAZ_TransactionStatus__c, CAZ_ResponseCode__c
            FROM Payment WHERE Id = :paymentId
        ];
        System.assertEquals('Rejected', persisted.CAZ_TransactionStatus__c);
        System.assertEquals('54', persisted.CAZ_ResponseCode__c);
    }

    @IsTest
    static void processResponse_invalidSignatureButApprovedCode_marksAsSignatureInvalid() {
        setupSecret(TEST_SECRET);
        Id paymentId = setupPendingPayment();

        // Firma arbitraria que NO corresponde al payload.
        String fakeSig = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef';
        String json = buildResponseJson(
            MP_ORDER, MP_REFERENCE, '250.00',
            '00', 'Aprobada', MP_AUTH, fakeSig
        );

        Test.startTest();
        CAZ_MultipagosResponseHandler.PaymentResultData result =
            CAZ_MultipagosResponseHandler.processResponse(json, VALID_REFERER);
        Test.stopTest();

        System.assertEquals('Signature_Invalid', result.transactionStatus,
            'mp_response=00 con firma inválida debe marcar como Signature_Invalid');
        System.assertEquals(false, result.signatureValid);
        System.assertEquals(false, result.isApproved);

        Payment persisted = [
            SELECT CAZ_TransactionStatus__c, CAZ_SignatureValid__c
            FROM Payment WHERE Id = :paymentId
        ];
        System.assertEquals('Signature_Invalid', persisted.CAZ_TransactionStatus__c);
        System.assertEquals(false, persisted.CAZ_SignatureValid__c);
    }

    @IsTest
    static void processResponse_invalidReferer_stillApprovedIfSignatureValid() {
        setupSecret(TEST_SECRET);
        setupPendingPayment();
        String validSig = computeValidSignature();
        String json = buildResponseJson(
            MP_ORDER, MP_REFERENCE, '250.00',
            '00', 'Aprobada', MP_AUTH, validSig
        );

        Test.startTest();
        // Referer de un host distinto al CMT expected.
        CAZ_MultipagosResponseHandler.PaymentResultData result =
            CAZ_MultipagosResponseHandler.processResponse(json, 'https://evil.example.com/bad');
        Test.stopTest();

        System.assertEquals('Approved', result.transactionStatus,
            'Regla documentada: referer inválido se audita pero no degrada Approved con firma válida');
        System.assertEquals(false, result.refererValid);
        System.assertEquals(true, result.signatureValid);
    }

    @IsTest
    static void processResponse_blankReferer_flagFalseButProcessesNormally() {
        setupSecret(TEST_SECRET);
        setupPendingPayment();
        String validSig = computeValidSignature();
        String json = buildResponseJson(
            MP_ORDER, MP_REFERENCE, '250.00',
            '00', 'Aprobada', MP_AUTH, validSig
        );

        Test.startTest();
        CAZ_MultipagosResponseHandler.PaymentResultData result =
            CAZ_MultipagosResponseHandler.processResponse(json, '');
        Test.stopTest();

        System.assertEquals('Approved', result.transactionStatus);
        System.assertEquals(false, result.refererValid,
            'Referer blank debe quedar en false pero no bloquear el flujo');
    }

    @IsTest
    static void processResponse_paymentNotFound_returnsErrorStatus() {
        setupSecret(TEST_SECRET);
        // NO insertamos ningún Payment con CAZ_MultipagosOrder__c = MP_ORDER.
        String validSig = computeValidSignature();
        String json = buildResponseJson(
            MP_ORDER, MP_REFERENCE, '250.00',
            '00', 'Aprobada', MP_AUTH, validSig
        );

        Test.startTest();
        CAZ_MultipagosResponseHandler.PaymentResultData result =
            CAZ_MultipagosResponseHandler.processResponse(json, VALID_REFERER);
        Test.stopTest();

        System.assertEquals('Error', result.transactionStatus);
        System.assertEquals(null, result.paymentId,
            'Sin Payment encontrado, paymentId del DTO debe ser null');
        System.assertEquals(false, result.isApproved);
    }

    @IsTest
    static void processResponse_alreadyProcessed_returnsExistingStateWithoutUpdate() {
        setupSecret(TEST_SECRET);
        Id paymentId = setupPendingPayment();

        // Marcamos el Payment como Approved para simular que ya fue procesado.
        Payment pre = new Payment(
            Id = paymentId,
            CAZ_TransactionStatus__c = 'Approved',
            CAZ_ResponseCode__c = '00',
            CAZ_ResponseMessage__c = 'Previamente aprobada',
            CAZ_Authorization__c = 'PRIOR_AUTH',
            CAZ_SignatureValid__c = true,
            CAZ_RefererValid__c = true
        );
        update pre;

        String validSig = computeValidSignature();
        String json = buildResponseJson(
            MP_ORDER, MP_REFERENCE, '250.00',
            '00', 'Segunda respuesta', MP_AUTH, validSig
        );

        Test.startTest();
        CAZ_MultipagosResponseHandler.PaymentResultData result =
            CAZ_MultipagosResponseHandler.processResponse(json, VALID_REFERER);
        Test.stopTest();

        System.assertEquals(true, result.alreadyProcessed,
            'Un Payment no-Pending debe devolver alreadyProcessed=true');
        System.assertEquals('Approved', result.transactionStatus);
        System.assertEquals('PRIOR_AUTH', result.authorization,
            'Debe devolver los valores previamente persistidos, no los del nuevo request');

        // El Payment no debe haberse reescrito.
        Payment persisted = [
            SELECT CAZ_Authorization__c, CAZ_ResponseMessage__c
            FROM Payment WHERE Id = :paymentId
        ];
        System.assertEquals('PRIOR_AUTH', persisted.CAZ_Authorization__c);
        System.assertEquals('Previamente aprobada', persisted.CAZ_ResponseMessage__c);
    }

    @IsTest
    static void processResponse_blankJson_throws() {
        setupSecret(TEST_SECRET);
        Boolean thrown = false;
        try {
            CAZ_MultipagosResponseHandler.processResponse('', VALID_REFERER);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown);
    }

    @IsTest
    static void processResponse_invalidJson_throws() {
        setupSecret(TEST_SECRET);
        Boolean thrown = false;
        try {
            CAZ_MultipagosResponseHandler.processResponse('not-a-valid-json{', VALID_REFERER);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown);
    }

    @IsTest
    static void processResponse_missingMinimumFields_throws() {
        setupSecret(TEST_SECRET);
        // Falta mp_response.
        String json = buildResponseJson(
            MP_ORDER, MP_REFERENCE, '250.00',
            '', 'x', MP_AUTH, 'any'
        );
        Boolean thrown = false;
        try {
            CAZ_MultipagosResponseHandler.processResponse(json, VALID_REFERER);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown);
    }

    @IsTest
    static void processResponse_invalidAmount_throws() {
        setupSecret(TEST_SECRET);
        setupPendingPayment();
        String json = buildResponseJson(
            MP_ORDER, MP_REFERENCE, 'NOT_A_NUMBER',
            '00', 'Aprobada', MP_AUTH, 'any'
        );
        Boolean thrown = false;
        try {
            CAZ_MultipagosResponseHandler.processResponse(json, VALID_REFERER);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown);
    }

    @IsTest
    static void processResponse_blankSecret_throws() {
        // NO insertamos el Custom Setting.
        setupPendingPayment();
        String json = buildResponseJson(
            MP_ORDER, MP_REFERENCE, '250.00',
            '00', 'Aprobada', MP_AUTH, 'any'
        );
        Boolean thrown = false;
        try {
            CAZ_MultipagosResponseHandler.processResponse(json, VALID_REFERER);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown);
    }

    @IsTest
    static void validateReferer_blankExpected_returnsFalse() {
        Boolean v = CAZ_MultipagosResponseHandler.validateReferer(VALID_REFERER, '');
        System.assertEquals(false, v);
    }

    @IsTest
    static void validateReferer_blankReferer_returnsFalse() {
        Boolean v = CAZ_MultipagosResponseHandler.validateReferer('', EXPECTED_HOST);
        System.assertEquals(false, v);
    }

    @IsTest
    static void validateReferer_matchingHost_returnsTrue() {
        Boolean v = CAZ_MultipagosResponseHandler.validateReferer(
            'https://prepro.adquiracloud.mx/return?x=1', EXPECTED_HOST
        );
        System.assertEquals(true, v, 'Host extraído debe coincidir con expected');
    }

    @IsTest
    static void validateReferer_matchingHostBareNoScheme_returnsTrue() {
        Boolean v = CAZ_MultipagosResponseHandler.validateReferer(
            'prepro.adquiracloud.mx:443/path', EXPECTED_HOST
        );
        System.assertEquals(true, v, 'Debe soportar referer sin esquema y con puerto');
    }

    @IsTest
    static void validateReferer_wrongHost_returnsFalse() {
        Boolean v = CAZ_MultipagosResponseHandler.validateReferer(
            'https://attacker.com/fake', EXPECTED_HOST
        );
        System.assertEquals(false, v);
    }

    @IsTest
    static void determineTransactionStatus_approvedWithValidSig() {
        String status = CAZ_MultipagosResponseHandler.determineTransactionStatus('00', true, true);
        System.assertEquals('Approved', status);
    }

    @IsTest
    static void determineTransactionStatus_approvedCodeWithInvalidSig() {
        String status = CAZ_MultipagosResponseHandler.determineTransactionStatus('00', false, true);
        System.assertEquals('Signature_Invalid', status);
    }

    @IsTest
    static void determineTransactionStatus_approvedWithInvalidReferer_stillApproved() {
        // Regla documentada en el handler: referer inválido NO degrada un
        // Approved cuando la firma es válida.
        String status = CAZ_MultipagosResponseHandler.determineTransactionStatus('00', true, false);
        System.assertEquals('Approved', status);
    }

    @IsTest
    static void determineTransactionStatus_rejectedCode() {
        String status = CAZ_MultipagosResponseHandler.determineTransactionStatus('54', true, true);
        System.assertEquals('Rejected', status);
    }

    @IsTest
    static void getSecretKey_returnsConfiguredValue() {
        setupSecret('handler-test-secret');
        String key = CAZ_MultipagosResponseHandler.getSecretKey();
        System.assertEquals('handler-test-secret', key);
    }
}