public without sharing class CAZ_PlantaShareHandler {

    private static final String SHARE_ROW_CAUSE = 'Manual';

    public static void syncSharesForChangedPlantas(List<CAZ_Planta__c> plantas, Map<Id, CAZ_Planta__c> oldMap) {
        Set<Id> plantaIds = new Set<Id>();
        for (CAZ_Planta__c planta : plantas) {
            Boolean zonaChanged = oldMap == null
                || planta.CAZ_Zona__c != oldMap.get(planta.Id).CAZ_Zona__c;
            if (zonaChanged) {
                plantaIds.add(planta.Id);
            }
        }

        if (!plantaIds.isEmpty()) {
            syncSharesForPlantas(plantaIds);
        }
    }

    public static void syncSharesForPlantas(Set<Id> plantaIds) {
        List<CAZ_Planta__c> plantas = [
            SELECT Id, CAZ_Zona__r.CAZ_GrupoCompartidoId__c
            FROM CAZ_Planta__c
            WHERE Id IN :plantaIds
        ];

        List<CAZ_Planta__Share> existingShares = [
            SELECT Id
            FROM CAZ_Planta__Share
            WHERE ParentId IN :plantaIds AND RowCause = :SHARE_ROW_CAUSE
        ];
        if (!existingShares.isEmpty()) {
            delete existingShares;
        }

        List<CAZ_Planta__Share> sharesToInsert = new List<CAZ_Planta__Share>();
        for (CAZ_Planta__c planta : plantas) {
            String groupId = planta.CAZ_Zona__r != null ? planta.CAZ_Zona__r.CAZ_GrupoCompartidoId__c : null;
            if (String.isNotBlank(groupId)) {
                sharesToInsert.add(new CAZ_Planta__Share(
                    ParentId = planta.Id,
                    UserOrGroupId = groupId,
                    AccessLevel = 'Read',
                    RowCause = SHARE_ROW_CAUSE
                ));
            }
        }

        if (!sharesToInsert.isEmpty()) {
            insert sharesToInsert;
        }
    }

    public static void shareExistingPlantasForZonas(Set<Id> zonaIds) {
        Set<Id> plantaIds = new Set<Id>();
        for (CAZ_Planta__c planta : [SELECT Id FROM CAZ_Planta__c WHERE CAZ_Zona__c IN :zonaIds]) {
            plantaIds.add(planta.Id);
        }

        if (!plantaIds.isEmpty()) {
            syncSharesForPlantas(plantaIds);
        }
    }
}
