public with sharing class CAZ_UserPermissionSetHandler {

    private static final String DISTRIBUIDOR_ADMIN_PROFILE = 'Portal Distribuidor - Partner Community User';
    private static final String DISTRIBUIDOR_ADMIN_PSG = 'CAZ_Portal_Distribuidor_Admin';

    public static void assignDistribuidorAdminPermissionSet(List<User> newUsers) {
        Set<Id> profileIds = new Set<Id>();
        for (User u : newUsers) {
            profileIds.add(u.ProfileId);
        }

        Map<Id, Profile> distribuidorAdminProfiles = new Map<Id, Profile>(
            [SELECT Id FROM Profile WHERE Id IN :profileIds AND Name = :DISTRIBUIDOR_ADMIN_PROFILE]
        );

        if (distribuidorAdminProfiles.isEmpty()) {
            return;
        }

        Set<Id> userIds = new Set<Id>();
        for (User u : newUsers) {
            if (distribuidorAdminProfiles.containsKey(u.ProfileId)) {
                userIds.add(u.Id);
            }
        }

        if (!userIds.isEmpty()) {
            assignPermissionSetGroupAsync(userIds);
        }
    }

    @future
    public static void assignPermissionSetGroupAsync(Set<Id> userIds) {
        List<PermissionSetGroup> psgList = [
            SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :DISTRIBUIDOR_ADMIN_PSG LIMIT 1
        ];

        if (psgList.isEmpty()) {
            return;
        }

        List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();
        for (Id userId : userIds) {
            assignmentsToInsert.add(new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetGroupId = psgList[0].Id
            ));
        }

        insert assignmentsToInsert;
    }
}
