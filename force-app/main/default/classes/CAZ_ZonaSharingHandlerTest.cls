@isTest
private class CAZ_ZonaSharingHandlerTest {

    @isTest
    static void testAddsUserToZonaGroupWhenAccountLinkedToZona() {
        CAZ_Zona__c zona = new CAZ_Zona__c(Name = 'Zona Test Reconcile');
        insert zona;
        Group g = new Group(Name = 'CAZ Zona Test Reconcile', Type = 'Regular');
        insert g;
        zona.CAZ_GrupoCompartidoId__c = g.Id;
        update zona;

        Account acc = new Account(Name = 'Test Account Reconcile');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Reconcile User',
            AccountId = acc.Id,
            Email = 'test.reconcile.user@example.com'
        );
        insert con;

        Profile distribuidorProfile = [
            SELECT Id FROM Profile WHERE Name = 'Portal Distribuidor - Partner Community User' LIMIT 1
        ];

        String uniqueName = 'testreconcile' + DateTime.now().getTime();
        User u = new User(
            FirstName = 'Test',
            LastName = 'Reconcile User',
            Alias = 'trecu',
            Email = 'test.reconcile.user@example.com',
            Username = uniqueName + '@example.com.test',
            CommunityNickname = uniqueName,
            ContactId = con.Id,
            ProfileId = distribuidorProfile.Id,
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'es_MX',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'es'
        );

        CAZ_Cuenta_y_Zona__c link = new CAZ_Cuenta_y_Zona__c(
            CAZ_Cuenta__c = acc.Id,
            CAZ_Zona__c = zona.Id
        );

        System.Test.startTest();
        insert u;
        insert link;
        System.Test.stopTest();

        List<GroupMember> members = [
            SELECT Id FROM GroupMember WHERE GroupId = :g.Id AND UserOrGroupId = :u.Id
        ];
        System.assertEquals(
            1,
            members.size(),
            'El usuario portal debe agregarse al grupo de la zona ligada a su cuenta'
        );
    }

    @isTest
    static void testRemovesUserFromZonaGroupWhenLinkIsDeleted() {
        CAZ_Zona__c zona = new CAZ_Zona__c(Name = 'Zona Test Reconcile Remove');
        insert zona;
        Group g = new Group(Name = 'CAZ Zona Test Reconcile Remove', Type = 'Regular');
        insert g;
        zona.CAZ_GrupoCompartidoId__c = g.Id;
        update zona;

        Account acc = new Account(Name = 'Test Account Reconcile Remove');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Reconcile Remove User',
            AccountId = acc.Id,
            Email = 'test.reconcile.remove.user@example.com'
        );
        insert con;

        Profile distribuidorProfile = [
            SELECT Id FROM Profile WHERE Name = 'Portal Distribuidor - Partner Community User' LIMIT 1
        ];

        String uniqueName = 'testreconcileremove' + DateTime.now().getTime();
        User u = new User(
            FirstName = 'Test',
            LastName = 'Reconcile Remove User',
            Alias = 'trecru',
            Email = 'test.reconcile.remove.user@example.com',
            Username = uniqueName + '@example.com.test',
            CommunityNickname = uniqueName,
            ContactId = con.Id,
            ProfileId = distribuidorProfile.Id,
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'es_MX',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'es'
        );

        CAZ_Cuenta_y_Zona__c link = new CAZ_Cuenta_y_Zona__c(
            CAZ_Cuenta__c = acc.Id,
            CAZ_Zona__c = zona.Id
        );

        System.Test.startTest();
        insert u;
        insert link;
        delete link;
        System.Test.stopTest();

        List<GroupMember> members = [
            SELECT Id FROM GroupMember WHERE GroupId = :g.Id AND UserOrGroupId = :u.Id
        ];
        System.assertEquals(
            0,
            members.size(),
            'El usuario debe salir del grupo de la zona cuando se elimina la relacion cuenta-zona'
        );
    }
}
