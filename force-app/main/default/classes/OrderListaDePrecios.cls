public class OrderListaDePrecios {
    public static void buscaLista(list<Order> triggerNew, list<String> idPlantas) {
        // Definicion de variables
        map<String, String> mapaPlantas = new map<String, String>();
        map<String, String> mapaListaPrecios = new map<String, String>();

        // Se consultan los nombres de la(s) Plantas para buscar el de la Lista de precios
        // select Id, Name from Planta__c where Id IN : idPlantas
        //for(Planta__c forData : Database.query(system.label.CAZ_consultaPlantas)) {
            //mapaPlantas.put(forData.Id, forData.Name);
        //}

        // Se buscan los nombres de las Listas de precios
        for(Pricebook2 forData : [select Id, Name from Pricebook2 where IsActive = true and Name IN : mapaPlantas.values()]) {
            if(!mapaListaPrecios.containsKey(forData.Name)) {
                mapaListaPrecios.put(forData.Name, forData.Id);
            }
        }

        // Se asigna el valor de la Lista de precios en la Orden
        for(Order forData : triggerNew) {
            forData.Pricebook2Id = mapaListaPrecios.get(mapaPlantas.get(forData.CAZ_Planta__c));
        }
    }
}