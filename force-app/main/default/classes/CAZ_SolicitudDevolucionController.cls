public with sharing class CAZ_SolicitudDevolucionController {

    @AuraEnabled(cacheable=false)
    public static List<Case> getMisSolicitudes(Integer limitSize, Integer offsetSize) {
        Id devolucionRtId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Devolucion')
            .getRecordTypeId();

        // Para usuarios de comunidad: obtener AccountId del usuario actual
        List<User> currentUsers = [
            SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];

        if (currentUsers.isEmpty() || currentUsers[0].AccountId == null) {
            return new List<Case>();
        }

        Id accountId = currentUsers[0].AccountId;

        Integer lSize = (limitSize != null && limitSize > 0) ? limitSize : 10;
        Integer oSize = (offsetSize != null && offsetSize >= 0) ? offsetSize : 0;

        return [
            SELECT Id, CaseNumber, Subject, Status, CreatedDate,
                   CAZ_ImporteDevolucion__c, CAZ_MotivoDevolucion__c
            FROM Case
            WHERE RecordTypeId = :devolucionRtId
              AND AccountId = :accountId
            ORDER BY CreatedDate DESC
            LIMIT :lSize
            OFFSET :oSize
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Integer getTotalSolicitudes() {
        Id devolucionRtId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Devolucion')
            .getRecordTypeId();

        List<User> currentUsers = [
            SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];

        if (currentUsers.isEmpty() || currentUsers[0].AccountId == null) {
            return 0;
        }

        Id accountId = currentUsers[0].AccountId;

        return [
            SELECT COUNT()
            FROM Case
            WHERE RecordTypeId = :devolucionRtId
              AND AccountId = :accountId
        ];
    }

    @AuraEnabled
    public static void enviarSolicitud(Id caseId) {
        try {
            Case c = [SELECT Id, Status FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED LIMIT 1];
            if (c.Status == 'Borrador') {
                c.Status = 'Por atender';
                update c;
            } else {
                throw new AuraHandledException('Solo se pueden enviar solicitudes en estado Borrador.');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
