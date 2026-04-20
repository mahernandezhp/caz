@IsTest
private class CAZ_MultipagosSignatureServiceTest {

    /**
     * ============================================================================
     * Clase: CAZ_MultipagosSignatureServiceTest
     * ============================================================================
     * Propósito:
     * Cubrir todas las ramas lógicas de CAZ_MultipagosSignatureService.
     *
     * Cobertura esperada:
     * - generateRequestSignature: camino feliz, normalización de amount,
     *   determinismo y las 4 ramas de validación (order/reference/secret/amount).
     * - generateResponseSignature: camino feliz, diferenciación frente a
     *   request signature, rama de authorization vacío.
     * - isResponseSignatureValid: match, mismatch, case-insensitive,
     *   recibido blank y null.
     *
     * Notas:
     * - La clase bajo prueba es pura (sin DML ni SOQL), por eso estos tests no
     *   requieren @TestSetup ni Test.startTest()/stopTest() salvo para aislar
     *   límites en el caso más pesado.
     * ============================================================================
     */

    private static final String ORDER      = 'ORD00000001';
    private static final String REFERENCE  = 'CAZORD0000000112345';
    private static final String AUTH       = 'AUTH123456';
    private static final String SECRET     = 'flap-secret-key-demo-2026';

    @IsTest
    static void generateRequestSignature_returnsHexLowercase() {
        Test.startTest();
        String sig = CAZ_MultipagosSignatureService.generateRequestSignature(
            ORDER, REFERENCE, 100.00, SECRET
        );
        Test.stopTest();

        System.assertNotEquals(null, sig, 'La firma no debe ser null');
        System.assertEquals(64, sig.length(), 'HMAC SHA-256 en hex debe tener 64 chars');
        System.assertEquals(sig.toLowerCase(), sig, 'La firma debe estar en lowercase');
        System.assert(Pattern.matches('[0-9a-f]+', sig), 'La firma debe ser hex: ' + sig);
    }

    @IsTest
    static void generateRequestSignature_isDeterministic() {
        String s1 = CAZ_MultipagosSignatureService.generateRequestSignature(
            ORDER, REFERENCE, 100.00, SECRET
        );
        String s2 = CAZ_MultipagosSignatureService.generateRequestSignature(
            ORDER, REFERENCE, 100.00, SECRET
        );
        System.assertEquals(s1, s2, 'Mismos inputs deben producir la misma firma');
    }

    @IsTest
    static void generateRequestSignature_amountNormalization_integerEqualsDecimal() {
        // 100 y 100.00 deben producir la misma firma porque normalizeAmount
        // aplica setScale(2) a ambos valores.
        String sInt = CAZ_MultipagosSignatureService.generateRequestSignature(
            ORDER, REFERENCE, 100, SECRET
        );
        String sDec = CAZ_MultipagosSignatureService.generateRequestSignature(
            ORDER, REFERENCE, 100.00, SECRET
        );
        System.assertEquals(sInt, sDec, '100 y 100.00 deben ser equivalentes tras setScale(2)');
    }

    @IsTest
    static void generateRequestSignature_differentAmountsProduceDifferentSignatures() {
        String s1 = CAZ_MultipagosSignatureService.generateRequestSignature(
            ORDER, REFERENCE, 100.00, SECRET
        );
        String s2 = CAZ_MultipagosSignatureService.generateRequestSignature(
            ORDER, REFERENCE, 100.01, SECRET
        );
        System.assertNotEquals(s1, s2, 'Amounts distintos deben generar firmas distintas');
    }

    @IsTest
    static void generateRequestSignature_blankOrder_throws() {
        Boolean thrown = false;
        try {
            CAZ_MultipagosSignatureService.generateRequestSignature('', REFERENCE, 100.00, SECRET);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown, 'Debe lanzar AuraHandledException por order vacío');
    }

    @IsTest
    static void generateRequestSignature_nullReference_throws() {
        Boolean thrown = false;
        try {
            CAZ_MultipagosSignatureService.generateRequestSignature(ORDER, null, 100.00, SECRET);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown, 'Debe lanzar AuraHandledException por reference null');
    }

    @IsTest
    static void generateRequestSignature_blankSecret_throws() {
        Boolean thrown = false;
        try {
            CAZ_MultipagosSignatureService.generateRequestSignature(ORDER, REFERENCE, 100.00, '');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown, 'Debe lanzar AuraHandledException por secret vacío');
    }

    @IsTest
    static void generateRequestSignature_nullAmount_throws() {
        Boolean thrown = false;
        try {
            CAZ_MultipagosSignatureService.generateRequestSignature(ORDER, REFERENCE, null, SECRET);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown, 'Debe lanzar AuraHandledException por amount null');
    }

