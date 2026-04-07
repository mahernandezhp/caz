trigger CAZ_SolicitudDevolucionTrigger on CAZ_SolicitudDevolucion__c (before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        CAZ_SolicitudDevolucionTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}