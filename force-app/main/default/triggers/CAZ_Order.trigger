/*
 * Trigger que procesa la informacion cuando el registro es manual y no por WS
 * La Planta (CAZ_Planta__c - lookup) debe ser indicada en la creacion del registro
 * NOTA: SE DESACTIVO FLUJO "Asignacion de lista de precios del pedido - V1" DEBIDO A QUE TIENE LA LISTA FIJA
 */

trigger CAZ_Order on Order (before insert, before update) {
    if(trigger.isBefore) {
        if(trigger.isInsert || trigger.isUpdate) {
            if(system.label.CAZ_stopTriggerOrder == 'No') {
                list<String> idRegistros = new list<String>();

                for(Order forData : trigger.new) {
                    if(!String.isBlank(forData.CAZ_Planta__c) && !String.isEmpty(forData.CAZ_Planta__c) && !forData.CAZ_VieneDeWS__c) {
                        if(trigger.isInsert || (trigger.isUpdate && forData.CAZ_Planta__c != trigger.oldMap.get(forData.Id).CAZ_Planta__c)) {
                            idRegistros.add(forData.CAZ_Planta__c);
                            system.debug('Trigger - Order - idRegistros: ' + idRegistros.size());
                        }
                    }
                }

                if(!idRegistros.isEmpty()) {
                    system.debug('Trigger - Order - Metodo : buscaLista');
                    CAZ_OrderListaDePrecios.buscaLista(trigger.new, idRegistros);
                }
            }
        }
    }
}