@isTest
public class CAZ_AclaracionPagoQueueableTest {

    @testSetup
    static void setup() {
        // Crear un caso base para la prueba
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'AclaracionPagos' AND SobjectType = 'Case' LIMIT 1];
        
        Case c = new Case(
            RecordTypeId = rt.Id,
            Status = 'Borrador',
            Subject = 'Prueba Queueable',
            CAZ_NumeroFactura__c = 'FAC-999'
        );
        insert c;
    }

    @isTest
    static void testQueueableExecution() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        
        // Encolar el job
        CAZ_AclaracionPagoQueueable queueableJob = new CAZ_AclaracionPagoQueueable(c.Id, '12345', 'FAC-999');
        
        System.Test.startTest();
        System.enqueueJob(queueableJob);
        System.Test.stopTest(); // Se fuerza la ejecución de procesos asíncronos encolados
        
        // Verificar que el caso se actualizó correctamente a En Revisión
        Case updatedCase = [SELECT Id, Status, CAZ_AbonoEncontrado__c FROM Case WHERE Id = :c.Id];
        System.assertEquals('En Revisión', updatedCase.Status, 'El estado del caso debió actualizarse a En Revisión');
        
        // Verificar el comentario del caso
        List<CaseComment> comments = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :c.Id];
        System.assertEquals(1, comments.size(), 'Debe haberse agregado un CaseComment');
        System.assert(comments[0].CommentBody.contains('Resultado de búsqueda en JDE'), 'El comentario debe contener la confirmación del mock');
    }
}
