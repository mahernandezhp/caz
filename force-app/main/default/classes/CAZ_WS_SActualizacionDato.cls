/*
 * Se recibe la informacion por medio del WS.
 * Solo se acepta un registro a la vez
 */

@RestResource(urlMapping='/v1/actualizaDato/*') global class CAZ_WS_SActualizacionDato {
    @HttpPost global static CAZ_WS_SActualizacionDatoResponse recibeActualizacion() {
        system.debug('CAZ_WS_SActualizacionDato ::: urlMapping: v1_actualizaDato');

        // Se inician las variables
        list<String> listIdCuenta = new list<String>();
        map<String, String> mapIdCuenta = new map<String, String>();
        list<Solicitud_de_actualizacion_de_datos__c> saddObj = new list<Solicitud_de_actualizacion_de_datos__c>();
        list<Solicitud_de_actualizacion_de_datos__c> list_saddObj = new list<Solicitud_de_actualizacion_de_datos__c>();
        list<CAZ_WS_SActualizacionDatoData> sadd = new list<CAZ_WS_SActualizacionDatoData>();
        CAZ_WS_SActualizacionDatoResponse sadr = new CAZ_WS_SActualizacionDatoResponse();

        // Se recibe la información desde el servicio
        RestRequest request = RestContext.request;
        system.debug('CAZ_WS_SActualizacionDato ::: request: '+ request.requestURI);

        RestResponse res = RestContext.response;
        String datoRecibido = request.requestBody.toString();
        system.debug('CAZ_WS_SActualizacionDato ::: datoRecibido: ' + datoRecibido);

        // Se descompone la informacion por medio de la clase
        sadd = (list<CAZ_WS_SActualizacionDatoData>) JSON.deserialize(datoRecibido, list<CAZ_WS_SActualizacionDatoData>.class);
        system.debug('CAZ_WS_SActualizacionDato ::: sadd: ' + sadd.size());
        
        // Se agrega la informacion al objeto ya instanciado
        for(CAZ_WS_SActualizacionDatoData forData : sadd) {
            Solicitud_de_actualizacion_de_datos__c saddObjTMP = new Solicitud_de_actualizacion_de_datos__c();
            listIdCuenta.add(forData.CAZ_IdExterno);
            saddObjTMP.CAZ_IdExterno__c = forData.CAZ_IdExterno;
            saddObjTMP.CAZ_VieneDeWS__c = true;
            saddObjTMP.CAZP_Email__c = forData.CAZ_Email;
            //---
            saddObjTMP.CAZPB_Calle__c = forData.CAZB_Calle;
            saddObjTMP.CAZPB_Ciudad__c = forData.CAZB_Ciudad;
            saddObjTMP.CAZPB_CodigoPostal__c = forData.CAZB_CodigoPostal;
            saddObjTMP.CAZPB_Colonia__c = forData.CAZB_Colonia;
            saddObjTMP.CAZPB_Estado__c = forData.CAZB_Estado;
            saddObjTMP.CAZPB_Municipio__c = forData.CAZB_Municipio;
            saddObjTMP.CAZPB_No_exterior__c = forData.CAZB_No_exterior;
            saddObjTMP.CAZPB_No_interior__c = forData.CAZB_No_interior;
            saddObjTMP.CAZPB_Pais__c = forData.CAZB_Pais;
            //---
            saddObjTMP.CAZPS_Calle__c = forData.CAZS_Calle;
            saddObjTMP.CAZPS_Ciudad__c = forData.CAZS_Ciudad;
            saddObjTMP.CAZPS_CodigoPostal__c = forData.CAZS_CodigoPostal;
            saddObjTMP.CAZPS_Colonia__c = forData.CAZS_Colonia;
            saddObjTMP.CAZPS_Estado__c = forData.CAZS_Estado;
            saddObjTMP.CAZPS_Municipio__c = forData.CAZS_Municipio;
            saddObjTMP.CAZPS_No_exterior__c = forData.CAZS_No_exterior;
            saddObjTMP.CAZPS_No_interior__c = forData.CAZS_No_interior;
            saddObjTMP.CAZPS_Pais__c = forData.CAZS_Pais;
            //---
            saddObjTMP.RecordTypeId = Schema.SObjectType.Solicitud_de_actualizacion_de_datos__c.getRecordTypeInfosByDeveloperName().get(system.label.SActualizacionDato_developerName).getRecordTypeId();
            saddObj.add(saddObjTMP);
        }
        
        if(!listIdCuenta.isEmpty()) {
            // select Id, ClaveJDE__c from Account where ClaveJDE__c IN : listIdCuenta
            list<Account> cuentaUnica = Database.query(system.label.CAZ_WS_SADeDatos);
            system.debug('CAZ_WS_SActualizacionDato ::: cuentaUnica: ' + cuentaUnica.size());

            if(!cuentaUnica.isEmpty()) {
                for(Account forData: cuentaUnica) {
                    system.debug('forData ::: JDE: ' + forData.ClaveJDE__c + ' ::: Id: ' + forData.Id);
                    mapIdCuenta.put(forData.ClaveJDE__c, forData.Id);
                }

                for(Solicitud_de_actualizacion_de_datos__c forData : saddObj) {
                    forData.CAZ_Cuenta__c = mapIdCuenta.get(forData.CAZ_IdExterno__c);
                    system.debug('CAZ_WS_SActualizacionDato ::: cuantaUnica: ' + forData.CAZ_Cuenta__c);
                }
            }
        }

        // false: indica que se insertaran tantos registros sean posibles
        Database.SaveResult[] dbsr = Database.insert(saddObj, false);
        for(Database.SaveResult forData : dbsr) {
            if(forData.isSuccess()) {
                sadr.resultado = 'Registro recibido y almacenado correctamente';
            }
            else {
                for(Database.Error forDataError : forData.getErrors()) {
                    sadr.resultado += 'Error ::: ' + 'Detalle ::: ' + forDataError.getStatusCode() + ' ::: ' + forDataError.getMessage() + ' ::: Afectando los campos: ' + forDataError.getFields();
                }
            }
        }
        return sadr;
    }
}

