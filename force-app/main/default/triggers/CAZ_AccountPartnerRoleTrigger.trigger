trigger CAZ_AccountPartnerRoleTrigger on Account (after insert, after update) {
    CAZ_CobranzaAccountTriggerHandler.enqueueCobranzaCases(
        Trigger.new,
        Trigger.isUpdate ? Trigger.oldMap : null
    );
}
