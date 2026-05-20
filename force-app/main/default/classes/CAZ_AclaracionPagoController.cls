public with sharing class CAZ_AclaracionPagoController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getDistribuidoresDelUsuario() {
        Id userId = UserInfo.getUserId();
        User currentUser = [SELECT Contact.AccountId FROM User WHERE Id = :userId LIMIT 1];
        
        if (currentUser.ContactId != null && currentUser.Contact.AccountId != null) {
            return [SELECT Id, Name, AccountNumber FROM Account WHERE Id = :currentUser.Contact.AccountId];
        }
        
        // Para pruebas de desarrollador interno
        return [SELECT Id, Name, AccountNumber FROM Account LIMIT 10];
    }

    @AuraEnabled
    public static String enviarSolicitud(Map<String, Object> params) {
        try {
            Id accountId = (Id) params.get('accountId');
            String motivo = (String) params.get('motivo');
            String numeroFactura = (String) params.get('numeroFactura');
            Decimal monto = params.get('monto') != null ? Decimal.valueOf(String.valueOf(params.get('monto'))) : null;
            String fechaPagoStr = (String) params.get('fechaPago');
            String referencia = (String) params.get('referencia');
            String comprobanteUrl = (String) params.get('comprobanteUrl'); // This can be ContentDocumentId
            String descripcion = (String) params.get('descripcion');
            
            Date fechaPago = null;
            if (String.isNotBlank(fechaPagoStr)) {
                fechaPago = Date.valueOf(fechaPagoStr);
            }
            
            RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'AclaracionPagos' AND SobjectType = 'Case' LIMIT 1];
            
            Case newCase = new Case(
                RecordTypeId = rt.Id,
                Status = 'Borrador',
                Origin = 'Web',
                Subject = 'Aclaración de Pago - Factura ' + numeroFactura,
                Description = descripcion,
                CAZ_ClaveDistribuidor__c = accountId,
                CAZ_MotivoAclaracion__c = motivo,
                CAZ_NumeroFactura__c = numeroFactura,
                CAZ_MontoPagado__c = monto,
                CAZ_FechaPago__c = fechaPago,
                CAZ_ReferenciaBancaria__c = referencia
            );
            
            User u = [SELECT ContactId, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            if (u.ContactId != null) {
                newCase.ContactId = u.ContactId;
            }
            
            insert newCase;
            
            // Vincular el archivo adjunto si se proporcionó un ContentDocumentId
            if (String.isNotBlank(comprobanteUrl) && comprobanteUrl.startsWith('069')) {
                ContentDocumentLink cdl = new ContentDocumentLink(
                    ContentDocumentId = comprobanteUrl,
                    LinkedEntityId = newCase.Id,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                );
                insert cdl;
                newCase.CAZ_ComprobantePago__c = URL.getOrgDomainUrl().toExternalForm() + '/' + comprobanteUrl;
                update newCase;
            }
            
            // Encolar la búsqueda asíncrona en JDE
            if (String.isNotBlank(numeroFactura) && accountId != null) {
                Account acc = [SELECT AccountNumber FROM Account WHERE Id = :accountId LIMIT 1];
                System.enqueueJob(new CAZ_AclaracionPagoQueueable(newCase.Id, acc.AccountNumber, numeroFactura));
            }
            
            return newCase.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creando la solicitud: ' + e.getMessage());
        }
    }
}
