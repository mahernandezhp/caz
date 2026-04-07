trigger CAZ_CaseTrigger on Case (before update) {
    CAZ_CaseTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
}