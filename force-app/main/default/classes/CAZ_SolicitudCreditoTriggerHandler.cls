/**
 * CAZ_SolicitudCreditoTriggerHandler
 * ---------------------
 * Handler para el trigger de CAZ_SolicitudCredito__c.
 * Auto-asigna la cuenta del distribuidor (CAZ_Cuenta__c) desde el
 * AccountId del usuario de comunidad que crea el registro.
 * Controla notificaciones in-app, horarios de recordatorio y visibilidad.
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
     * Punto de entrada desde el trigger before update.
     */
    public static void handleBeforeUpdate(List<CAZ_SolicitudCredito__c> newRecords, Map<Id, CAZ_SolicitudCredito__c> oldMap) {
        if (isSystemAdminUser()) {
            return;
        }

        Map<String, Id> queueMap = new Map<String, Id>();
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('CreditoCobranza', 'Tesoreria')]) {
            queueMap.put(g.DeveloperName, g.Id);
        }

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        Long ochoHorasEnMs = 8L * 60L * 60L * 1000L;

        for (CAZ_SolicitudCredito__c c : newRecords) {
            CAZ_SolicitudCredito__c oldRecord = oldMap.get(c.Id);

            // 1. Asignación para el Siguiente Recordatorio y Cambio a Crédito y Cobranza
            if (c.CAZ_Estatus__c == 'En Revisión') {
                if (oldRecord.CAZ_Estatus__c != 'En Revisión') {
                    // La primera vez que pasa a En Revisión, lo programamos a 8 horas hábiles y lo pasamos a CreditoCobranza
                    c.CAZ_SiguienteRecordatorio__c = BusinessHours.add(bh.Id, System.now(), ochoHorasEnMs);
                    if (queueMap.get('CreditoCobranza') != null) {
                        c.OwnerId = queueMap.get('CreditoCobranza');
                    }
                } else if (c.CAZ_SiguienteRecordatorio__c == null) {
                    c.CAZ_SiguienteRecordatorio__c = BusinessHours.add(bh.Id, System.now(), ochoHorasEnMs);
                }
            } else {
                // Si el estatus ya no es En Revisión, limpiamos el campo para cancelar cualquier recordatorio
                c.CAZ_SiguienteRecordatorio__c = null;
            }

            // 2. Si regresa a Borrador, le devolvemos la propiedad al creador original
            if (c.CAZ_Estatus__c == 'Borrador' && oldRecord.CAZ_Estatus__c != 'Borrador') {
                if (c.CreatedById != null) {
                    c.OwnerId = c.CreatedById;
                }
            }
        }
    }

    /**
     * Punto de entrada desde el trigger after update.
     * Envía notificaciones In-App cuando cambia el estatus de la Solicitud de Crédito.
     * Mantiene el acceso de lectura/edición para el creador original mediante Apex Managed Sharing.
     */
    public static void handleAfterUpdate(List<CAZ_SolicitudCredito__c> newRecords, Map<Id, CAZ_SolicitudCredito__c> oldMap) {
        
        List<CAZ_SolicitudCredito__c> solicitudesConCambio = new List<CAZ_SolicitudCredito__c>();
        List<CAZ_SolicitudCredito__Share> sharesToInsert = new List<CAZ_SolicitudCredito__Share>();

        for (CAZ_SolicitudCredito__c c : newRecords) {
            String oldStatus = oldMap.get(c.Id).CAZ_Estatus__c;
            if (c.CAZ_Estatus__c != oldStatus) {
                solicitudesConCambio.add(c);
            }

            // Mantenimiento de acceso: Si cambió el propietario y ya no es el creador, restaurar acceso al creador
            if (c.OwnerId != oldMap.get(c.Id).OwnerId && c.OwnerId != c.CreatedById) {
                CAZ_SolicitudCredito__Share shareRec = new CAZ_SolicitudCredito__Share();
                shareRec.ParentId = c.Id;
                shareRec.UserOrGroupId = c.CreatedById;
                shareRec.AccessLevel = 'Edit';
                shareRec.RowCause = Schema.CAZ_SolicitudCredito__Share.RowCause.Manual;
                sharesToInsert.add(shareRec);
            }
        }
        
        if (!sharesToInsert.isEmpty()) {
            try {
                new SharingHelper().insertShares(sharesToInsert);
            } catch (Exception e) {
                System.debug('Error insertando CAZ_SolicitudCredito__Share: ' + e.getMessage());
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
        
        Map<String, Id> queueNameMap = new Map<String, Id>();
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('CreditoCobranza', 'Tesoreria')]) {
            queueNameMap.put(g.DeveloperName, g.Id);
        }

        Id creditoCobranzaId = queueNameMap.get('CreditoCobranza');
        Id tesoreriaId = queueNameMap.get('Tesoreria');
        
        for (CAZ_SolicitudCredito__c c : solicitudesConCambio) {
            // 1. Notificaciones para Ejecutivos (Colas)
            Set<String> recipientEjecutivos = new Set<String>();
            String bodyEjecutivos = '';
            
            if (c.CAZ_Estatus__c == 'Por atender' || c.CAZ_Estatus__c == 'En Revisión') {
                bodyEjecutivos = 'Hay una nueva Solicitud de Crédito para Revisión en tu bandeja.';
                if (creditoCobranzaId != null) recipientEjecutivos.add(creditoCobranzaId);
            }

            if (!recipientEjecutivos.isEmpty()) {
                Messaging.CustomNotification notifEjec = new Messaging.CustomNotification();
                notifEjec.setBody(bodyEjecutivos);
                notifEjec.setTitle('Acción Requerida: Solicitud de Crédito');
                notifEjec.setSenderId(UserInfo.getUserId());
                notifEjec.setNotificationTypeId(notifTypeId);
                notifEjec.setTargetId(c.Id);
                try { notifEjec.send(recipientEjecutivos); } catch (Exception e) {}
            }

            // 2. Notificación al Distribuidor
            // Se le envía a su CreatedById para garantizar que le llegue, sin importar de qué cola es el dueño actual
            if (c.CreatedById != UserInfo.getUserId()) {
                String bodyDistribuidor = '';
                if (c.CAZ_Estatus__c == 'Aprobado') {
                    bodyDistribuidor = 'Tu Solicitud de Crédito ha sido Aprobada y resuelta con éxito.';
                } else if (c.CAZ_Estatus__c == 'Rechazado') {
                    bodyDistribuidor = 'Tu Solicitud de Crédito ha sido Rechazada. Consulta las resoluciones de los ejecutivos.';
                } else {
                    bodyDistribuidor = 'El estatus de tu Solicitud de Crédito ha cambiado a: ' + c.CAZ_Estatus__c;
                }

                Set<String> recDistribuidor = new Set<String>{ c.CreatedById };
                Messaging.CustomNotification notifDist = new Messaging.CustomNotification();
                notifDist.setBody(bodyDistribuidor);
                notifDist.setTitle('Actualización: Solicitud de Crédito');
                notifDist.setSenderId(UserInfo.getUserId());
                notifDist.setNotificationTypeId(notifTypeId);
                notifDist.setTargetId(c.Id);
                try { notifDist.send(recDistribuidor); } catch (Exception e) {}
            }
        }
    }

    @TestVisible
    private static Boolean isSystemAdminUser() {
        String profileName = [
            SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1
        ].Name;

        return profileName == 'System Administrator'
            || profileName == 'Administrador del sistema';
    }

    private without sharing class SharingHelper {
        public void insertShares(List<CAZ_SolicitudCredito__Share> shares) {
            if (!shares.isEmpty()) {
                insert shares;
            }
        }
    }
}