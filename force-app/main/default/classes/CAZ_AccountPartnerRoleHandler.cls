public with sharing class CAZ_AccountPartnerRoleHandler {

    private static final Integer ROLES_PER_ACCOUNT = 3;

    public static void createPartnerRoles(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Set<Id> accountsToProcess = new Set<Id>();
        for (Account acc : newAccounts) {
            Account oldAcc = oldMap.get(acc.Id);
            if (acc.IsPartner && !oldAcc.IsPartner) {
                accountsToProcess.add(acc.Id);
            }
        }
        if (!accountsToProcess.isEmpty()) {
            createPartnerRolesAsync(accountsToProcess);
        }
    }

    @future
    public static void createPartnerRolesAsync(Set<Id> accountIds) {
        Map<Id, Integer> existingByAccount = new Map<Id, Integer>();
        for (Id aid : accountIds) existingByAccount.put(aid, 0);
        for (UserRole r : [SELECT PortalAccountId FROM UserRole WHERE PortalAccountId IN :accountIds]) {
            existingByAccount.put(r.PortalAccountId, existingByAccount.get(r.PortalAccountId) + 1);
        }

        List<UserRole> rolesToInsert = new List<UserRole>();
        for (Id aid : accountIds) {
            Integer toCreate = ROLES_PER_ACCOUNT - existingByAccount.get(aid);
            for (Integer i = 0; i < toCreate; i++) {
                rolesToInsert.add(new UserRole(PortalType = 'Partner', PortalAccountId = aid));
            }
        }
        if (!rolesToInsert.isEmpty()) insert rolesToInsert;
    }
}
