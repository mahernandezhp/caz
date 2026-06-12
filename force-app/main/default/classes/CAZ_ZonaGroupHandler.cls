public without sharing class CAZ_ZonaGroupHandler {

    public static void createGroupsForNewZonas(List<CAZ_Zona__c> newZonas) {
        Set<Id> zonaIds = new Set<Id>();
        for (CAZ_Zona__c zona : newZonas) {
            if (String.isBlank(zona.CAZ_GrupoCompartidoId__c)) {
                zonaIds.add(zona.Id);
            }
        }

        if (!zonaIds.isEmpty()) {
            createGroupsAsync(zonaIds);
        }
    }

    @future
    public static void createGroupsAsync(Set<Id> zonaIds) {
        List<CAZ_Zona__c> zonas = [
            SELECT Id, Name, CAZ_GrupoCompartidoId__c
            FROM CAZ_Zona__c
            WHERE Id IN :zonaIds AND CAZ_GrupoCompartidoId__c = null
        ];

        if (zonas.isEmpty()) {
            return;
        }

        List<Group> groupsToInsert = new List<Group>();
        for (CAZ_Zona__c zona : zonas) {
            groupsToInsert.add(new Group(
                Name = 'CAZ Zona ' + zona.Name,
                Type = 'Regular'
            ));
        }
        insert groupsToInsert;

        for (Integer i = 0; i < zonas.size(); i++) {
            zonas[i].CAZ_GrupoCompartidoId__c = groupsToInsert[i].Id;
        }
        update zonas;
    }
}
