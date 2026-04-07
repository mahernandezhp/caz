public with sharing class CazNavigationController {
    
    @AuraEnabled(cacheable=true)
    public static List<NavigationMenuItem> getMenuItems(String menuName) {
        if (String.isBlank(menuName)) {
            return new List<NavigationMenuItem>();
        }
        
        // Obtenemos los ítems del menú publicado (Live)
        List<NavigationMenuItem> items = [
            SELECT Id, Label, Target, Type, DefaultListViewId 
            FROM NavigationMenuItem 
            WHERE NavigationLinkSet.MasterLabel = :menuName
            AND Status = 'Live'
            ORDER BY Position
        ];
        
        return items;
    }
}