/*
 * Se recibe json para crear o actualizar registros de Cuenta (Distribuidores)
 * iuDistribuidores = insertar / actualizar Distribuidores
 * 
 * Campos en upsert - CAZ_IdExterno__c -
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
        for(CAZ_WS_IU_CuentasCamposJSON forData : cjson) {
            // Se valida que cada registro del JSON tenga el Id identificador entre los dos sistemas
            system.debug('CAZ_WS_IU_Cuentas ::: forData: ' + forData);

            if(!String.isBlank(forData.CAZ_IdExterno) || !String.isEmpty(forData.CAZ_IdExterno)) {
                Account tmp = new Account();
                tmp.CAZ_Usuario_activo__c = forData.CAZ_Usuario_activo;
                tmp.ClaveJDE__c = forData.ClaveJDE;
                tmp.RFC__c = forData.RFC;
                tmp.CAZ_Correo_institucional__c = forData.CAZ_Email;
                tmp.Phone = forData.Phone;
                tmp.CAZ_IdExterno__c = forData.CAZ_IdExterno;
                tmp.Name = forData.CAZ_NombreDeLaCuenta;
                tmp.BillingStreet = forData.CAZB_Calle;
                tmp.BillingCity = forData.CAZB_Ciudad;
                tmp.BillingPostalCode = forData.CAZB_CodigoPostal;
                tmp.CAZB_Colonia__c = forData.CAZB_Colonia;
                tmp.BillingState = forData.CAZB_Estado;
                tmp.CAZB_Municipio__c = forData.CAZB_Municipio;
                tmp.CAZB_No_exterior__c = forData.CAZB_No_exterior;
                tmp.CAZB_No_interior__c = forData.CAZB_No_interior;
                tmp.BillingCountry = forData.CAZB_Pais;
                tmp.ShippingStreet = forData.CAZS_Calle;
                tmp.ShippingCity = forData.CAZS_Ciudad;
                tmp.ShippingPostalCode = forData.CAZS_CodigoPostal;
                tmp.CAZS_Colonia__c = forData.CAZS_Colonia;
                tmp.ShippingState = forData.CAZS_Estado;
                tmp.CAZS_Municipio__c = forData.CAZS_Municipio;
                tmp.CAZS_No_exterior__c = forData.CAZS_No_exterior;
                tmp.CAZS_No_interior__c = forData.CAZS_No_interior;
                tmp.ShippingCountry = forData.CAZS_Pais;
                tmp.ParentId = null;
                tmp.CAZ_IdExternoCP__c = forData.CuentaPricipal;
                tmp.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CAZ_Informacion_propia').getRecordTypeId();
                listaCuentaUpsert.add(tmp);

                // Para calcular la Cuenta principal. Se valida que el campo no este vacio
                if(!cuentasPrincipales.contains(forData.CuentaPricipal) && forData.CuentaPricipal != null) {
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
        // "CuentaPricipal" es el "CAZ_IdExterno__c" de la Cuenta principal
        if(continuaValidacion) {
            if(!cuentasPrincipales.isEmpty()) {
                for(Account forData : [select Id, CAZ_IdExterno__c from Account where CAZ_IdExterno__c IN : cuentasPrincipales]) {
                    relacionIdExtCP.put(forData.CAZ_IdExterno__c, forData.Id);
                }
                system.debug('CAZ_WS_IU_Cuentas ::: relacionIdExtCP: ' + relacionIdExtCP.keySet());

                // Se completa la informacion de el json entrante
                for(Account forData : listaCuentaUpsert) {
                    forData.ParentId = relacionIdExtCP.get(forData.CAZ_IdExternoCP__c);
                    system.debug('CAZ_WS_IU_Cuentas ::: ParentId: ' + forData.ParentId);
                }

                // Se insertan los registros
                // - false - insertara todos los registros posibles, embase a los datos minimos necesarios para crear un registro en Salesforce
                // - true  - si un registro como minimo no cumple con los datos minimos necesarios para crear un registro en Salesforce, toda la operacion se cancela
                // Cuando se usa "true", apex ya no itera - Database.UpsertResult -
                Database.UpsertResult[] resultsUpsert = Database.upsert(listaCuentaUpsert, Account.Fields.CAZ_IdExterno__c, false);
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
      "ClaveJDE":"1000",
      "RFC":"XXXX000000XX0",
      "CAZ_Email":"correo0@correo.correo",
      "Phone":"5500000000",
      "CAZ_IdExterno":"A000",
      "CAZ_NombreDeLaCuenta":"Cuenta de WS - 0",
      "CAZ_Usuario_activo":true,
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
      "CAZS_Pais":"Pais - 0",
      "CuentaPricipal":"A001"
   }
]

Peticion - Varios registros
[
   {
      "ClaveJDE":"1000",
      "RFC":"XXXX000000XX0",
      "CAZ_Email":"correo0@correo.correo",
      "Phone":"5500000000",
      "CAZ_IdExterno":"A000",
      "CAZ_NombreDeLaCuenta":"Cuenta de WS - 0",
      "CAZ_Usuario_activo":true,
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
      "CAZS_Pais":"Pais - 0",
      "CuentaPricipal":"A001"
   },
   {
      "ClaveJDE":"1001",
      "RFC":"XXXX000000XX1",
      "CAZ_Email":"correo1@correo.correo",
      "Phone":"5500000001",
      "CAZ_IdExterno":"A001",
      "CAZ_NombreDeLaCuenta":"Cuenta de WS - 1",
      "CAZ_Usuario_activo":true,
      "CAZB_Calle":"Calle - 1",
      "CAZB_Ciudad":"Ciudad - 1",
      "CAZB_CodigoPostal":"10001",
      "CAZB_Colonia":"Colonia - 1",
      "CAZB_Estado":"Estado - 1",
      "CAZB_Municipio":"Municipio - 1",
      "CAZB_No_exterior":"E1",
      "CAZB_No_interior":"I1",
      "CAZB_Pais":"Pais - 1",
      "CAZS_Calle":"Calle - 1",
      "CAZS_Ciudad":"Ciudad - 1",
      "CAZS_CodigoPostal":"10001",
      "CAZS_Colonia":"Colonia - 1",
      "CAZS_Estado":"Estado - 1",
      "CAZS_Municipio":"Municipio - 1",
      "CAZS_No_exterior":"E1",
      "CAZS_No_interior":"I1",
      "CAZS_Pais":"Pais - 1",
      "CuentaPricipal":"A001"
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