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

    @TestVisible
    private static Boolean isSystemAdminUser() {
        String profileName = [
            SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1
        ].Name;

        return profileName == 'System Administrator'
            || profileName == 'Administrador del sistema';
    }
}