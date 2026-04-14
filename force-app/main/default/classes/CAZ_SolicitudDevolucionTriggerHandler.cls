/**
 * CAZ_SolicitudDevolucionTriggerHandler
 * ---------------------
 * Handler para el trigger de CAZ_SolicitudDevolucion__c.
 * Valida que las solicitudes de devolución cuenten con todos los documentos
 * obligatorios antes de permitir el cambio de estatus de Borrador → Por atender.
 */
public with sharing class CAZ_SolicitudDevolucionTriggerHandler {

    private static final String STATUS_BORRADOR   = 'Borrador';
    private static final String STATUS_POR_ATENDER = 'Por atender';
    private static final String PROCESO_DEVOLUCION = 'Devolucion';

    /**
     * Punto de entrada desde el trigger before insert.
     */
    public static void handleBeforeInsert(List<CAZ_SolicitudDevolucion__c> newRecords) {
        // Obtener el AccountId del usuario actual si es de comunidad
        Id userAccountId = null;
        List<User> currentUsers = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (!currentUsers.isEmpty() && currentUsers[0].AccountId != null) {
            userAccountId = currentUsers[0].AccountId;
        }

        // Si el usuario tiene una cuenta asociada, asignarla a las nuevas solicitudes
        if (userAccountId != null) {
            for (CAZ_SolicitudDevolucion__c c : newRecords) {
                if (c.CAZ_Account__c == null) {
                    c.CAZ_Account__c = userAccountId;
                }
            }
        }
    }

    /**
     * Punto de entrada desde el trigger before update.
     */
    public static void handleBeforeUpdate(List<CAZ_SolicitudDevolucion__c> newRecords, Map<Id, CAZ_SolicitudDevolucion__c> oldMap) {
        if (isSystemAdminUser()) {
            return;
        }

        List<CAZ_SolicitudDevolucion__c> casosAValidar = new List<CAZ_SolicitudDevolucion__c>();
        for (CAZ_SolicitudDevolucion__c c : newRecords) {
            CAZ_SolicitudDevolucion__c oldRecord = oldMap.get(c.Id);
            if (oldRecord.CAZ_Status__c == STATUS_BORRADOR
                && c.CAZ_Status__c == STATUS_POR_ATENDER) {
                casosAValidar.add(c);
            }
        }

        if (casosAValidar.isEmpty()) {
            return;
        }

        List<CAZ_DocumentoSolicitud__mdt> docsObligatorios = [
            SELECT MasterLabel
            FROM CAZ_DocumentoSolicitud__mdt
            WHERE CAZ_TipoProceso__c = :PROCESO_DEVOLUCION
              AND CAZ_Obligatorio__c = true
            ORDER BY MasterLabel ASC
        ];

        if (docsObligatorios.isEmpty()) {
            return;
        }

        Set<String> nombresObligatorios = new Set<String>();
        for (CAZ_DocumentoSolicitud__mdt doc : docsObligatorios) {
            nombresObligatorios.add(doc.MasterLabel);
        }

        Set<Id> recordIds = new Set<Id>();
        for (CAZ_SolicitudDevolucion__c c : casosAValidar) {
            recordIds.add(c.Id);
        }

        Map<Id, Set<String>> tiposDocPorRegistro = new Map<Id, Set<String>>();
        for (Id rId : recordIds) {
            tiposDocPorRegistro.put(rId, new Set<String>());
        }

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :recordIds
        ];

        if (!links.isEmpty()) {
            Set<Id> contentDocIds = new Set<Id>();
            Map<Id, Id> contentDocToRecordMap = new Map<Id, Id>();
            for (ContentDocumentLink cdl : links) {
                contentDocIds.add(cdl.ContentDocumentId);
                contentDocToRecordMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }

            List<ContentVersion> versions = [
                SELECT ContentDocumentId, Description
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocIds
                  AND IsLatest = true
            ];

            for (ContentVersion cv : versions) {
                Id linkedRecordId = contentDocToRecordMap.get(cv.ContentDocumentId);
                if (linkedRecordId != null && String.isNotBlank(cv.Description)) {
                    tiposDocPorRegistro.get(linkedRecordId).add(cv.Description);
                }
            }
        }

        for (CAZ_SolicitudDevolucion__c c : casosAValidar) {
            Set<String> tiposCargados = tiposDocPorRegistro.get(c.Id);
            List<String> faltantes = new List<String>();

            for (String nombreObligatorio : nombresObligatorios) {
                if (!tiposCargados.contains(nombreObligatorio)) {
                    faltantes.add(nombreObligatorio);
                }
            }

            if (!faltantes.isEmpty()) {
                String mensajeFaltantes = String.join(faltantes, ', ');
                c.addError(
                    'No es posible enviar la solicitud de devolución. '
                    + 'Faltan los siguientes documentos obligatorios: '
                    + mensajeFaltantes + '.'
                );
            }
        }
    }

    /**
     * Punto de entrada desde el trigger after update.
     */
    public static void handleAfterUpdate(List<CAZ_SolicitudDevolucion__c> newRecords, Map<Id, CAZ_SolicitudDevolucion__c> oldMap) {
        
        List<CAZ_SolicitudDevolucion__c> solicitudesConCambio = new List<CAZ_SolicitudDevolucion__c>();
        for (CAZ_SolicitudDevolucion__c c : newRecords) {
            String oldStatus = oldMap.get(c.Id).CAZ_Status__c;
            if (c.CAZ_Status__c != oldStatus) {
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
        
        for (CAZ_SolicitudDevolucion__c c : solicitudesConCambio) {
            if (c.CAZ_Status__c == 'Borrador') continue;

            String body = '';
            Set<String> recipientIds = new Set<String>();
            
            if (c.CAZ_Status__c == 'Por atender') {
                body = 'Hay una nueva Solicitud de Devolución para Revisión Inicial en tu bandeja.';
                if (creditoCobranzaId != null) recipientIds.add(creditoCobranzaId);
            } else if (c.CAZ_Status__c == 'En revisión Tesorería') {
                body = 'La Solicitud de Devolución superó revisión crediticia y espera Revisión Final en tu bandeja.';
                if (tesoreriaId != null) recipientIds.add(tesoreriaId);
            } else if (c.CAZ_Status__c == 'Aprobado') {
                body = 'Tu Solicitud de Devolución ha sido Aprobada y resuelta con éxito.';
                if (String.valueOf(c.OwnerId).startsWith('005')) recipientIds.add(c.OwnerId);
            } else if (c.CAZ_Status__c == 'Rechazado') {
                body = 'Tu Solicitud de Devolución ha sido Rechazada. Consulta las resoluciones de los ejecutivos.';
                if (String.valueOf(c.OwnerId).startsWith('005')) recipientIds.add(c.OwnerId);
            } else {
                body = 'El estatus de la Solicitud de Devolución ha cambiado a: ' + c.CAZ_Status__c;
                if (String.valueOf(c.OwnerId).startsWith('005')) recipientIds.add(c.OwnerId);
            }

            if (!recipientIds.isEmpty()) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setBody(body);
                notification.setTitle('Actualización: Solicitud de Devolución');
                notification.setSenderId(UserInfo.getUserId());
                notification.setNotificationTypeId(notifTypeId);
                notification.setTargetId(c.Id);

                try {
                    notification.send(recipientIds);
                } catch (Exception e) {
                    System.debug('Error enviando notificación push de la campaña: ' + e.getMessage());
                }
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
}