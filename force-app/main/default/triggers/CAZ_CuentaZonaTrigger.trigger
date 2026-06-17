trigger CAZ_CuentaZonaTrigger on CAZ_Cuenta_y_Zona__c (before insert, after insert, after delete) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CAZ_CuentaZonaValidationHandler.validateNoDuplicates(Trigger.new);
    }

    if (Trigger.isAfter) {
        List<CAZ_Cuenta_y_Zona__c> records = Trigger.isDelete ? Trigger.old : Trigger.new;
        CAZ_ZonaSharingHandler.reconcileAccountsAsync(
            CAZ_ZonaSharingHandler.extractAccountIds(records)
        );
    }
}