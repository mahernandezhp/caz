/**
 * CAZ_SolicitudCreditoTriggerHandler
 * ---------------------
 * Handler para el trigger de CAZ_SolicitudCredito__c.
 * Auto-asigna la cuenta del distribuidor (CAZ_Cuenta__c) desde el
 * AccountId del usuario de comunidad que crea el registro.
 */
public with sharing class CAZ_SolicitudCreditoTriggerHandler {

    /**
     * Punto de entrada desde el trigger before insert.
     * Auto-asigna CAZ_Cuenta__c del AccountId del usuario actual.
     */
    public static void handleBeforeInsert(List<CAZ_SolicitudCredito__c> newRecords) {
        Id userAccountId = null;
        List<User> currentUsers = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (!currentUsers.isEmpty() && currentUsers[0].AccountId != null) {
            userAccountId = currentUsers[0].AccountId;
        }

        if (userAccountId != null) {
            for (CAZ_SolicitudCredito__c sol : newRecords) {
                if (sol.CAZ_Cuenta__c == null) {
                    sol.CAZ_Cuenta__c = userAccountId;
                }
            }
        }
    }
}