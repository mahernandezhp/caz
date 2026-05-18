/*
 * Se recibe json para crear o actualizar registros de Contactos
 * iuContactos = insertar / actualizar Contactos
 * 
 * Campos en upsert - CAZ_IdExterno__c -
 */

@RestResource(urlMapping='/v1/iuContactos/*') global class CAZ_WS_IU_Contactos {
    @HttpPost global static CAZ_WS_IU_ContactosRespuesta procesaPeticion() {
        system.debug('CAZ_WS_IU_Contactos ::: urlMapping: v1_iuContactos');

        // Se inician variables
        String apexJSON = null;
        list<String> idExternoidCuenta = new list<String>();
        list<CAZ_WS_IU_ContactosCamposJSON> cjson = new list<CAZ_WS_IU_ContactosCamposJSON>();
        list<Account> consultaCuentas = new list<Account>();
        list<CAZ_WS_IU_ContactosEstructura> contactoJSONRespuesta = new list<CAZ_WS_IU_ContactosEstructura>();
        CAZ_WS_IU_ContactosRespuesta resultado = new CAZ_WS_IU_ContactosRespuesta();

        // Se recibe la información desde el servicio
        RestRequest request = RestContext.request;
        system.debug('CAZ_WS_IU_Cuentas ::: request: '+ request.requestURI);

        RestResponse res = RestContext.response;
        String datoRecibido = request.requestBody.toString();

        system.debug('CAZ_WS_IU_Contactos ::: datoRecibido: ' + datoRecibido);

        // Se procesa la respuesta del servicio de Cruz Azul
        cjson = (list<CAZ_WS_IU_ContactosCamposJSON>) JSON.deserialize(datoRecibido, list<CAZ_WS_IU_ContactosCamposJSON>.class);
        system.debug('CAZ_WS_IU_Contactos ::: cjson: ' + cjson.size());

        // Se consulta la Cuenta asociada en base al valor del campo "Cuenta" del JSON
        for(CAZ_WS_IU_ContactosCamposJSON forData : cjson) {
            system.debug('CAZ_WS_IU_Contactos ::: forData: ' + forData.CAZ_ClaveJDE);

            if(!String.isBlank(forData.CAZ_ClaveJDE) && !String.isEmpty(forData.CAZ_ClaveJDE) && !idExternoidCuenta.contains(forData.CAZ_ClaveJDE)) {
                idExternoidCuenta.add(forData.CAZ_ClaveJDE);
            }
        }
        system.debug('CAZ_WS_IU_Contactos ::: idExternoidCuenta: ' + idExternoidCuenta.size());

        // Si se encontro como minimo un valor en la lista, se consultaran las Cuentas asociadas
        if(!idExternoidCuenta.isEmpty()) {
            // Se consultan los registros de Cuenta asociados
            consultaCuentas = [select Id, ClaveJDE__c, (select Id, AccountId, Account.Name, FirstName, MiddleName, LastName, Email, Phone from Contacts) from Account where ClaveJDE__c IN : idExternoidCuenta];
            system.debug('CAZ_WS_IU_Contactos ::: consultaCuentas: ' + consultaCuentas.size());

            if(!consultaCuentas.isEmpty()) {
                // Se agrupa la informacion de Contactos
                for(Account forData : consultaCuentas) {
                    if(!forData.Contacts.isEmpty()) {
                        for(Contact forData2 : forData.Contacts) {
                            CAZ_WS_IU_ContactosEstructura contactoJSONtmp = new CAZ_WS_IU_ContactosEstructura();
                            contactoJSONtmp.IdAccount = forData2.AccountId;
                            contactoJSONtmp.Distribuidor = forData2.Account.Name;
                            contactoJSONtmp.Nombre = forData2.FirstName;
                            contactoJSONtmp.Nombre2 = forData2.MiddleName;
                            contactoJSONtmp.Apellidos = forData2.LastName;
                            contactoJSONtmp.Email = forData2.Email;
                            contactoJSONtmp.Telefono = forData2.Phone;
                            contactoJSONRespuesta.add(contactoJSONtmp);
                        }
                    }
                }
                system.debug('CAZ_WS_IU_Contactos ::: contactoJSONRespuesta: ' + contactoJSONRespuesta.size());

                // Se prepara la respuesta
                resultado.Success = true;
                resultado.Mesagge = !contactoJSONRespuesta.isEmpty() ? 'Informacion cargada correctamente.' : 'No se encontraron Contactos relacionados ';
                resultado.Data = !contactoJSONRespuesta.isEmpty() ? contactoJSONRespuesta : null;
            }
            else {
                resultado.Success = false;
                resultado.Mesagge = 'No se encontro registro de Cuenta (Distribuidor) con el JDE indicado.';
                resultado.Data = null;
            }
        }
        return resultado;
    }
}

/*
JSON propuesto
[
   {
      "CAZ_ClaveJDE":"1003"
   }
]

SUCCESS
{
  "Success" : true,
  "Mesagge" : "Texto...",
  "Data" : objClass
}

ERROR
{
  "Success" : false,
  "Mesagge" : "Texto...",
  "Data" : null
}
*/