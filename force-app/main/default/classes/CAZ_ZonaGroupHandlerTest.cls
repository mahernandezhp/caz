@isTest
private class CAZ_ZonaGroupHandlerTest {

    @isTest
    static void testCreatesGroupForNewZona() {
        CAZ_Zona__c zona = new CAZ_Zona__c(Name = 'Zona Test Group');

        System.Test.startTest();
        insert zona;
        System.Test.stopTest();

        CAZ_Zona__c updatedZona = [
            SELECT Id, Name, CAZ_GrupoCompartidoId__c
            FROM CAZ_Zona__c
            WHERE Id = :zona.Id
        ];
        System.assertNotEquals(
            null,
            updatedZona.CAZ_GrupoCompartidoId__c,
            'Debe crearse un grupo publico asociado a la nueva zona'
        );

        Group g = [SELECT Id, Name, Type FROM Group WHERE Id = :updatedZona.CAZ_GrupoCompartidoId__c];
        System.assertEquals('CAZ Zona ' + updatedZona.Name, g.Name);
        System.assertEquals('Regular', g.Type);
    }
}
