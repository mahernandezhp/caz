trigger CAZ_SolicitudDevolucionTrigger on CAZ_SolicitudDevolucion__c (before insert, before update, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CAZ_SolicitudDevolucionTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        CAZ_SolicitudDevolucionTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        CAZ_SolicitudDevolucionTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}