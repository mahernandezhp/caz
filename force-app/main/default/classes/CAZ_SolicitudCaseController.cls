public with sharing class CAZ_SolicitudCaseController {

    @AuraEnabled(cacheable=false)
    public static List<Case> getMisSolicitudes(Integer limitSize, Integer offsetSize) {
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
            SELECT Id, CaseNumber, Description, Status, CreatedDate,
                   CAZ_ImporteDevolucion__c, Reason
            FROM Case
            WHERE AccountId = :accountId
            AND RecordType.DeveloperName = 'Solicitud_de_Devolucion'
            ORDER BY CreatedDate DESC
            LIMIT :lSize
            OFFSET :oSize
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Integer getTotalSolicitudes() {
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
            WHERE AccountId = :accountId
            AND RecordType.DeveloperName = 'Solicitud_de_Devolucion'
        ];
    }

    @AuraEnabled
    public static void enviarSolicitud(Id recordId) {
        submitApprovalFromPortal(recordId);
    }

    @AuraEnabled
    public static void submitApprovalFromPortal(Id recordId) {
        try {
            Case c = [SELECT Id, Status FROM Case WHERE Id = :recordId WITH SECURITY_ENFORCED LIMIT 1];
            
            if (c.Status == 'Borrador' || c.Status == 'New') {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Solicitud enviada para revisión desde el portal');
                req.setObjectId(recordId);
                
                Approval.ProcessResult result = Approval.process(req);
                if (!result.isSuccess()) {
                    throw new AuraHandledException('No se pudo enviar la solicitud.');
                }
            } else {
                throw new AuraHandledException('Solo se pueden enviar solicitudes en estado Borrador/Nuevo.');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}