/*
 * Se recibe json para crear o actualizar registros de Cuenta (Distribuidores)
 * iuDistribuidores = insertar / actualizar Distribuidores
 * 
 * Campos en upsert - ClaveJDE -
 */

@RestResource(urlMapping='/v1/iuDistribuidores/*') global class CAZ_WS_IU_Cuentas {
    @HttpPost global static CAZ_WS_IU_CuentasRespuesta procesaPeticion() {
        system.debug('CAZ_WS_IU_Cuentas ::: urlMapping: v1_iuDistribuidores');

        // Se inician variables
        Boolean continuaValidacion = true;
        list<Account> listaCuentaUpsert = new list<Account>();
        list<CAZ_WS_IU_CuentasCamposJSON> cjson = new list<CAZ_WS_IU_CuentasCamposJSON>();
        list<String> cuentasPrincipales = new list<String>();
        map<String, String> relacionIdExtCP = new map<String, String>();
        CAZ_WS_IU_CuentasRespuesta resultado = new CAZ_WS_IU_CuentasRespuesta();
        // ---
        String idExito = '';
        String idError = '';

        // Se recibe la información desde el servicio
        RestRequest request = RestContext.request;
        system.debug('CAZ_WS_IU_Cuentas ::: request: '+ request.requestURI);

        RestResponse res = RestContext.response;
        String datoRecibido = request.requestBody.toString();

        system.debug('CAZ_WS_IU_Cuentas ::: datoRecibido: ' + datoRecibido);

        // Se descompone la informacion por medio de la clase
        cjson = (list<CAZ_WS_IU_CuentasCamposJSON>) JSON.deserialize(datoRecibido, list<CAZ_WS_IU_CuentasCamposJSON>.class);

        // Se procesa la informacion
        for(CAZ_WS_IU_CuentasCamposJSON forData : cjson) {
            // Se valida que cada registro del JSON tenga el Id identificador entre los dos sistemas
            if(!String.isBlank(forData.ClaveJDE) || !String.isEmpty(forData.ClaveJDE)) {
                Account tmp = new Account();
                tmp.CAZ_Usuario_activo__c = forData.CAZ_Usuario_activo;
                tmp.ClaveJDE__c = forData.ClaveJDE;
                tmp.RFC__c = forData.RFC;
                tmp.CAZ_Correo_institucional__c = forData.CAZ_Email;
                tmp.Phone = forData.Phone;
                tmp.ParentId = null;
                tmp.CAZ_IdExternoCP__c = forData.CuentaPricipal;
                tmp.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CAZ_Informacion_propia').getRecordTypeId();
                tmp.Name = forData.CAZ_NombreDeLaCuenta;
                // Este valor, siempre debera ser true, cuando la informacion viene desde el servicio
                tmp.CAZ_Viene_de_WS__c = true;
                // ---
                tmp.BillingStreet = forData.CAZB_Calle;
                tmp.BillingCity = forData.CAZB_Ciudad;
                tmp.BillingPostalCode = forData.CAZB_CodigoPostal;
                tmp.CAZB_Colonia__c = forData.CAZB_Colonia;
                tmp.BillingState = forData.CAZB_Estado;
                tmp.CAZB_Municipio__c = forData.CAZB_Municipio;
                tmp.CAZB_No_exterior__c = forData.CAZB_No_exterior;
                tmp.CAZB_No_interior__c = forData.CAZB_No_interior;
                tmp.BillingCountry = forData.CAZB_Pais;
                // ---
                tmp.ShippingStreet = forData.CAZS_Calle;
                tmp.ShippingCity = forData.CAZS_Ciudad;
                tmp.ShippingPostalCode = forData.CAZS_CodigoPostal;
                tmp.CAZS_Colonia__c = forData.CAZS_Colonia;
                tmp.ShippingState = forData.CAZS_Estado;
                tmp.CAZS_Municipio__c = forData.CAZS_Municipio;
                tmp.CAZS_No_exterior__c = forData.CAZS_No_exterior;
                tmp.CAZS_No_interior__c = forData.CAZS_No_interior;
                tmp.ShippingCountry = forData.CAZS_Pais;
                // ---
                listaCuentaUpsert.add(tmp);

                // Para calcular la Cuenta principal. Se valida que el campo no este vacio
                system.debug('CAZ_WS_IU_Cuentas ::: CuentaPricipal: ' + forData.CuentaPricipal);
                if(!cuentasPrincipales.contains(forData.CuentaPricipal) && !String.isBlank(forData.CuentaPricipal) && !String.isEmpty(forData.CuentaPricipal)) {
                    cuentasPrincipales.add(forData.CuentaPricipal);
                }
            }
            else {
                resultado.Success = false;
                resultado.Mesagge = 'No se puede continuar con el registro de informacion en Salesforce. No se encontro Id externo.';
                resultado.Data = null;
                continuaValidacion = false;
            }
        }
        system.debug('CAZ_WS_IU_Cuentas ::: cuentasPrincipales: ' + cuentasPrincipales);

        // Se buscan las Cuantas principales
        // "cuentasPrincipales" es el "ClaveJDE__c" de la Cuenta principal
        if(continuaValidacion) {
            if(!cuentasPrincipales.isEmpty()) {
                for(Account forData : [select Id, ClaveJDE__c from Account where ClaveJDE__c IN : cuentasPrincipales]) {
                    relacionIdExtCP.put(forData.ClaveJDE__c, forData.Id);
                }
                system.debug('CAZ_WS_IU_Cuentas ::: relacionIdExtCP: ' + relacionIdExtCP.keySet());

                // Se completa la informacion de el json entrante
                for(Account forData : listaCuentaUpsert) {
                    forData.ParentId = relacionIdExtCP.get(forData.CAZ_IdExternoCP__c);
                    system.debug('CAZ_WS_IU_Cuentas ::: ParentId: ' + forData.ParentId);
                }

                // Se insertan los registros
                // - false - insertara todos los registros posibles, en base a los datos minimos necesarios para crear un registro en Salesforce
                // - true  - si un registro como minimo no cumple con los datos minimos necesarios para crear un registro, toda la operacion se cancela
                Database.UpsertResult[] resultsUpsert = Database.upsert(listaCuentaUpsert, Account.Fields.ClaveJDE__c, false);
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

                resultado.Success = continuaValidacion ? true : false;
                resultado.Mesagge = continuaValidacion ? 'Registro ' + idExito + ', generado correctamente en Salesforce': 'La informacion recibida es insuficiente para generar el registro' + idError;
                resultado.Data = idExito;

                system.debug('CAZ_WS_IU_Cuentas ::: resultado: ' + resultado);
            }
        }
        return resultado;
    }
}

