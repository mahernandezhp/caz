public without sharing class CAZ_AccountContactRelationHandler {

    public static void manageAccountSharing(
        List<AccountContactRelation> records,
        Map<Id, AccountContactRelation> oldMap,
        System.TriggerOperation operationType
    ) {
        if (operationType == System.TriggerOperation.AFTER_INSERT) {
            createShares(records);
        } else if (operationType == System.TriggerOperation.AFTER_UPDATE) {
            handleUpdates(records, oldMap);
        } else if (operationType == System.TriggerOperation.AFTER_DELETE) {
            removeShares(records);
        }
    }

    private static void createShares(List<AccountContactRelation> acrs) {
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Set<Id>> contactToAccounts = new Map<Id, Set<Id>>();

        for (AccountContactRelation acr : acrs) {
            if (!acr.IsDirect && acr.IsActive) {
                contactIds.add(acr.ContactId);
                if (!contactToAccounts.containsKey(acr.ContactId)) {
                    contactToAccounts.put(acr.ContactId, new Set<Id>());
                }
                contactToAccounts.get(acr.ContactId).add(acr.AccountId);
            }
        }

        if (contactIds.isEmpty()) return;

        Map<Id, Id> contactToUserId = getPortalUsersByContact(contactIds);
        if (contactToUserId.isEmpty()) return;

        Set<String> existingKeys = getExistingShareKeys(contactToUserId.values(), contactToAccounts);

        List<AccountShare> sharesToInsert = new List<AccountShare>();
        for (Id contactId : contactToAccounts.keySet()) {
            Id userId = contactToUserId.get(contactId);
            if (userId == null) continue;
            for (Id accountId : contactToAccounts.get(contactId)) {
                if (!existingKeys.contains(userId + '-' + accountId)) {
                    sharesToInsert.add(new AccountShare(
                        AccountId = accountId,
                        UserOrGroupId = userId,
                        AccountAccessLevel = 'Edit',
                        OpportunityAccessLevel = 'None'
                    ));
                }
            }
        }

        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
        }
    }

    private static void handleUpdates(List<AccountContactRelation> acrs, Map<Id, AccountContactRelation> oldMap) {
        List<AccountContactRelation> activated = new List<AccountContactRelation>();
        List<AccountContactRelation> deactivated = new List<AccountContactRelation>();

        for (AccountContactRelation acr : acrs) {
            AccountContactRelation oldAcr = oldMap.get(acr.Id);
            if (!acr.IsDirect) {
                if (acr.IsActive && !oldAcr.IsActive) {
                    activated.add(acr);
                } else if (!acr.IsActive && oldAcr.IsActive) {
                    deactivated.add(acr);
                }
            }
        }

        if (!activated.isEmpty()) createShares(activated);
        if (!deactivated.isEmpty()) removeShares(deactivated);
    }

    private static void removeShares(List<AccountContactRelation> acrs) {
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Set<Id>> contactToAccounts = new Map<Id, Set<Id>>();

        for (AccountContactRelation acr : acrs) {
            if (!acr.IsDirect) {
                contactIds.add(acr.ContactId);
                if (!contactToAccounts.containsKey(acr.ContactId)) {
                    contactToAccounts.put(acr.ContactId, new Set<Id>());
                }
                contactToAccounts.get(acr.ContactId).add(acr.AccountId);
            }
        }

        if (contactIds.isEmpty()) return;

        Map<Id, Id> contactToUserId = getPortalUsersByContact(contactIds);
        if (contactToUserId.isEmpty()) return;

        Set<Id> userIds = new Set<Id>(contactToUserId.values());
        Set<Id> allAccountIds = new Set<Id>();
        for (Set<Id> ids : contactToAccounts.values()) {
            allAccountIds.addAll(ids);
        }

        List<AccountShare> toDelete = [
            SELECT Id, AccountId, UserOrGroupId
            FROM AccountShare
            WHERE UserOrGroupId IN :userIds
            AND AccountId IN :allAccountIds
            AND RowCause = 'Manual'
        ];

        if (!toDelete.isEmpty()) {
            Database.delete(toDelete, false);
        }
    }

    private static Map<Id, Id> getPortalUsersByContact(Set<Id> contactIds) {
        Map<Id, Id> result = new Map<Id, Id>();
        for (User u : [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId IN :contactIds AND IsActive = true AND IsPortalEnabled = true
        ]) {
            result.put(u.ContactId, u.Id);
        }
        return result;
    }

    private static Set<String> getExistingShareKeys(List<Id> userIds, Map<Id, Set<Id>> contactToAccounts) {
        Set<Id> allAccountIds = new Set<Id>();
        for (Set<Id> ids : contactToAccounts.values()) {
            allAccountIds.addAll(ids);
        }
        Set<String> keys = new Set<String>();
        for (AccountShare s : [
            SELECT AccountId, UserOrGroupId
            FROM AccountShare
            WHERE UserOrGroupId IN :userIds AND AccountId IN :allAccountIds
        ]) {
            keys.add(s.UserOrGroupId + '-' + s.AccountId);
        }
        return keys;
    }
}
