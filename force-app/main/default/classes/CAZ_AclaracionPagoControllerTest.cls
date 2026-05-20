@isTest
public class CAZ_AclaracionPagoControllerTest {

    @testSetup
    static void setup() {
        // Crear Account de prueba
        Account acc = new Account(
            Name = 'Distribuidor Test',
            AccountNumber = '12345',
            ClaveJDE__c = '12345'
        );
        insert acc;
        
        // Crear Contact de prueba
        Contact con = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert con;
        
        // Crear Usuario de Portal/Comunidad o un Standard User con ContactId
        // Para simplificar la prueba y evitar setup de roles/portal, el controller maneja un fallback de 10 cuentas 
        // cuando el usuario actual no tiene un ContactId configurado. Probaremos ambas rutas si es posible.
    }

    @isTest
    static void testGetDistribuidoresDelUsuario() {
        System.Test.startTest();
        // Como el usuario administrador que corre la prueba no tiene un ContactId asociado,
        // el método debe retornar el fallback (hasta 10 cuentas).
        List<Account> accounts = CAZ_AclaracionPagoController.getDistribuidoresDelUsuario();
        System.Test.stopTest();
        
        System.assertNotEquals(null, accounts, 'La lista de distribuidores no debe ser nula');
        System.assert(accounts.size() > 0, 'Debe retornar al menos una cuenta en modo fallback');
    }

    @isTest
    static void testEnviarSolicitud_Exito() {
        Account acc = [SELECT Id, AccountNumber FROM Account LIMIT 1];
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('accountId', acc.Id);
        params.put('motivo', 'Pago duplicado');
        params.put('numeroFactura', 'FAC-001');
        params.put('monto', 1500.50);
        params.put('fechaPago', String.valueOf(Date.today()));
        params.put('referencia', 'REF-12345');
        params.put('descripcion', 'Test descripción');
        // No enviamos comprobanteUrl para probar la ruta simple primero
        
        System.Test.startTest();
        String caseId = CAZ_AclaracionPagoController.enviarSolicitud(params);
        System.Test.stopTest();
        
        System.assertNotEquals(null, caseId, 'El CaseId retornado no debe ser nulo');
        
        Case insertedCase = [SELECT Id, Status, Subject, CAZ_NumeroFactura__c FROM Case WHERE Id = :caseId];
        // Al terminar stopTest(), el Queueable se ejecuta y cambia el status a En Revisión
        System.assertEquals('En Revisión', insertedCase.Status, 'El estado final debe ser En Revisión');
        System.assertEquals('FAC-001', insertedCase.CAZ_NumeroFactura__c, 'La factura debe coincidir');
    }

    @isTest
    static void testEnviarSolicitud_ConDocumento() {
        Account acc = [SELECT Id, AccountNumber FROM Account LIMIT 1];
        
        // Simular la subida de un archivo
        ContentVersion cv = new ContentVersion(
            Title = 'Comprobante Test',
            PathOnClient = 'comprobante.pdf',
            VersionData = Blob.valueOf('File Content Test'),
            IsMajorVersion = true
        );
        insert cv;
        
        ContentVersion cvInserted = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('accountId', acc.Id);
        params.put('motivo', 'Error en la referencia');
        params.put('numeroFactura', 'FAC-002');
        params.put('monto', 500.00);
        params.put('fechaPago', String.valueOf(Date.today()));
        params.put('referencia', 'REF-999');
        params.put('descripcion', 'Archivo adjunto');
        params.put('comprobanteUrl', cvInserted.ContentDocumentId);
        
        System.Test.startTest();
        String caseId = CAZ_AclaracionPagoController.enviarSolicitud(params);
        System.Test.stopTest();
        
        System.assertNotEquals(null, caseId, 'El CaseId retornado no debe ser nulo');
        
        // Verificar que se vinculó el archivo
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :caseId];
        System.assertEquals(1, links.size(), 'Debe existir un ContentDocumentLink vinculado al caso');
        
        Case insertedCase = [SELECT Id, CAZ_ComprobantePago__c FROM Case WHERE Id = :caseId];
        System.assert(insertedCase.CAZ_ComprobantePago__c.contains(cvInserted.ContentDocumentId), 'La URL del comprobante debe contener el ContentDocumentId');
    }
    
    @isTest
    static void testEnviarSolicitud_Error() {
        Map<String, Object> params = new Map<String, Object>();
        // Faltan parámetros obligatorios o AccountId inválido, debería fallar
        params.put('accountId', 'IdInvalido');
        
        System.Test.startTest();
        try {
            CAZ_AclaracionPagoController.enviarSolicitud(params);
            System.assert(false, 'Debería haber arrojado una excepción');
        } catch (Exception e) {
            System.assertNotEquals(null, e, 'Se debe haber capturado una excepción de creación');
        }
        System.Test.stopTest();
    }
}
