// 1. Crear grupos para zonas existentes que no tengan CAZ_GrupoCompartidoId__c
List<CAZ_Zona__c> zonasSinGrupo = [
    SELECT Id, Name, CAZ_GrupoCompartidoId__c
    FROM CAZ_Zona__c
    WHERE CAZ_GrupoCompartidoId__c = null
];
System.debug('Zonas sin grupo: ' + zonasSinGrupo.size());

if (!zonasSinGrupo.isEmpty()) {
    List<Group> groupsToInsert = new List<Group>();
    for (CAZ_Zona__c zona : zonasSinGrupo) {
        groupsToInsert.add(new Group(Name = 'CAZ Zona ' + zona.Name, Type = 'Regular'));
    }
    insert groupsToInsert;

    for (Integer i = 0; i < zonasSinGrupo.size(); i++) {
        zonasSinGrupo[i].CAZ_GrupoCompartidoId__c = groupsToInsert[i].Id;
    }
    update zonasSinGrupo;
    System.debug('Grupos creados: ' + groupsToInsert.size());
}

// 2. Compartir todas las Plantas existentes con el grupo de su Zona
Set<Id> todasLasPlantas = new Set<Id>();
for (CAZ_Planta__c planta : [SELECT Id FROM CAZ_Planta__c WHERE CAZ_Zona__c != null]) {
    todasLasPlantas.add(planta.Id);
}
System.debug('Plantas con zona a compartir: ' + todasLasPlantas.size());

if (!todasLasPlantas.isEmpty()) {
    CAZ_PlantaShareHandler.syncSharesForPlantas(todasLasPlantas);
}

// 3. Reconciliar membresia de grupos para todos los usuarios portal existentes
Set<Id> userIds = new Set<Id>();
for (User u : [SELECT Id FROM User WHERE ContactId != null AND IsActive = true]) {
    userIds.add(u.Id);
}
System.debug('Usuarios portal a reconciliar: ' + userIds.size());

if (!userIds.isEmpty()) {
    CAZ_ZonaSharingHandler.reconcileUserZonaGroupsAsync(userIds);
}
