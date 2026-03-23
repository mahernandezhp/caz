public with sharing class CAZ_SolicitudDevolucionController {

    @AuraEnabled(cacheable=false)
    public static List<Case> getMisSolicitudes() {
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

        return [
            SELECT Id, CaseNumber, Subject, Status, CreatedDate,
                   CAZ_ImporteDevolucion__c, CAZ_MotivoDevolucion__c
            FROM Case
            WHERE RecordTypeId = :devolucionRtId
              AND AccountId = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}
