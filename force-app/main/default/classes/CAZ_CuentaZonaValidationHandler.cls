public with sharing class CAZ_CuentaZonaValidationHandler {

    public static void validateNoDuplicates(List<CAZ_Cuenta_y_Zona__c> newRecords) {
        Set<String> incomingKeys = new Set<String>();
        Map<String, List<CAZ_Cuenta_y_Zona__c>> recordsByKey = new Map<String, List<CAZ_Cuenta_y_Zona__c>>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> zonaIds = new Set<Id>();

        for (CAZ_Cuenta_y_Zona__c rec : newRecords) {
            if (rec.CAZ_Cuenta__c == null || rec.CAZ_Zona__c == null) {
                continue;
            }
            String key = String.valueOf(rec.CAZ_Cuenta__c) + '-' + String.valueOf(rec.CAZ_Zona__c);
            accountIds.add(rec.CAZ_Cuenta__c);
            zonaIds.add(rec.CAZ_Zona__c);

            if (incomingKeys.contains(key)) {
                rec.addError('Ya existe otra relación en este lote para la misma Cuenta y Zona.');
            }
            incomingKeys.add(key);

            if (!recordsByKey.containsKey(key)) {
                recordsByKey.put(key, new List<CAZ_Cuenta_y_Zona__c>());
            }
            recordsByKey.get(key).add(rec);
        }

        if (accountIds.isEmpty()) {
            return;
        }

        for (CAZ_Cuenta_y_Zona__c existing : [
            SELECT CAZ_Cuenta__c, CAZ_Zona__c
            FROM CAZ_Cuenta_y_Zona__c
            WHERE CAZ_Cuenta__c IN :accountIds AND CAZ_Zona__c IN :zonaIds
        ]) {
            String key = String.valueOf(existing.CAZ_Cuenta__c) + '-' + String.valueOf(existing.CAZ_Zona__c);
            if (recordsByKey.containsKey(key)) {
                for (CAZ_Cuenta_y_Zona__c rec : recordsByKey.get(key)) {
                    rec.addError('Esta Cuenta ya está relacionada con esta Zona.');
                }
            }
        }
    }
}
