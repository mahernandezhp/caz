@isTest
private class CAZ_CuentaZonaValidationHandlerTest {

    @isTest
    static void testBlocksDuplicateAccountZonaRelationship() {
        Account acc = new Account(Name = 'Test Duplicate Validation');
        insert acc;

        CAZ_Zona__c zona = new CAZ_Zona__c(Name = 'Zona Duplicate Test');
        insert zona;

        CAZ_Cuenta_y_Zona__c link1 = new CAZ_Cuenta_y_Zona__c(
            CAZ_Cuenta__c = acc.Id,
            CAZ_Zona__c = zona.Id
        );
        insert link1;

        CAZ_Cuenta_y_Zona__c link2 = new CAZ_Cuenta_y_Zona__c(
            CAZ_Cuenta__c = acc.Id,
            CAZ_Zona__c = zona.Id
        );

        System.Test.startTest();
        try {
            insert link2;
            System.assert(false, 'Debio lanzar excepcion por duplicado');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('ya está relacionada con esta Zona'),
                'El mensaje de error debe indicar que la relacion ya existe: ' + e.getMessage()
            );
        }
        System.Test.stopTest();
    }

    @isTest
    static void testAllowsDifferentZonaForSameAccount() {
        Account acc = new Account(Name = 'Test Different Zonas');
        insert acc;

        CAZ_Zona__c zona1 = new CAZ_Zona__c(Name = 'Zona A');
        CAZ_Zona__c zona2 = new CAZ_Zona__c(Name = 'Zona B');
        insert new List<CAZ_Zona__c>{ zona1, zona2 };

        insert new CAZ_Cuenta_y_Zona__c(CAZ_Cuenta__c = acc.Id, CAZ_Zona__c = zona1.Id);

        System.Test.startTest();
        CAZ_Cuenta_y_Zona__c link2 = new CAZ_Cuenta_y_Zona__c(
            CAZ_Cuenta__c = acc.Id,
            CAZ_Zona__c = zona2.Id
        );
        insert link2;
        System.Test.stopTest();

        System.assertNotEquals(null, link2.Id, 'Debe permitir relacionar la misma cuenta a una zona diferente');
    }

    @isTest
    static void testBlocksDuplicatesWithinSameBatch() {
        Account acc = new Account(Name = 'Test Batch Duplicate');
        insert acc;

        CAZ_Zona__c zona = new CAZ_Zona__c(Name = 'Zona Batch Test');
        insert zona;

        List<CAZ_Cuenta_y_Zona__c> links = new List<CAZ_Cuenta_y_Zona__c>{
            new CAZ_Cuenta_y_Zona__c(CAZ_Cuenta__c = acc.Id, CAZ_Zona__c = zona.Id),
            new CAZ_Cuenta_y_Zona__c(CAZ_Cuenta__c = acc.Id, CAZ_Zona__c = zona.Id)
        };

        System.Test.startTest();
        try {
            insert links;
            System.assert(false, 'Debio lanzar excepcion por duplicados en el mismo lote');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('relación'),
                'El mensaje debe indicar duplicado: ' + e.getMessage()
            );
        }
        System.Test.stopTest();
    }
}