    @IsTest
    static void generateResponseSignature_happyPath() {
        String sig = CAZ_MultipagosSignatureService.generateResponseSignature(
            ORDER, REFERENCE, 100.00, AUTH, SECRET
        );
        System.assertNotEquals(null, sig);
        System.assertEquals(64, sig.length(), 'HMAC SHA-256 hex debe tener 64 chars');
    }

    @IsTest
    static void generateResponseSignature_differsFromRequestSignature() {
        // Response firma una cadena más larga (incluye authorization), por eso
        // request y response nunca coinciden aunque compartan orden/ref/amount.
        String req = CAZ_MultipagosSignatureService.generateRequestSignature(
            ORDER, REFERENCE, 100.00, SECRET
        );
        String resp = CAZ_MultipagosSignatureService.generateResponseSignature(
            ORDER, REFERENCE, 100.00, AUTH, SECRET
        );
        System.assertNotEquals(req, resp, 'Request y response firman cadenas distintas');
    }

    @IsTest
    static void generateResponseSignature_blankAuthorization_throws() {
        Boolean thrown = false;
        try {
            CAZ_MultipagosSignatureService.generateResponseSignature(
                ORDER, REFERENCE, 100.00, '', SECRET
            );
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown, 'Debe lanzar AuraHandledException por authorization vacío');
    }

    @IsTest
    static void generateResponseSignature_blankOrder_throws() {
        Boolean thrown = false;
        try {
            CAZ_MultipagosSignatureService.generateResponseSignature(
                null, REFERENCE, 100.00, AUTH, SECRET
            );
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown);
    }

    @IsTest
    static void generateResponseSignature_blankSecret_throws() {
        Boolean thrown = false;
        try {
            CAZ_MultipagosSignatureService.generateResponseSignature(
                ORDER, REFERENCE, 100.00, AUTH, null
            );
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown);
    }

    @IsTest
    static void generateResponseSignature_nullAmount_throws() {
        Boolean thrown = false;
        try {
            CAZ_MultipagosSignatureService.generateResponseSignature(
                ORDER, REFERENCE, null, AUTH, SECRET
            );
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assertEquals(true, thrown);
    }

    @IsTest
    static void isResponseSignatureValid_matchingSignature_returnsTrue() {
        String expected = CAZ_MultipagosSignatureService.generateResponseSignature(
            ORDER, REFERENCE, 100.00, AUTH, SECRET
        );
        Boolean valid = CAZ_MultipagosSignatureService.isResponseSignatureValid(
            ORDER, REFERENCE, 100.00, AUTH, SECRET, expected
        );
        System.assertEquals(true, valid, 'Firma calculada localmente debe validar');
    }

    @IsTest
    static void isResponseSignatureValid_uppercaseReceived_returnsTrue() {
        // Simula que Multipagos devolviera la firma en mayúsculas (no lo hace,
        // pero el método normaliza con toLowerCase() antes de comparar, y esa
        // rama debe quedar cubierta).
        String expected = CAZ_MultipagosSignatureService.generateResponseSignature(
            ORDER, REFERENCE, 100.00, AUTH, SECRET
        );
        Boolean valid = CAZ_MultipagosSignatureService.isResponseSignatureValid(
            ORDER, REFERENCE, 100.00, AUTH, SECRET, expected.toUpperCase()
        );
        System.assertEquals(true, valid, 'La validación debe ser case-insensitive');
    }

    @IsTest
    static void isResponseSignatureValid_wrongSignature_returnsFalse() {
        Boolean valid = CAZ_MultipagosSignatureService.isResponseSignatureValid(
            ORDER, REFERENCE, 100.00, AUTH, SECRET,
            'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
        );
        System.assertEquals(false, valid, 'Firma arbitraria no debe validar');
    }

    @IsTest
    static void isResponseSignatureValid_blankReceived_returnsFalse() {
        Boolean valid = CAZ_MultipagosSignatureService.isResponseSignatureValid(
            ORDER, REFERENCE, 100.00, AUTH, SECRET, ''
        );
        System.assertEquals(false, valid, 'Firma vacía debe retornar false sin lanzar');
    }

    @IsTest
    static void isResponseSignatureValid_nullReceived_returnsFalse() {
        Boolean valid = CAZ_MultipagosSignatureService.isResponseSignatureValid(
            ORDER, REFERENCE, 100.00, AUTH, SECRET, null
        );
        System.assertEquals(false, valid, 'Firma null debe retornar false sin lanzar');
    }
}