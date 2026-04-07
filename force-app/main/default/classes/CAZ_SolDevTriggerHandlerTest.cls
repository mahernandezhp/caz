@isTest
private class CAZ_SolDevTriggerHandlerTest {

    private static CAZ_SolicitudDevolucion__c crearSolicitudBorrador() {
        CAZ_SolicitudDevolucion__c s = new CAZ_SolicitudDevolucion__c(
            CAZ_Status__c = 'Borrador',
            CAZ_MotivoDevolucion__c = 'Pago duplicado',
            CAZ_ImporteDevolucion__c = 1500.00
        );
        insert s;
        return s;
    }

    private static void adjuntarDocumento(Id recordId, String tipoDocumento) {
        ContentVersion cv = new ContentVersion(
            Title = tipoDocumento + ' - test.pdf',
            PathOnClient = tipoDocumento + '_test.pdf',
            VersionData = Blob.valueOf('contenido de prueba'),
            Description = tipoDocumento
        );
        insert cv;

        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = recordId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
    }

    @isTest
    static void testBloqueaSinDocumentos() {
        CAZ_SolicitudDevolucion__c s = crearSolicitudBorrador();

        Test.startTest();
        s.CAZ_Status__c = 'Por atender';
        Database.SaveResult sr = Database.update(s, false);
        Test.stopTest();

        Boolean isAdmin = CAZ_SolicitudDevolucionTriggerHandler.isSystemAdminUser();
        if (!isAdmin) {
            System.assert(!sr.isSuccess(), 'Debería fallar sin documentos obligatorios');
            System.assert(sr.getErrors()[0].getMessage().contains('documentos obligatorios'));
        } else {
            System.assert(sr.isSuccess(), 'System Admin no debe ser bloqueado');
        }
    }

    @isTest
    static void testPermiteConDocumentosCompletos() {
        CAZ_SolicitudDevolucion__c s = crearSolicitudBorrador();

        List<CAZ_DocumentoSolicitud__mdt> docsObligatorios = [
            SELECT MasterLabel
            FROM CAZ_DocumentoSolicitud__mdt
            WHERE CAZ_TipoProceso__c = 'Devolucion'
              AND CAZ_Obligatorio__c = true
        ];

        for (CAZ_DocumentoSolicitud__mdt doc : docsObligatorios) {
            adjuntarDocumento(s.Id, doc.MasterLabel);
        }

        Test.startTest();
        s.CAZ_Status__c = 'Por atender';
        Database.SaveResult sr = Database.update(s, false);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Debería permitir el envío con todos los documentos: ' + sr.getErrors());
    }
}