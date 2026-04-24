/**
 * CAZ_SolicitudCreditoTriggerHandler
 * ---------------------
 * Handler para el trigger de CAZ_SolicitudCredito__c.
 * Auto-asigna la cuenta del distribuidor (CAZ_Cuenta__c) desde el
 * AccountId del usuario de comunidad que crea el registro.
 */
public with sharing class CAZ_SolicitudCreditoTriggerHandler {

    /**
     * Punto de entrada desde el trigger before insert.
     * Auto-asigna CAZ_Cuenta__c del AccountId del usuario actual.
     */
    public static void handleBeforeInsert(List<CAZ_SolicitudCredito__c> newRecords) {
        Id userAccountId = null;
        List<User> currentUsers = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (!currentUsers.isEmpty() && currentUsers[0].AccountId != null) {
            userAccountId = currentUsers[0].AccountId;
        }

        if (userAccountId != null) {
            for (CAZ_SolicitudCredito__c sol : newRecords) {
                if (sol.CAZ_Cuenta__c == null) {
                    sol.CAZ_Cuenta__c = userAccountId;
                }
            }
        }
    }

    /**
     * Punto de entrada desde el trigger after update.
     * Envía notificaciones In-App cuando cambia el estatus de la Solicitud de Crédito.
     */
    public static void handleAfterUpdate(List<CAZ_SolicitudCredito__c> newRecords, Map<Id, CAZ_SolicitudCredito__c> oldMap) {
        
        List<CAZ_SolicitudCredito__c> solicitudesConCambio = new List<CAZ_SolicitudCredito__c>();
        for (CAZ_SolicitudCredito__c c : newRecords) {
            String oldStatus = oldMap.get(c.Id).CAZ_Estatus__c;
            if (c.CAZ_Estatus__c != oldStatus) {
                solicitudesConCambio.add(c);
            }
        }
        
        if (solicitudesConCambio.isEmpty()) {
            return;
        }

        List<CustomNotificationType> notifTypes = [
            SELECT Id FROM CustomNotificationType 
            WHERE DeveloperName = 'Notificaciones_Portal' LIMIT 1
        ];

        if (notifTypes.isEmpty()) {
            return;
        }

        Id notifTypeId = notifTypes[0].Id;
        
        // Consultar los Groups de tipo Queue para enviarles las notificaciones corporativas
        Map<String, Id> queueNameMap = new Map<String, Id>();
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('CreditoCobranza', 'Tesoreria')]) {
            queueNameMap.put(g.DeveloperName, g.Id);
        }

        Id creditoCobranzaId = queueNameMap.get('CreditoCobranza');
        Id tesoreriaId = queueNameMap.get('Tesoreria');
        
        for (CAZ_SolicitudCredito__c c : solicitudesConCambio) {
            if (c.CAZ_Estatus__c == 'Borrador') continue;

            String body = '';
            Set<String> recipientIds = new Set<String>();
            
            if (c.CAZ_Estatus__c == 'Por atender' || c.CAZ_Estatus__c == 'En Revisión') {
                body = 'Hay una nueva Solicitud de Crédito para Revisión en tu bandeja.';
                if (creditoCobranzaId != null) recipientIds.add(creditoCobranzaId);
            } else if (c.CAZ_Estatus__c == 'Aprobado') {
                body = 'Tu Solicitud de Crédito ha sido Aprobada y resuelta con éxito.';
                if (String.valueOf(c.OwnerId).startsWith('005')) recipientIds.add(c.OwnerId);
            } else if (c.CAZ_Estatus__c == 'Rechazado') {
                body = 'Tu Solicitud de Crédito ha sido Rechazada. Consulta las resoluciones de los ejecutivos.';
                if (String.valueOf(c.OwnerId).startsWith('005')) recipientIds.add(c.OwnerId);
            } else {
                body = 'El estatus de la Solicitud de Crédito ha cambiado a: ' + c.CAZ_Estatus__c;
                if (String.valueOf(c.OwnerId).startsWith('005')) recipientIds.add(c.OwnerId);
            }

            if (!recipientIds.isEmpty()) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setBody(body);
                notification.setTitle('Actualización: Solicitud de Crédito');
                notification.setSenderId(UserInfo.getUserId());
                notification.setNotificationTypeId(notifTypeId);
                notification.setTargetId(c.Id);

                try {
                    notification.send(recipientIds);
                } catch (Exception e) {
                    System.debug('Error enviando notificación push: ' + e.getMessage());
                }
            }
        }
    }
}