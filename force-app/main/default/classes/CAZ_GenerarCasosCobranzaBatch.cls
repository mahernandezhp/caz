public class CAZ_GenerarCasosCobranzaBatch implements Database.Batchable<sObject>, Schedulable {
    
    /**
     * Método Schedulable para programar el Batch (ej. que corra diariamente)
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CAZ_GenerarCasosCobranzaBatch());
    }
    
    /**
     * Inicia el Batch recolectando todas las cuentas que presentan atraso (días > 0)
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Name, OwnerId, CAZ_DiasAtraso__c, CAZ_NivelRiesgoCobranza__c 
            FROM Account 
            WHERE CAZ_DiasAtraso__c > 0
        ]);
    }

    /**
     * Ejecuta la lógica para cada bloque de cuentas
     */
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : scope) {
            accountIds.add(acc.Id);
        }
        
        // Obtener el Id del Record Type de Cobranza y Negociación de forma dinámica
        Id recordTypeId;
        try {
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CAZ_CobranzaNegociacion').getRecordTypeId();
        } catch (Exception e) {
            System.debug('Error: No se encontró el Record Type CAZ_CobranzaNegociacion');
            return;
        }
        
        // Identificar qué cuentas ya tienen un Caso de Cobranza Abierto para evitar duplicados
        Set<Id> accountsWithOpenCases = new Set<Id>();
        for (Case c : [SELECT AccountId FROM Case 
                       WHERE AccountId IN :accountIds 
                       AND RecordTypeId = :recordTypeId 
                       AND IsClosed = false]) {
            accountsWithOpenCases.add(c.AccountId);
        }
        
        List<Case> casesToInsert = new List<Case>();
        
        // Generar los nuevos casos
        for (Account acc : scope) {
            if (!accountsWithOpenCases.contains(acc.Id)) {
                Case newCase = new Case(
                    AccountId = acc.Id,
                    RecordTypeId = recordTypeId,
                    Status = 'Nuevo',
                    Priority = 'High',
                    Origin = 'Integración ERP',
                    Subject = 'Gestión de Cobranza - ' + acc.Name + ' - Bucket ' + acc.CAZ_NivelRiesgoCobranza__c,
                    CAZ_BucketActual__c = acc.CAZ_NivelRiesgoCobranza__c,
                    OwnerId = acc.OwnerId // Asignación inicial al Ejecutivo de Cuenta
                );
                casesToInsert.add(newCase);
            }
        }
        
        // Insertar los casos tolerando fallos parciales (AllOrNone = false)
        if (!casesToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(casesToInsert, false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    // Loguear errores para su posterior revisión (Idealmente en un Custom Object de Logs)
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error al insertar Caso de Cobranza: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
    }

    /**
     * Finaliza el Batch (Aquí se pueden enviar alertas por correo de resumen de ejecución)
     */
    public void finish(Database.BatchableContext BC) {
        System.debug('CAZ_GenerarCasosCobranzaBatch Finalizado exitosamente.');
    }
}