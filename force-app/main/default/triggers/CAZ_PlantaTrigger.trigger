trigger CAZ_PlantaTrigger on CAZ_Planta__c (after insert, after update) {
    CAZ_PlantaShareHandler.syncSharesForChangedPlantas(
        Trigger.new,
        Trigger.isUpdate ? Trigger.oldMap : null
    );
}