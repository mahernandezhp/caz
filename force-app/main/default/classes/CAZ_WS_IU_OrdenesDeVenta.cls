/*
 * Se recibe json para crear o actualizar registros de Contactos
 * iuContactos = insertar registros de Pedidos (Order)
 */

@RestResource(urlMapping='/v1/iuOrder/*') global class CAZ_WS_IU_OrdenesDeVenta {
    @HttpPost global static CAZ_WS_IU_OrdenesDeVentaRespuesta procesaPeticion() {
        system.debug('CAZ_WS_IU_OrdenesDeVenta ::: urlMapping: v1_iuOrder');

        // Se inician variables
        Boolean continuaValidacion = true;
        map<String, PricebookEntry> map_pbe = new map<String, PricebookEntry>();
        map<String, String> idExternoidCuenta = new map<String, String>();
        map<String, String> idExternoidPlanta = new map<String, String>();
        map<String, String> idExternoidProductos = new map<String, String>();
        list<CAZ_WS_IU_OrdenVentaCamposJSON> cjson = new list<CAZ_WS_IU_OrdenVentaCamposJSON>();
        CAZ_WS_IU_OrdenesDeVentaRespuesta resultado = new CAZ_WS_IU_OrdenesDeVentaRespuesta();
        list<Account> consultaCuentas = new list<Account>();
        list<CAZ_Planta__c> consultaPlanta = new list<CAZ_Planta__c>();
        list<Pricebook2> listaProductos = new list<Pricebook2>();
        list<Order> listaInsertar = new list<Order>();
        list<OrderItem> listaProductosPedido = new list<OrderItem>();
        list<String> listaProductosString = new list<String>();
        // ---
        String idExito = '';
        String idError = '';

        // Se recibe la información desde el servicio
        RestRequest request = RestContext.request;
        system.debug('CAZ_WS_IU_OrdenesDeVenta ::: request: '+ request.requestURI);

        RestResponse res = RestContext.response;
        String datoRecibido = request.requestBody.toString();

        // Se procesa la respuesta del servicio de Cruz Azul
        cjson = (list<CAZ_WS_IU_OrdenVentaCamposJSON>) JSON.deserialize(datoRecibido, list<CAZ_WS_IU_OrdenVentaCamposJSON>.class);
        system.debug('CAZ_WS_IU_OrdenVentaCamposJSON ::: cjson: ' + cjson.size());

        // Se consultan los Ids asociados a cada objeto
        for(CAZ_WS_IU_OrdenVentaCamposJSON forData : cjson) {
            system.debug('CAZ_WS_IU_OrdenesDeVenta ::: forData ::: Cuenta: ' + forData.CAZ_IdExternoA);
            system.debug('CAZ_WS_IU_OrdenesDeVenta ::: forData ::: Planta: ' + forData.CAZ_Planta);

            // Id externo de Cuenta
            if(!String.isBlank(forData.CAZ_IdExternoA) && !String.isEmpty(forData.CAZ_IdExternoA) && !idExternoidCuenta.containsKey(forData.CAZ_IdExternoA)) {
                idExternoidCuenta.put(forData.CAZ_IdExternoA, null);
            }

            // Id externo de Planta
            if(!String.isBlank(forData.CAZ_Planta) && !String.isEmpty(forData.CAZ_Planta) && !idExternoidPlanta.containsKey(forData.CAZ_Planta)) {
                idExternoidPlanta.put(forData.CAZ_Planta, null);
            }
        }
        system.debug('CAZ_WS_IU_OrdenesDeVenta ::: CAZ_IdExternoA: ' + idExternoidCuenta.keySet());
        system.debug('CAZ_WS_IU_OrdenesDeVenta ::: CAZ_Planta: ' + idExternoidPlanta.keySet());

        // Si se encontro como minimo un valor en el mapa, se consultara la Cuenta asociada
        if(!idExternoidCuenta.keySet().isEmpty()) {
            consultaCuentas = [select Id, ClaveJDE__c from Account where ClaveJDE__c IN : idExternoidCuenta.keySet()];
            system.debug('CAZ_WS_IU_OrdenesDeVenta ::: consultaCuentas: ' + consultaCuentas.size());

            // Se carga el mapa para agregar la informacion al nuevo registro
            if(!consultaCuentas.isEmpty()) {
                for(Account forData : consultaCuentas) {
                    idExternoidCuenta.put(forData.ClaveJDE__c, forData.Id);
                }
                system.debug('CAZ_WS_IU_OrdenesDeVenta ::: idExternoidCuenta: ' + idExternoidCuenta.size());
            }
        }
        else {
            resultado.Success = false;
            resultado.Mesagge = 'No se encontro la Cuenta asociada al Pedido.';
            resultado.Data = null;
            continuaValidacion = false;
        }

        // Se cargan los mapas con los Id externos recibidos
        if(continuaValidacion) {
            if(!idExternoidPlanta.keySet().isEmpty()) {
                consultaPlanta = [select Id, CAZ_Codigo__c from CAZ_Planta__c where CAZ_Codigo__c IN : idExternoidPlanta.keySet()];
                system.debug('CAZ_WS_IU_OrdenesDeVenta ::: consultaPlanta: ' + consultaPlanta.size());

                listaProductos = [select Id, CAZ_Codigo__c from Pricebook2 where CAZ_Codigo__c IN : idExternoidPlanta.keySet()];
                system.debug('CAZ_WS_IU_OrdenesDeVenta ::: consultaProductos: ' + listaProductos.size());

                // Se carga el mapa para agregar la informacion al nuevo registro
                if(!consultaPlanta.isEmpty()) {
                    for(CAZ_Planta__c forData : consultaPlanta) {
                        idExternoidPlanta.put(forData.CAZ_Codigo__c, forData.Id);
                    }
                }

                // Se carga el mapa para agregar la informacion al nuevo registro
                if(!listaProductos.isEmpty()) {
                    for(Pricebook2 forData : listaProductos) {
                        idExternoidProductos.put(forData.CAZ_Codigo__c, forData.Id);
                    }
                }
            }
            else {
                resultado.Success = false;
                resultado.Mesagge += 'No se encontro la Planta asociada al Pedido.';
                resultado.Data = null;
                continuaValidacion = false;
            }
        }

        // se agregan los valores buscados y se inserta el Pedido
        if(continuaValidacion) {
            for(CAZ_WS_IU_OrdenVentaCamposJSON forData : cjson) {
                Order tmp = new Order();
                tmp.CAZ_VieneDeWS__c = true;
                tmp.Status = forData.CAZ_Estado;
                tmp.Name = forData.CAZ_NombrePedido;
                tmp.CAZ_Numero_JDE__c = forData.CAZ_ClaveJDE;
                tmp.CAZ_CreadoPor__c = forData.CAZ_CreadoPor;
                tmp.CAZ_Producto_WS__c = forData.CAZ_Producto;
                tmp.CAZ_TotalAmount__c = forData.CAZ_MontoTotal;
                tmp.CAZ_Capacidad_de_retiro__c = forData.CAZ_CapacidadRetiro;
                tmp.AccountId = idExternoidCuenta.get(forData.CAZ_IdExternoA);
                tmp.CAZ_Planta__c = idExternoidPlanta.get(forData.CAZ_Planta);
                tmp.Pricebook2Id = idExternoidProductos.get(forData.CAZ_Planta);

                // --- Por definir
                //tmp. = forData.CAZ_TipoDeDocumento = '';
                //tmp. = forData.CAZ_UnidadDeNegocio = '';

                // Formato: YYYY-MM-DD
                try {
                    String [] seccion0 = forData.CAZ_FechaPedido.split('-');
                    tmp.EffectiveDate = Date.newInstance(Integer.valueOf(seccion0[0]), Integer.valueOf(seccion0[1]), Integer.valueOf(seccion0[2]));
                } catch(Exception e) { tmp.EffectiveDate = null; }

                // Formato: YYYY-MM-DD
                try {
                    String [] seccion1 = forData.CAZ_FechaCancelacionPedido.split('-');
                    tmp.CAZ_Cancelacion__c = Date.newInstance(Integer.valueOf(seccion1[0]), Integer.valueOf(seccion1[1]), Integer.valueOf(seccion1[2]));
                } catch(Exception e) { tmp.CAZ_Cancelacion__c = null; }

                // Formato: YYYY-MM-DDThh:mm:ssZ
                try {
                    String [] seccion2 = forData.CAZ_FechaDeCreacion.split('T');
                    String [] seccion3 = seccion2[0].split('-');
                    String [] seccion4 = seccion2[1].split(':');
                    tmp.CAZ_Fecha_de_creacion__c = DateTime.newInstance(Integer.valueOf(seccion3[0]), Integer.valueOf(seccion3[1]), Integer.valueOf(seccion3[2]), Integer.valueOf(seccion4[0]), Integer.valueOf(seccion4[1]), Integer.valueOf(seccion4[2].substring(0,seccion4[2].length()-1)));
                } catch(Exception e) { tmp.CAZ_Fecha_de_creacion__c = null; }

                // Formato: YYYY-MM-DDThh:mm:ssZ
                try {
                    String [] seccion5 = forData.CAZ_FechaUltimaModificacion.split('T');
                    String [] seccion6 = seccion5[0].split('-');
                    String [] seccion7 = seccion5[1].split(':');
                    tmp.CAZ_Fecha_UModificacion__c = DateTime.newInstance(Integer.valueOf(seccion6[0]), Integer.valueOf(seccion6[1]), Integer.valueOf(seccion6[2]), Integer.valueOf(seccion7[0]), Integer.valueOf(seccion7[1]), Integer.valueOf(seccion7[2].substring(0,seccion7[2].length()-1)));
                }
                catch(Exception e) { tmp.CAZ_Fecha_UModificacion__c = null; }

                listaProductosString.add(tmp.CAZ_Producto_WS__c);
                listaInsertar.add(tmp);
            }
            system.debug('CAZ_WS_IU_OrdenesDeVenta ::: listaInsertar: ' + listaInsertar.size());

            // Se insertan los registros
            // - false - insertara todos los registros posibles, embase a los datos minimos necesarios para crear un registro en Salesforce
            // - true  - si un registro como minimo no cumple con los datos minimos necesarios para crear un registro en Salesforce, toda la operacion se cancela
            // Cuando se usa "true", apex ya no itera - Database.UpsertResult -
            Database.UpsertResult[] resultsUpsert = Database.upsert(listaInsertar, Order.Fields.CAZ_Numero_JDE__c, false);
            for(Database.UpsertResult forData : resultsUpsert) {
                if(forData.isSuccess()) {
                    idExito = forData.getId();
                }
                else {
                    for(Database.Error forDataError : forData.getErrors()) {
                        idError += ' ::: ' + forDataError.getMessage();
                    }
                    continuaValidacion = false;
                }
            }
        }
        
        if(continuaValidacion) {
            list<PricebookEntry> pbe = [SELECT Id, UnitPrice, Product2Id, Product2.CAZ_Codigo_de_Producto__c, Pricebook2Id FROM PricebookEntry WHERE Pricebook2Id =: idExternoidProductos.values() and Product2.CAZ_Codigo_de_Producto__c IN : listaProductosString];
            for(PricebookEntry forData : pbe) {
                map_pbe.put(forData.Pricebook2Id, forData);
            }

            for(Order forData : listaInsertar) {
                OrderItem oli = new OrderItem();
                oli.OrderId = forData.Id;
                oli.PricebookEntryId = map_pbe.get(forData.Pricebook2Id).Id;
                oli.Product2Id = map_pbe.get(forData.Pricebook2Id).Product2Id;
                oli.UnitPrice = map_pbe.get(forData.Pricebook2Id).UnitPrice;
                oli.Quantity = 1;
                listaProductosPedido.add(oli);
            }

            if(!listaProductosPedido.isEmpty()) {
                insert listaProductosPedido;
            }
        }

        // Parte final de la insercion de Pedidos
        resultado.Success = continuaValidacion ? true : false;
        resultado.Mesagge = continuaValidacion ? 'Registro ' + idExito + ', generado correctamente en Salesforce.' : resultado.Mesagge + idError;
        resultado.Data = continuaValidacion ? idExito : null;
        system.debug('CAZ_WS_IU_Contactos ::: resultado: ' + resultado);

        return resultado;
    }
}

/*
JSON propuesto
[
   {
      "CAZ_ClaveJDE":"12345679",
      "CAZ_NombrePedido":"Pedido ejemplo",
      "CAZ_FechaPedido":"2026-05-31",
      "CAZ_FechaCancelacionPedido":"2026-05-31",
      "CAZ_FechaDeCreacion":"2026-05-31T23:59:59Z",
      "CAZ_FechaUltimaModificacion":"2026-05-31T23:59:59Z",
      "CAZ_CapacidadRetiro":1,
      "CAZ_Estado":"Draft",
      "CAZ_MontoTotal":1,
      "CAZ_Producto":"MTRO",
      "CAZ_CreadoPor":"porAlias",
      "CAZ_IdExternoA":"1003",
      "CAZ_Planta":"CCAA",
      "CAZ_UnidadDeNegocio":"",
      "CAZ_TipoDeDocumento":""
   }
]

SUCCESS
{
  "Success" : true,
  "Mesagge" : "Operacion correcta",
  "Data" : null
}

ERROR
{
  "Success" : false,
  "Mesagge" : "Descripcion del error",
  "Data" : null
}
*/