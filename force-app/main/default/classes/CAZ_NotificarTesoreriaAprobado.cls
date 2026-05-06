public with sharing class CAZ_NotificarTesoreriaAprobado {
    
    @InvocableMethod(label='Enviar Recordatorio a Tesorería' description='Envía notificación In-App y Correo al dueño actual (Tesorería o Usuario asignado), y re-programa usando horario hábil')
    public static void enviarRecordatorios(List<Id> solicitudIds) {
        if (solicitudIds == null || solicitudIds.isEmpty()) return;

        List<CAZ_SolicitudDevolucion__c> solicitudes = [
            SELECT Id, Name, CAZ_Status__c, CAZ_SiguienteRecordatorio__c, OwnerId 
            FROM CAZ_SolicitudDevolucion__c 
            WHERE Id IN :solicitudIds AND CAZ_Status__c = 'Aprobado'
        ];

        if (solicitudes.isEmpty()) return;

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

        List<String> emailsTesoreria = new List<String>();
        if (tesoreriaGroup != null) {
            Set<Id> directMemberIds = new Set<Id>();
            for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :tesoreriaGroup.Id]) {
                directMemberIds.add(gm.UserOrGroupId);
            }
            
            Set<Id> userIds = new Set<Id>();
            for (Id memId : directMemberIds) {
                if (memId.getSObjectType() == User.sObjectType) {
                    userIds.add(memId);
                }
            }
            
            for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId IN :directMemberIds]) {
                if (gm.UserOrGroupId.getSObjectType() == User.sObjectType) {
                    userIds.add(gm.UserOrGroupId);
                }
            }
            
            for(User u : [SELECT Email FROM User WHERE Id IN :userIds]) {
                emailsTesoreria.add(u.Email);
            }
        }
        
        // 3. Obtener correos de los usuarios asignados individuales
        Set<Id> ownerUserIds = new Set<Id>();
        for (CAZ_SolicitudDevolucion__c sol : solicitudes) {
            if (sol.OwnerId.getSObjectType() == User.sObjectType) {
                ownerUserIds.add(sol.OwnerId);
            }
        }
        Map<Id, String> ownerUserEmails = new Map<Id, String>();
        if (!ownerUserIds.isEmpty()) {
            for (User u : [SELECT Id, Email FROM User WHERE Id IN :ownerUserIds]) {
                ownerUserEmails.put(u.Id, u.Email);
            }
        }

        // 4. Obtener Horario Hábil por Defecto (Business Hours)
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        Long ochoHorasEnMs = 8L * 60L * 60L * 1000L;

        String siteUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/CAZ_SolicitudDevolucion__c/';

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<CAZ_SolicitudDevolucion__c> recordsToUpdate = new List<CAZ_SolicitudDevolucion__c>();

        for (CAZ_SolicitudDevolucion__c sol : solicitudes) {
            String recordUrl = siteUrl + sol.Id + '/view';
            
            Set<String> recipientIds = new Set<String>();
            List<String> currentEmails = new List<String>();

            if (sol.OwnerId.getSObjectType() == User.sObjectType) {
                recipientIds.add(sol.OwnerId);
                if (ownerUserEmails.containsKey(sol.OwnerId)) {
                    currentEmails.add(ownerUserEmails.get(sol.OwnerId));
                }
            } else {
                if (tesoreriaGroup != null) recipientIds.add(tesoreriaGroup.Id);
                currentEmails = emailsTesoreria;
            }
            
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
            if (!currentEmails.isEmpty()) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(currentEmails);
                email.setSubject('⏳ Recordatorio de Atención: Solicitud de Devolución en Espera [' + sol.Name + ']');
                email.setHtmlBody(
                    'Hola,<br><br>' +
                    'La Solicitud de Devolución <b>' + sol.Name + '</b> cuenta con el estatus de <b>\'Aprobado\'</b> y está pendiente de su atención para continuar con el proceso.<br><br>' +
                    'Por favor, accede al siguiente enlace para revisarla y gestionarla:<br>' +
                    '<a href="' + recordUrl + '">' + recordUrl + '</a><br><br>' +
                    '<i>(Este es un recordatorio automático que se generará cada 8 horas hábiles mientras la solicitud se mantenga en este estatus).</i>'
                );
                email.setSaveAsActivity(false);
                emailsToSend.add(email);
            }

            // Update Field to re-trigger the Flow later using Business Hours
            sol.CAZ_SiguienteRecordatorio__c = BusinessHours.add(bh.Id, System.now(), ochoHorasEnMs);
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