public without sharing class CAZ_ZonaSharingHandler {

    public static Set<Id> extractAccountIds(List<CAZ_Cuenta_y_Zona__c> records) {
        Set<Id> accountIds = new Set<Id>();
        for (CAZ_Cuenta_y_Zona__c rec : records) {
            if (rec.CAZ_Cuenta__c != null) {
                accountIds.add(rec.CAZ_Cuenta__c);
            }
        }
        return accountIds;
    }

    public static void reconcileAccountsAsync(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }

        Set<Id> userIds = new Set<Id>();
        for (User u : [
            SELECT Id
            FROM User
            WHERE ContactId != null AND Contact.AccountId IN :accountIds AND IsActive = true
        ]) {
            userIds.add(u.Id);
        }

        if (!userIds.isEmpty()) {
            reconcileUserZonaGroupsAsync(userIds);
        }
    }

    public static void reconcileUsers(List<User> users) {
        Set<Id> userIds = new Set<Id>();
        for (User u : users) {
            if (u.ContactId != null) {
                userIds.add(u.Id);
            }
        }

        if (!userIds.isEmpty()) {
            reconcileUserZonaGroupsAsync(userIds);
        }
    }

    @future
    public static void reconcileUserZonaGroupsAsync(Set<Id> userIds) {
        List<CAZ_Zona__c> allZonas = [
            SELECT Id, CAZ_GrupoCompartidoId__c
            FROM CAZ_Zona__c
            WHERE CAZ_GrupoCompartidoId__c != null
        ];

        if (allZonas.isEmpty()) {
            return;
        }

        Set<Id> allZonaGroupIds = new Set<Id>();
        for (CAZ_Zona__c zona : allZonas) {
            allZonaGroupIds.add((Id) zona.CAZ_GrupoCompartidoId__c);
        }

        Map<Id, Id> accountIdByUserId = new Map<Id, Id>();
        for (User u : [
            SELECT Id, Contact.AccountId
            FROM User
            WHERE Id IN :userIds AND ContactId != null
        ]) {
            if (u.Contact.AccountId != null) {
                accountIdByUserId.put(u.Id, u.Contact.AccountId);
            }
        }

        if (accountIdByUserId.isEmpty()) {
            return;
        }

        Set<Id> accountIds = new Set<Id>(accountIdByUserId.values());

        Map<Id, Set<Id>> groupIdsByAccountId = new Map<Id, Set<Id>>();
        for (CAZ_Cuenta_y_Zona__c link : [
            SELECT CAZ_Cuenta__c, CAZ_Zona__r.CAZ_GrupoCompartidoId__c
            FROM CAZ_Cuenta_y_Zona__c
            WHERE CAZ_Cuenta__c IN :accountIds AND CAZ_Zona__r.CAZ_GrupoCompartidoId__c != null
        ]) {
            Id groupId = (Id) link.CAZ_Zona__r.CAZ_GrupoCompartidoId__c;
            if (!groupIdsByAccountId.containsKey(link.CAZ_Cuenta__c)) {
                groupIdsByAccountId.put(link.CAZ_Cuenta__c, new Set<Id>());
            }
            groupIdsByAccountId.get(link.CAZ_Cuenta__c).add(groupId);
        }

        Map<Id, Map<Id, Id>> currentMembershipByUser = new Map<Id, Map<Id, Id>>();
        for (GroupMember gm : [
            SELECT Id, GroupId, UserOrGroupId
            FROM GroupMember
            WHERE UserOrGroupId IN :userIds AND GroupId IN :allZonaGroupIds
        ]) {
            if (!currentMembershipByUser.containsKey(gm.UserOrGroupId)) {
                currentMembershipByUser.put(gm.UserOrGroupId, new Map<Id, Id>());
            }
            currentMembershipByUser.get(gm.UserOrGroupId).put(gm.GroupId, gm.Id);
        }

        List<GroupMember> membersToInsert = new List<GroupMember>();
        List<Id> membersToDeleteIds = new List<Id>();

        for (Id userId : accountIdByUserId.keySet()) {
            Set<Id> desiredGroupIds = groupIdsByAccountId.containsKey(accountIdByUserId.get(userId))
                ? groupIdsByAccountId.get(accountIdByUserId.get(userId))
                : new Set<Id>();
            Map<Id, Id> currentMembership = currentMembershipByUser.containsKey(userId)
                ? currentMembershipByUser.get(userId)
                : new Map<Id, Id>();

            for (Id groupId : desiredGroupIds) {
                if (!currentMembership.containsKey(groupId)) {
                    membersToInsert.add(new GroupMember(GroupId = groupId, UserOrGroupId = userId));
                }
            }

            for (Id groupId : currentMembership.keySet()) {
                if (!desiredGroupIds.contains(groupId)) {
                    membersToDeleteIds.add(currentMembership.get(groupId));
                }
            }
        }

        if (!membersToInsert.isEmpty()) {
            insert membersToInsert;
        }
        if (!membersToDeleteIds.isEmpty()) {
            delete [SELECT Id FROM GroupMember WHERE Id IN :membersToDeleteIds];
        }
    }
}
