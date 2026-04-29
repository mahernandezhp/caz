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

        Map<String, Id> queueMap = new Map<String, Id>();
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('CreditoCobranza', 'Tesoreria')]) {
            queueMap.put(g.DeveloperName, g.Id);
        }

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        Long ochoHorasEnMs = 8L * 60L * 60L * 1000L;

        List<CAZ_SolicitudDevolucion__c> casosAValidar = new List<CAZ_SolicitudDevolucion__c>();
        for (CAZ_SolicitudDevolucion__c c : newRecords) {
            CAZ_SolicitudDevolucion__c oldRecord = oldMap.get(c.Id);

            // 1. Asignación para el Siguiente Recordatorio y Cambio a Tesorería
            if (c.CAZ_Status__c == 'Aprobado') {
                if (oldRecord.CAZ_Status__c != 'Aprobado') {
                    // La primera vez que pasa a Aprobado, lo programamos a 8 horas hábiles y lo pasamos a Tesorería
                    c.CAZ_SiguienteRecordatorio__c = BusinessHours.add(bh.Id, System.now(), ochoHorasEnMs);
                    if (queueMap.get('Tesoreria') != null) {
                        c.OwnerId = queueMap.get('Tesoreria');
                    }
                } else if (c.CAZ_SiguienteRecordatorio__c == null) {
                    c.CAZ_SiguienteRecordatorio__c = BusinessHours.add(bh.Id, System.now(), ochoHorasEnMs);
                }
            } else {
                // Si el estatus ya no es Aprobado, limpiamos el campo para cancelar cualquier recordatorio
                c.CAZ_SiguienteRecordatorio__c = null;
            }

            // 2. Validación de documentos requeridos
            if (oldRecord.CAZ_Status__c == STATUS_BORRADOR
                && c.CAZ_Status__c == STATUS_POR_ATENDER) {
                casosAValidar.add(c);
            }

            // 3. Regresar propietario al creador si pasa a Borrador
            if (oldRecord.CAZ_Status__c != STATUS_BORRADOR && c.CAZ_Status__c == STATUS_BORRADOR) {
                c.OwnerId = c.CreatedById;
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

        Id creditoCobranzaQueueId = queueMap.get('CreditoCobranza');

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
            } else if (creditoCobranzaQueueId != null) {
                c.OwnerId = creditoCobranzaQueueId;
            }
        }
    }

    /**
     * Punto de entrada desde el trigger after update.
     */
    public static void handleAfterUpdate(List<CAZ_SolicitudDevolucion__c> newRecords, Map<Id, CAZ_SolicitudDevolucion__c> oldMap) {
        
        List<CAZ_SolicitudDevolucion__c> solicitudesConCambio = new List<CAZ_SolicitudDevolucion__c>();
        List<CAZ_SolicitudDevolucion__Share> sharesToInsert = new List<CAZ_SolicitudDevolucion__Share>();

        for (CAZ_SolicitudDevolucion__c c : newRecords) {
            String oldStatus = oldMap.get(c.Id).CAZ_Status__c;
            if (c.CAZ_Status__c != oldStatus) {
                solicitudesConCambio.add(c);
            }

            // Mantenimiento de acceso: Si cambió el propietario y ya no es el creador, restaurar acceso al creador
            if (c.OwnerId != oldMap.get(c.Id).OwnerId && c.OwnerId != c.CreatedById) {
                CAZ_SolicitudDevolucion__Share shareRec = new CAZ_SolicitudDevolucion__Share();
                shareRec.ParentId = c.Id;
                shareRec.UserOrGroupId = c.CreatedById;
                shareRec.AccessLevel = 'Edit';
                shareRec.RowCause = Schema.CAZ_SolicitudDevolucion__Share.RowCause.Manual;
                sharesToInsert.add(shareRec);
            }
        }
        
        if (!sharesToInsert.isEmpty()) {
            try {
                new SharingHelper().insertShares(sharesToInsert);
            } catch (Exception e) {
                System.debug('Error insertando CAZ_SolicitudDevolucion__Share: ' + e.getMessage());
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
            
            // 1. Notificaciones para Ejecutivos (Colas)
            Set<String> recipientEjecutivos = new Set<String>();
            String bodyEjecutivos = '';
            
            if (c.CAZ_Status__c == 'Por atender') {
                bodyEjecutivos = 'Hay una nueva Solicitud de Devolución para Revisión Inicial en tu bandeja.';
                if (creditoCobranzaId != null) recipientEjecutivos.add(creditoCobranzaId);
            } else if (c.CAZ_Status__c == 'Aprobado') {
                bodyEjecutivos = 'Hay una Solicitud de Devolución Aprobada lista para tu gestión.';
                if (tesoreriaId != null) recipientEjecutivos.add(tesoreriaId);
            }

            if (!recipientEjecutivos.isEmpty()) {
                Messaging.CustomNotification notifEjec = new Messaging.CustomNotification();
                notifEjec.setBody(bodyEjecutivos);
                notifEjec.setTitle('Acción Requerida: Solicitud de Devolución');
                notifEjec.setSenderId(UserInfo.getUserId());
                notifEjec.setNotificationTypeId(notifTypeId);
                notifEjec.setTargetId(c.Id);
                try { notifEjec.send(recipientEjecutivos); } catch (Exception e) {}
            }

            // 2. Notificación al Distribuidor Creador (siempre y cuando él NO haya sido el que originó el cambio)
            if (c.CreatedById != null && c.CreatedById != UserInfo.getUserId()) {
                String bodyDistribuidor = '';
                if (c.CAZ_Status__c == 'Aprobado') {
                    bodyDistribuidor = 'Tu Solicitud de Devolución ha sido Aprobada y será procesada por Tesorería.';
                } else if (c.CAZ_Status__c == 'Rechazado') {
                    bodyDistribuidor = 'Tu Solicitud de Devolución ha sido Rechazada. Consulta las resoluciones de los ejecutivos.';
                } else if (c.CAZ_Status__c == 'Borrador') {
                    bodyDistribuidor = 'Tu Solicitud de Devolución requiere ajustes. Por favor, revisa la solicitud en estado Borrador.';
                } else if (c.CAZ_Status__c == 'Solicitud Completada') {
                    bodyDistribuidor = 'Tu Solicitud de Devolución ha sido completada exitosamente.';
                } else {
                    bodyDistribuidor = 'El estatus de tu Solicitud de Devolución ha cambiado a: ' + c.CAZ_Status__c;
                }

                Set<String> recDistribuidor = new Set<String>{ c.CreatedById };
                Messaging.CustomNotification notifDist = new Messaging.CustomNotification();
                notifDist.setBody(bodyDistribuidor);
                notifDist.setTitle('Actualización: Solicitud de Devolución');
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
        public void insertShares(List<CAZ_SolicitudDevolucion__Share> shares) {
            if (!shares.isEmpty()) {
                insert shares;
            }
        }
    }
}