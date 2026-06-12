@isTest
private class CAZ_UserPermissionSetHandlerTest {

    @isTest
    static void testAssignsPermissionSetGroupForDistribuidorAdminProfile() {
        Profile distribuidorAdminProfile = [
            SELECT Id FROM Profile WHERE Name = 'Portal Distribuidor - Partner Community User' LIMIT 1
        ];

        Account acc = new Account(Name = 'Test Distribuidor PSG');
        insert acc;
        acc.IsPartner = true;
        update acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'PSG User',
            AccountId = acc.Id,
            Email = 'test.psg.user@example.com'
        );
        insert con;

        String uniqueName = 'testpsguser' + DateTime.now().getTime();

        User u = new User(
            FirstName = 'Test',
            LastName = 'PSG User',
            Alias = 'tpsgu',
            Email = 'test.psg.user@example.com',
            Username = uniqueName + '@example.com.test',
            CommunityNickname = uniqueName,
            ContactId = con.Id,
            ProfileId = distribuidorAdminProfile.Id,
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'es_MX',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'es'
        );

        System.Test.startTest();
        insert u;
        System.Test.stopTest();

        PermissionSetGroup psg = [
            SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'CAZ_Portal_Distribuidor_Admin' LIMIT 1
        ];

        List<PermissionSetAssignment> assignments = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :u.Id AND PermissionSetGroupId = :psg.Id
        ];
        System.assertEquals(
            1,
            assignments.size(),
            'Debe asignarse el PSG CAZ Portal Distribuidor Admin al crear un usuario con el perfil Distribuidor'
        );
    }

    @isTest
    static void testDoesNotAssignPermissionSetGroupForOtherProfiles() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        String uniqueName = 'teststduser' + DateTime.now().getTime();

        User u = new User(
            FirstName = 'Test',
            LastName = 'Standard User',
            Alias = 'tstdu',
            Email = 'test.std.user@example.com',
            Username = uniqueName + '@example.com.test',
            CommunityNickname = uniqueName,
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'es_MX',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'es'
        );

        System.Test.startTest();
        insert u;
        System.Test.stopTest();

        PermissionSetGroup psg = [
            SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'CAZ_Portal_Distribuidor_Admin' LIMIT 1
        ];

        List<PermissionSetAssignment> assignments = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :u.Id AND PermissionSetGroupId = :psg.Id
        ];
        System.assertEquals(0, assignments.size(), 'No debe asignarse el PSG a usuarios internos');
    }
}