// JSON
// Para Postman
/*
[
   {
      "CAZ_IdExterno":"12345678",
      "CAZ_Email":"cliente1@correo.com",
      "CAZB_Calle":"Av. Reforma",
      "CAZB_Ciudad":"Ciudad de México",
      "CAZB_CodigoPostal":"06001",
      "CAZB_Colonia":"Centro",
      "CAZB_Estado":"CDMX",
      "CAZB_Municipio":"Cuauhtémoc",
      "CAZB_No_exterior":"101",
      "CAZB_No_interior":"11A",
      "CAZB_Pais":"México",
      "CAZS_Calle":"Av. Insurgentes",
      "CAZS_Ciudad":"Ciudad de México",
      "CAZS_CodigoPostal":"06001",
      "CAZS_Colonia":"Del Valle",
      "CAZS_Estado":"CDMX",
      "CAZS_Municipio":"Benito Juárez",
      "CAZS_No_exterior":"11A",
      "CAZS_No_interior":"11B",
      "CAZS_Pais":"México"
   }
]
*/

// Lista - Ejemplo
/*
[
   {
      "CAZ_IdExterno":"12345678",
      "CAZ_Email":"cliente1@correo.com",
      "CAZB_Calle":"Av. Reforma",
      "CAZB_Ciudad":"Ciudad de México",
      "CAZB_CodigoPostal":"06001",
      "CAZB_Colonia":"Centro",
      "CAZB_Estado":"CDMX",
      "CAZB_Municipio":"Cuauhtémoc",
      "CAZB_No_exterior":"101",
      "CAZB_No_interior":"11A",
      "CAZB_Pais":"México",
      "CAZS_Calle":"Av. Insurgentes",
      "CAZS_Ciudad":"Ciudad de México",
      "CAZS_CodigoPostal":"06001",
      "CAZS_Colonia":"Del Valle",
      "CAZS_Estado":"CDMX",
      "CAZS_Municipio":"Benito Juárez",
      "CAZS_No_exterior":"11A",
      "CAZS_No_interior":"11B",
      "CAZS_Pais":"México"
   },
   {
      "CAZ_IdExterno":"12345679",
      "CAZ_Email":"cliente2@correo.com",
      "CAZB_Calle":"Av. Reforma",
      "CAZB_Ciudad":"Ciudad de México",
      "CAZB_CodigoPostal":"06002",
      "CAZB_Colonia":"Centro",
      "CAZB_Estado":"CDMX",
      "CAZB_Municipio":"Cuauhtémoc",
      "CAZB_No_exterior":"102",
      "CAZB_No_interior":"12A",
      "CAZB_Pais":"México",
      "CAZS_Calle":"Av. Insurgentes",
      "CAZS_Ciudad":"Ciudad de México",
      "CAZS_CodigoPostal":"06002",
      "CAZS_Colonia":"Del Valle",
      "CAZS_Estado":"CDMX",
      "CAZS_Municipio":"Benito Juárez",
      "CAZS_No_exterior":"12A",
      "CAZS_No_interior":"12B",
      "CAZS_Pais":"México"
   }
]
*/