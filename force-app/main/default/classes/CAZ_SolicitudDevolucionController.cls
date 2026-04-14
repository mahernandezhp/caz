public with sharing class CAZ_SolicitudDevolucionController {

    @AuraEnabled(cacheable=false)
    public static List<CAZ_SolicitudDevolucion__c> getMisSolicitudes(Integer limitSize, Integer offsetSize) {
        // Para usuarios de comunidad: obtener AccountId del usuario actual
        List<User> currentUsers = [
            SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];

        if (currentUsers.isEmpty() || currentUsers[0].AccountId == null) {
            return new List<CAZ_SolicitudDevolucion__c>();
        }

        Id accountId = currentUsers[0].AccountId;

        Integer lSize = (limitSize != null && limitSize > 0) ? limitSize : 10;
        Integer oSize = (offsetSize != null && offsetSize >= 0) ? offsetSize : 0;

        return [
            SELECT Id, Name, CAZ_Description__c, CAZ_Status__c, CreatedDate,
                   CAZ_ImporteDevolucion__c, CAZ_MotivoDevolucion__c
            FROM CAZ_SolicitudDevolucion__c
            WHERE CAZ_Account__c = :accountId
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
            FROM CAZ_SolicitudDevolucion__c
            WHERE CAZ_Account__c = :accountId
        ];
    }

    @AuraEnabled
    public static void enviarSolicitud(Id recordId) {
        // Redirigir siempre al método oficial que ejecuta la clase central de aprobaciones
        submitApprovalFromPortal(recordId);
    }

    @AuraEnabled
    public static void submitApprovalFromPortal(Id recordId) {
        try {
            // Se asume Contexto Without Sharing al momento del trigger o System Run si hay temas de acceso
            // Pero como es public with sharing, el perfil requiere acceso al Id o ser Owner
            CAZ_SolicitudDevolucion__c c = [SELECT Id, CAZ_Status__c FROM CAZ_SolicitudDevolucion__c WHERE Id = :recordId WITH SECURITY_ENFORCED LIMIT 1];
            
            if (c.CAZ_Status__c == 'Borrador') {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Solicitud enviada para revisión desde el portal');
                req.setObjectId(recordId);
                // Si el usuario es quien lo creó y es el owner, no necesitamos forzar el SubmitterId
                // porque lo hará por defecto el context user.
                
                Approval.ProcessResult result = Approval.process(req);
                if (!result.isSuccess()) {
                    throw new AuraHandledException('No se pudo enviar la solicitud.');
                }
            } else {
                throw new AuraHandledException('Solo se pueden enviar solicitudes en estado Borrador.');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}