trigger CAZ_SolicitudCreditoTrigger on CAZ_SolicitudCredito__c (before insert, before update, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CAZ_SolicitudCreditoTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        CAZ_SolicitudCreditoTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        CAZ_SolicitudCreditoTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}