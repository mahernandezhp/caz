trigger CAZ_SolicitudCreditoTrigger on CAZ_SolicitudCredito__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CAZ_SolicitudCreditoTriggerHandler.handleBeforeInsert(Trigger.new);
    }
}