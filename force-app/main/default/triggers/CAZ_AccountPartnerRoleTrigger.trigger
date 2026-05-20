trigger CAZ_AccountPartnerRoleTrigger on Account (after update) {
    CAZ_AccountPartnerRoleHandler.createPartnerRoles(Trigger.new, Trigger.oldMap);
}
