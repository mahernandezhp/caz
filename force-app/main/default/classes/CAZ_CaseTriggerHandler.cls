/**
 * CAZ_CaseTriggerHandler
 * ---------------------
 * Handler para el trigger de Case.
 */
public with sharing class CAZ_CaseTriggerHandler {

    /**
     * Punto de entrada desde el trigger before update.
     */
    public static void handleBeforeUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
        // Reservado para futura lógica de soporte o casos estándar
    }

    /**
     * Determina si el usuario actual tiene perfil de System Administrator.
     */
    @TestVisible
    private static Boolean isSystemAdminUser() {
        String profileName = [
            SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1
        ].Name;

        return profileName == 'System Administrator'
            || profileName == 'Administrador del sistema';
    }
}