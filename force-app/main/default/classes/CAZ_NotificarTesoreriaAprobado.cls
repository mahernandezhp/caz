public with sharing class CAZ_NotificarTesoreriaAprobado {
    
    @InvocableMethod(label='Enviar Recordatorio a Tesorería' description='Envía notificación In-App y Correo a Tesorería, y re-programa el campo CAZ_SiguienteRecordatorio__c')
    public static void enviarRecordatorios(List<Id> solicitudIds) {
        if (solicitudIds == null || solicitudIds.isEmpty()) return;

        List<CAZ_SolicitudDevolucion__c> solicitudes = [
            SELECT Id, Name, CAZ_Status__c, CAZ_SiguienteRecordatorio__c 
            FROM CAZ_SolicitudDevolucion__c 
            WHERE Id IN :solicitudIds AND CAZ_Status__c = 'Aprobado'
        ];

        if (solicitudIds.isEmpty()) return;

        // 1. Obtener Custom Notification Type
        List<CustomNotificationType> notifTypes = [
            SELECT Id FROM CustomNotificationType 
            WHERE DeveloperName = 'Notificaciones_Portal' LIMIT 1
        ];
        Id notifTypeId = notifTypes.isEmpty() ? null : notifTypes[0].Id;

        // 2. Obtener Grupo/Cola Tesorería y sus emails
        Group tesoreriaGroup = null;
        List<Group> grupos = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Tesoreria' LIMIT 1];
        if (!grupos.isEmpty()) {
            tesoreriaGroup = grupos[0];
        }

        Set<String> recipientIds = new Set<String>();
        if (tesoreriaGroup != null) recipientIds.add(tesoreriaGroup.Id);

        // Opcional: Obtener correos directos de los miembros para enviar un correo
        // (Por simplicidad, enviaremos la CustomNotification. Para el correo usaremos el email de la cola si tiene, o iteramos)
        List<String> emailsTesoreria = new List<String>();
        if (tesoreriaGroup != null) {
            for(User u : [SELECT Email FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :tesoreriaGroup.Id)]) {
                emailsTesoreria.add(u.Email);
            }
        }
        
        String siteUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/CAZ_SolicitudDevolucion__c/';

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<CAZ_SolicitudDevolucion__c> recordsToUpdate = new List<CAZ_SolicitudDevolucion__c>();

        for (CAZ_SolicitudDevolucion__c sol : solicitudes) {
            String recordUrl = siteUrl + sol.Id + '/view';
            
            // Notification Push
            if (notifTypeId != null && !recipientIds.isEmpty()) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setBody('La Solicitud de Devolución ' + sol.Name + ' cuenta con el estatus de \'Aprobado\' y está pendiente de su atención.');
                notification.setTitle('⏳ Recordatorio de Atención: Solicitud ' + sol.Name);
                notification.setSenderId(UserInfo.getUserId());
                notification.setNotificationTypeId(notifTypeId);
                notification.setTargetId(sol.Id);
                try { notification.send(recipientIds); } catch (Exception e) {}
            }

            // Email Send
            if (!emailsTesoreria.isEmpty()) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(emailsTesoreria);
                email.setSubject('⏳ Recordatorio de Atención: Solicitud de Devolución en Espera [' + sol.Name + ']');
                email.setHtmlBody(
                    'Hola equipo de Tesorería,<br><br>' +
                    'La Solicitud de Devolución <b>' + sol.Name + '</b> cuenta con el estatus de <b>\'Aprobado\'</b> y está pendiente de su atención para continuar con el proceso.<br><br>' +
                    'Por favor, accede al siguiente enlace para revisarla y gestionarla:<br>' +
                    '<a href="' + recordUrl + '">' + recordUrl + '</a><br><br>' +
                    '<i>(Este es un recordatorio automático que se generará cada 8 horas mientras la solicitud se mantenga en este estatus).</i>'
                );
                email.setSaveAsActivity(false);
                emailsToSend.add(email);
            }

            // Update Field to re-trigger the Flow later
            // Adding 8 hours to the current date/time to re-queue the Scheduled Path
            sol.CAZ_SiguienteRecordatorio__c = System.now().addHours(8);
            recordsToUpdate.add(sol);
        }

        if (!emailsToSend.isEmpty()) {
            try { Messaging.sendEmail(emailsToSend, false); } catch(Exception e) {}
        }

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
}