/*
Peticion - 1 registro en estructura de lista
[
   {
      "CAZ_Email":"correo0@correo.correo",
      "CAZ_NombreDeLaCuenta":"Cuenta de WS - 0",
      "CAZ_Usuario_activo":true,
      "ClaveJDE":"1003",
      "CuentaPricipal":"1002",
      "Phone":"5500000000",
      "RFC":"XXXX000000XX0",
      "CAZB_Calle":"Calle - 0",
      "CAZB_Ciudad":"Ciudad - 0",
      "CAZB_CodigoPostal":"10000",
      "CAZB_Colonia":"Colonia - 0",
      "CAZB_Estado":"Estado - 0",
      "CAZB_Municipio":"Municipio - 0",
      "CAZB_No_exterior":"E0",
      "CAZB_No_interior":"I0",
      "CAZB_Pais":"Pais - 0",
      "CAZS_Calle":"Calle - 0",
      "CAZS_Ciudad":"Ciudad - 0",
      "CAZS_CodigoPostal":"10000",
      "CAZS_Colonia":"Colonia - 0",
      "CAZS_Estado":"Estado - 0",
      "CAZS_Municipio":"Municipio - 0",
      "CAZS_No_exterior":"E0",
      "CAZS_No_interior":"I0",
      "CAZS_Pais":"Pais - 0"
   }
]

SUCCESS
{
  "Success" : true,
  "Mesagge" : "Texto...",
  "Data" : null
}

ERROR
{
  "Success" : false,
  "Mesagge" : "Texto...",
  "Data" : null
}
*/