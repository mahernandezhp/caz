public with sharing class CAZ_MisSolicitudesCreditoCtrl {
    
    @AuraEnabled
    public static Integer getTotalSolicitudesCredito() {
        return [
            SELECT Count() 
            FROM Case 
            WHERE RecordType.DeveloperName = 'SolicitudCredito' 
            AND CreatedById = :UserInfo.getUserId()
        ];
    }

    @AuraEnabled
    public static List<Case> getMisSolicitudesCredito(Integer limitSize, Integer offsetSize) {
        return [
            SELECT Id, CaseNumber, Status, CAZ_RFC__c, CAZ_DiasCredito__c, CreatedDate 
            FROM Case 
            WHERE RecordType.DeveloperName = 'SolicitudCredito'
            AND CreatedById = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT :limitSize 
            OFFSET :offsetSize
        ];
    }
}