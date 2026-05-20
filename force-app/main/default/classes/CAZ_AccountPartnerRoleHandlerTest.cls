@isTest
private class CAZ_AccountPartnerRoleHandlerTest {

    @isTest
    static void testCreatesThreeRolesOnEnablePartner() {
        Account acc = new Account(Name = 'Test Distribuidor Trigger');
        insert acc;

        System.Test.startTest();
        acc.IsPartner = true;
        update acc;
        System.Test.stopTest();

        List<UserRole> roles = [SELECT Id FROM UserRole WHERE PortalAccountId = :acc.Id];
        System.assertEquals(3, roles.size(), '3 roles should be created when IsPartner becomes true');
    }

    @isTest
    static void testDoesNotCreateRolesWhenIsPartnerStaysSame() {
        Account acc = new Account(Name = 'Test Account No Partner');
        insert acc;

        System.Test.startTest();
        acc.Description = 'Some update';
        update acc;
        System.Test.stopTest();

        List<UserRole> roles = [SELECT Id FROM UserRole WHERE PortalAccountId = :acc.Id];
        System.assertEquals(0, roles.size(), 'No roles should be created when IsPartner did not change');
    }
}
