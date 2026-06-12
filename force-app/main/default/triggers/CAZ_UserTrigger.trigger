trigger CAZ_UserTrigger on User (after insert) {
    CAZ_UserPermissionSetHandler.assignDistribuidorAdminPermissionSet(Trigger.new);
    CAZ_ZonaSharingHandler.reconcileUsers(Trigger.new);
}
