/*
 * Se recibe json para crear o actualizar registros de Contactos
 * iuContactos = insertar / actualizar Contactos
 * 
 * Campos en upsert - CAZ_IdExterno__c -
 */

/*@RestResource(urlMapping='/v1/iuContactos/*')*/ global class CAZ_WS_IU_Contactos {
    //@HttpPost global static CAZ_WS_IU_ContactosRespuesta procesaPeticion() {
    /*@HttpPost */global static void procesaPeticion() {
        system.debug('CAZ_WS_IU_Contactos ::: urlMapping: v1_iuContactos');

        // Se inician variables
        Boolean continuaValidacion = true;
        map<String, String> idExternoidCuenta = new map<String, String>();
        list<CAZ_WS_IU_ContactosCamposJSON> cjson = new list<CAZ_WS_IU_ContactosCamposJSON>();
        CAZ_WS_IU_ContactosRespuesta resultado = new CAZ_WS_IU_ContactosRespuesta();
        list<Account> consultaCuentas = new list<Account>();
        list<Contact> listaInsertar = new list<Contact>();
        // ---
        String idExito = '';
        String idError = '';
        String datoRecibido = '[{"CAZ_Cuenta":"A001","CAZ_Nombre": "Nombre0","CAZ_SegundoNombre": "Nombre1","CAZ_Apellidos":"Apellidos","CAZ_Email":"correo2@correo.correo","CAZ_Telefono":"5500000002","CAZ_Factura":false,"CAZ_ClaveJDE":"C100","CAZ_IdExterno":"C000"}]';

        // Se procesa la respuesta del servicio de Cruz Azul
        cjson = (list<CAZ_WS_IU_ContactosCamposJSON>) JSON.deserialize(datoRecibido, list<CAZ_WS_IU_ContactosCamposJSON>.class);
        system.debug('CAZ_WS_IU_Contactos ::: cjson: ' + cjson.size());

        // Se consulta la Cuenta asociada en base al valor del campo "Cuenta" del JSON
        for(CAZ_WS_IU_ContactosCamposJSON forData : cjson) {
            system.debug('CAZ_WS_IU_Contactos ::: forData: ' + forData);
            if(!String.isBlank(forData.CAZ_Cuenta) && !String.isEmpty(forData.CAZ_Cuenta) && !idExternoidCuenta.containsKey(forData.CAZ_Cuenta)) {
                idExternoidCuenta.put(forData.CAZ_Cuenta, null);
            }
        }
        system.debug('CAZ_WS_IU_Contactos ::: idExternoidCuenta: ' + idExternoidCuenta.keySet());

        // Si se encontro como minimo un valor en el mapa, se consultara la Cuenta asociada
        if(!idExternoidCuenta.keySet().isEmpty()) {
            consultaCuentas = [select Id, CAZ_IdExterno__c from Account where CAZ_IdExterno__c IN : idExternoidCuenta.keySet()];
            system.debug('CAZ_WS_IU_Contactos ::: consultaCuentas: ' + consultaCuentas.size());

            if(!consultaCuentas.isEmpty()) {
                // Se carga el mapa para agregar la informacion al nuevo registro
                for(Account forData : consultaCuentas) {
                    idExternoidCuenta.put(forData.CAZ_IdExterno__c, forData.Id);
                }
                system.debug('CAZ_WS_IU_Contactos ::: idExternoidCuenta: ' + idExternoidCuenta.size());

                // se agrega el valor
                for(CAZ_WS_IU_ContactosCamposJSON forData : cjson) {
                    Contact tmp = new Contact();
                    if(idExternoidCuenta.get(forData.CAZ_Cuenta) != null) {
                        tmp.AccountId = idExternoidCuenta.get(forData.CAZ_Cuenta);
                        tmp.FirstName = forData.CAZ_Nombre;
                        tmp.MiddleName = forData.CAZ_SegundoNombre;
                        tmp.LastName = forData.CAZ_Apellidos;
                        tmp.Email = forData.CAZ_Email;
                        tmp.Phone = forData.CAZ_Telefono;
                        tmp.CAZ_Factura__c = forData.CAZ_Factura;
                        tmp.CAZ_IdExterno__c = forData.CAZ_IdExterno;
                        listaInsertar.add(tmp);
                    }
                    else {
                        resultado.Success = false;
                        resultado.Mesagge = 'No se encontro la Cuenta asociada al Contacto. Cuenta: ' + forData.CAZ_Cuenta;
                        resultado.Data = null;
                        continuaValidacion = false;
                    }
                }
                system.debug('CAZ_WS_IU_Contactos ::: listaInsertar: ' + listaInsertar.size());

                // Se insertan los registros
                // - false - insertara todos los registros posibles, embase a los datos minimos necesarios para crear un registro en Salesforce
                // - true  - si un registro como minimo no cumple con los datos minimos necesarios para crear un registro en Salesforce, toda la operacion se cancela
                // Cuando se usa "true", apex ya no itera - Database.UpsertResult -
                Database.UpsertResult[] resultsUpsert = Database.upsert(listaInsertar, Contact.Fields.CAZ_IdExterno__c, false);
                for(Database.UpsertResult forData : resultsUpsert) {
                    if(forData.isSuccess()) {
                        idExito += ', ' + forData.getId();
                    }
                    else {
                        for(Database.Error forDataError : forData.getErrors()) {
                            idError += ' ::: ' + forDataError.getMessage();
                        }
                        continuaValidacion = false;
                    }
                }

                resultado.Success = continuaValidacion ? true : false;
                resultado.Mesagge = continuaValidacion ? 'Informacion procesada' + idExito + ', correctamente en Salesforce': 'La informacion ingresada a Salesforce tuvo errores de validacion' + idError;
                resultado.Data = null;

                system.debug('CAZ_WS_IU_Contactos ::: resultado: ' + resultado);
            }
        }
        //return resultado;
    }
}

/*
JSON propuesto
[
   {
      "CAZ_Cuenta":"A001",
      "CAZ_Nombre":"Nombre0",
      "CAZ_SegundoNombre":"Nombre1",
      "CAZ_Apellidos":"Apellidos",
      "CAZ_Email":"correo2@correo.correo",
      "CAZ_Telefono":"5500000002",
      "CAZ_Factura":false,
      "CAZ_IdExterno":"C000"
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