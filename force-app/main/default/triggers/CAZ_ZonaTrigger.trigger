trigger CAZ_ZonaTrigger on CAZ_Zona__c (after insert) {
    CAZ_ZonaGroupHandler.createGroupsForNewZonas(Trigger.new);
}