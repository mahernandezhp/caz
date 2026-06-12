trigger CAZ_CuentaZonaTrigger on CAZ_Cuenta_y_Zona__c (after insert, after delete) {
    List<CAZ_Cuenta_y_Zona__c> records = Trigger.isDelete ? Trigger.old : Trigger.new;
    CAZ_ZonaSharingHandler.reconcileAccountsAsync(
        CAZ_ZonaSharingHandler.extractAccountIds(records)
    );
}
