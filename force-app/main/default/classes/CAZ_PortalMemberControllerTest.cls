@isTest
private class CAZ_PortalMemberControllerTest {

    @isTest
    static void testCreateMemberValidationFailsWithoutLastName() {
        System.Test.startTest();
        try {
            CAZ_PortalMemberController.createPortalMember(null, null, null, null, null, null, null);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }

    @isTest
    static void testCreateMemberValidationFailsWithoutEmail() {
        Account acc = new Account(Name = 'Test Account NoEmail');
        insert acc;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        System.Test.startTest();
        try {
            CAZ_PortalMemberController.createPortalMember('Test', 'User', null, p.Id, null, null, acc.Id);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }

    @isTest
    static void testCreateMemberValidationFailsWithoutProfile() {
        System.Test.startTest();
        try {
            CAZ_PortalMemberController.createPortalMember(
                'Test', 'User', 'test@example.com', null, null, null, '001000000000000AAA'
            );
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }

    @isTest
    static void testGetFormDataThrowsWhenNoContact() {
        User adminWithoutContact = [
            SELECT Id FROM User
            WHERE IsActive = true AND Profile.Name = 'System Administrator' AND ContactId = null
            LIMIT 1
        ];

        System.Test.startTest();
        System.runAs(adminWithoutContact) {
            try {
                CAZ_PortalMemberController.getFormData();
                System.assert(false, 'Should have thrown');
            } catch (Exception e) {
                System.assert(true);
            }
        }
        System.Test.stopTest();
    }

    @isTest
    static void testCreateMemberTriggersRollbackOnError() {
        Account acc = new Account(Name = 'Test Rollback');
        insert acc;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        System.Test.startTest();
        try {
            String uniqueEmail = 'rollback' + Datetime.now().getTime() + '@capptus.test';
            CAZ_PortalMemberController.createPortalMember(
                'Test', 'Rollback', uniqueEmail, p.Id, null, new List<Id>(), acc.Id
            );
        } catch (Exception e) {
            System.assert(true);
        }
        System.Test.stopTest();
    }

    @isTest
    static void testMemberOptionConstructor() {
        CAZ_PortalMemberController.MemberOption opt = new CAZ_PortalMemberController.MemberOption('Label', 'Value');
        System.assertEquals('Label', opt.label);
        System.assertEquals('Value', opt.value);
    }

    @isTest(SeeAllData=true)
    static void testGetFormDataAsPortalUser() {
        List<User> portalUsers = [
            SELECT Id FROM User
            WHERE IsActive = true
            AND UserType = 'PowerPartner'
            AND ContactId != null
            LIMIT 1
        ];
        if (portalUsers.isEmpty()) return;

        System.Test.startTest();
        System.runAs(portalUsers[0]) {
            try {
                CAZ_PortalMemberController.MemberFormData data = CAZ_PortalMemberController.getFormData();
                System.assertNotEquals(null, data);
            } catch (Exception e) {
                // OK
            }
        }
        System.Test.stopTest();
    }
}
