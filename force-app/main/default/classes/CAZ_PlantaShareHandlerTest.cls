@isTest
private class CAZ_PlantaShareHandlerTest {

    @isTest
    static void testCreatesShareForPlantaWithZonaGroup() {
        CAZ_Zona__c zona = new CAZ_Zona__c(Name = 'Zona Test Share');
        insert zona;

        Group g = new Group(Name = 'CAZ Zona Test Share', Type = 'Regular');
        insert g;
        zona.CAZ_GrupoCompartidoId__c = g.Id;
        update zona;

        CAZ_Planta__c planta = new CAZ_Planta__c(Name = 'Planta Test Share', CAZ_Zona__c = zona.Id);

        System.Test.startTest();
        insert planta;
        System.Test.stopTest();

        List<CAZ_Planta__Share> shares = [
            SELECT Id, UserOrGroupId, AccessLevel
            FROM CAZ_Planta__Share
            WHERE ParentId = :planta.Id AND RowCause = 'Manual'
        ];
        System.assertEquals(1, shares.size(), 'Debe crearse un registro de sharing hacia el grupo de la zona');
        System.assertEquals(g.Id, shares[0].UserOrGroupId);
        System.assertEquals('Read', shares[0].AccessLevel);
    }

    @isTest
    static void testUpdatesShareWhenZonaChanges() {
        CAZ_Zona__c zonaA = new CAZ_Zona__c(Name = 'Zona Test Share A');
        insert zonaA;
        Group groupA = new Group(Name = 'CAZ Zona Test Share A', Type = 'Regular');
        insert groupA;
        zonaA.CAZ_GrupoCompartidoId__c = groupA.Id;
        update zonaA;

        CAZ_Zona__c zonaB = new CAZ_Zona__c(Name = 'Zona Test Share B');
        insert zonaB;
        Group groupB = new Group(Name = 'CAZ Zona Test Share B', Type = 'Regular');
        insert groupB;
        zonaB.CAZ_GrupoCompartidoId__c = groupB.Id;
        update zonaB;

        CAZ_Planta__c planta = new CAZ_Planta__c(Name = 'Planta Test Cambio Zona', CAZ_Zona__c = zonaA.Id);
        insert planta;

        System.Test.startTest();
        planta.CAZ_Zona__c = zonaB.Id;
        update planta;
        System.Test.stopTest();

        List<CAZ_Planta__Share> shares = [
            SELECT Id, UserOrGroupId
            FROM CAZ_Planta__Share
            WHERE ParentId = :planta.Id AND RowCause = 'Manual'
        ];
        System.assertEquals(1, shares.size(), 'Debe existir un unico registro de sharing tras el cambio de zona');
        System.assertEquals(groupB.Id, shares[0].UserOrGroupId, 'El sharing debe apuntar al grupo de la nueva zona');
    }
}
