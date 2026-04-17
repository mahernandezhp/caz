public with sharing class CAZ_DocumentoSolicitudController {

    @AuraEnabled(cacheable=true)
    public static List<CAZ_DocumentoSolicitud__mdt> getDocumentosRequeridos(String processName) {
        if (String.isBlank(processName)) {
            return new List<CAZ_DocumentoSolicitud__mdt>();
        }
        return [
            SELECT MasterLabel, CAZ_Obligatorio__c, CAZ_TipoProceso__c, CAZ_TipoArchivoPermitido__c
            FROM CAZ_DocumentoSolicitud__mdt
            WHERE CAZ_TipoProceso__c = :processName
            ORDER BY MasterLabel ASC
        ];
    }

    /**
     * Etiqueta un archivo subido con el tipo de documento seleccionado por el usuario.
     * Actualiza la Description del ContentVersion más reciente del ContentDocument dado.
     * @param contentDocumentId Id del ContentDocument recién subido
     * @param tipoDocumento Label del tipo de documento (ej. "Comprobante de pago")
     */
    @AuraEnabled
    public static void etiquetarDocumento(Id contentDocumentId, String tipoDocumento) {
        if (contentDocumentId == null || String.isBlank(tipoDocumento)) {
            throw new AuraHandledException('Se requiere el archivo y el tipo de documento.');
        }

        List<ContentVersion> versions = [
            SELECT Id, Title, Description
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
              AND IsLatest = true
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (versions.isEmpty()) {
            throw new AuraHandledException('No se encontró el archivo cargado.');
        }

        ContentVersion cv = versions[0];
        cv.Description = tipoDocumento;
        update cv;
    }

    @AuraEnabled
    public static List<Map<String, String>> getDocumentosCargados(Id recordId) {
        if (recordId == null) {
            return new List<Map<String, String>>();
        }
        
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersion.Description
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            WITH SECURITY_ENFORCED
        ];
        
        List<Map<String, String>> results = new List<Map<String, String>>();
        for (ContentDocumentLink link : links) {
            Map<String, String> fileMap = new Map<String, String>();
            fileMap.put('documentId', link.ContentDocumentId);
            fileMap.put('name', link.ContentDocument.Title);
            fileMap.put('tipoDocumento', link.ContentDocument.LatestPublishedVersion.Description);
            results.add(fileMap);
        }
        return results;
    }

    @AuraEnabled
    public static void eliminarDocumento(Id documentId) {
        if (documentId == null) {
            throw new AuraHandledException('El ID del documento es requerido.');
        }

        try {
            ContentDocument doc = [SELECT Id FROM ContentDocument WHERE Id = :documentId WITH SECURITY_ENFORCED LIMIT 1];
            delete doc;
        } catch (Exception e) {
            throw new AuraHandledException('Error al eliminar el documento: ' + e.getMessage());
        }
    }
}