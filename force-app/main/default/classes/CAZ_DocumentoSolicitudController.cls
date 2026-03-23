public with sharing class CAZ_DocumentoSolicitudController {

    @AuraEnabled(cacheable=true)
    public static List<CAZ_DocumentoSolicitud__mdt> getDocumentosDevolucion() {
        return [
            SELECT MasterLabel, CAZ_Obligatorio__c, CAZ_TipoProceso__c, CAZ_TipoArchivoPermitido__c
            FROM CAZ_DocumentoSolicitud__mdt
            WHERE CAZ_TipoProceso__c = 'Devolucion'
            ORDER BY MasterLabel ASC
        ];
    }
}
