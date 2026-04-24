public with sharing class CAZ_SolicitudCreditoController {

    @AuraEnabled(cacheable=false)
    public static List<CAZ_SolicitudCredito__c> getMisSolicitudes(Integer limitSize, Integer offsetSize) {
        List<User> currentUsers = [
            SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];

        if (currentUsers.isEmpty() || currentUsers[0].AccountId == null) {
            return new List<CAZ_SolicitudCredito__c>();
        }

        Id accountId = currentUsers[0].AccountId;

        Integer lSize = (limitSize != null && limitSize > 0) ? limitSize : 10;
        Integer oSize = (offsetSize != null && offsetSize >= 0) ? offsetSize : 0;

        return [
            SELECT Id, Name, CAZ_Cuenta__c, CAZ_MontoSolicitado__c, CAZ_Dias__c,
                   CAZ_Justificacion__c, CAZ_Estatus__c, CAZ_RFC__c,
                   CAZ_Comentarios__c, CAZ_Resolucion__c, CreatedDate
            FROM CAZ_SolicitudCredito__c
            WHERE CAZ_Cuenta__c = :accountId
            ORDER BY CreatedDate DESC
            LIMIT :lSize
            OFFSET :oSize
        ];
    }

    @AuraEnabled(cacheable=false)
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
            FROM CAZ_SolicitudCredito__c
            WHERE CAZ_Cuenta__c = :accountId
        ];
    }

    @AuraEnabled
    public static void enviarSolicitud(Id recordId) {
        try {
            CAZ_SolicitudCredito__c sol = [
                SELECT Id, CAZ_Estatus__c 
                FROM CAZ_SolicitudCredito__c 
                WHERE Id = :recordId 
                WITH SECURITY_ENFORCED 
                LIMIT 1
            ];
            
            if (sol.CAZ_Estatus__c == 'Borrador') {
                sol.CAZ_Estatus__c = 'Por atender';
                update sol;
            } else {
                throw new AuraHandledException('Solo se pueden enviar solicitudes en estado Borrador.');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getUserContext() {
        Map<String, String> context = new Map<String, String>();
        
        List<User> currentUsers = [
            SELECT Id, AccountId, ContactId 
            FROM User 
            WHERE Id = :UserInfo.getUserId() 
            LIMIT 1
        ];
        
        if (!currentUsers.isEmpty()) {
            User u = currentUsers[0];
            if (u.AccountId != null) {
                context.put('AccountId', u.AccountId);
            }
            if (u.ContactId != null) {
                context.put('ContactId', u.ContactId);
            }
        }
        
        return context;
    }
}