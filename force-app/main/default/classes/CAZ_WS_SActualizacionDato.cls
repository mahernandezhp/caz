/*
 * Se recibe la informacion por medio del WS.
 * Solo se acepta un registro a la vez
 */

@RestResource(urlMapping='/v1/actualizaDato/*') global class CAZ_WS_SActualizacionDato {
    @HttpPost global static CAZ_WS_SActualizacionDatoResponse recibeActualizacion() {
        system.debug('CAZ_WS_SActualizacionDato ::: urlMapping: v1_actualizaDato');

        // Se inician las variables
        String idCuenta = null;
        Solicitud_de_actualizacion_de_datos__c saddObj = new Solicitud_de_actualizacion_de_datos__c();
        list<Solicitud_de_actualizacion_de_datos__c> list_saddObj = new list<Solicitud_de_actualizacion_de_datos__c>();
        CAZ_WS_SActualizacionDatoData sadd = new CAZ_WS_SActualizacionDatoData();
        CAZ_WS_SActualizacionDatoResponse sadr = new CAZ_WS_SActualizacionDatoResponse();
        sadr.resultado = '';
        
        system.debug('CAZ_WS_SActualizacionDato ::: resultado: ' + sadr.resultado);
        system.debug('CAZ_WS_SActualizacionDato ::: idCuenta: ' + idCuenta);

        // Se recibe la información desde el servicio
        RestRequest request = RestContext.request;
        system.debug('CAZ_WS_SActualizacionDato ::: request: '+ request.requestURI);

        RestResponse res = RestContext.response;
        String datoRecibido = request.requestBody.toString();
        system.debug('CAZ_WS_SActualizacionDato ::: datoRecibido: ' + datoRecibido);

        // Se descompone la informacion por medio de la clase
        sadd = (CAZ_WS_SActualizacionDatoData) JSON.deserialize(datoRecibido, CAZ_WS_SActualizacionDatoData.class);
        // ---
        idCuenta = sadd.CAZ_IdExterno;
        system.debug('CAZ_WS_SActualizacionDato ::: idCuenta: ' + idCuenta);
        //---
        saddObj.CAZ_IdExterno__c = sadd.CAZ_IdExterno;
        saddObj.CAZP_Email__c = sadd.CAZ_Email;
        saddObj.CAZPB_Calle__c = sadd.CAZB_Calle;
        saddObj.CAZPB_Ciudad__c = sadd.CAZB_Ciudad;
        saddObj.CAZPB_CodigoPostal__c = sadd.CAZB_CodigoPostal;
        saddObj.CAZPB_Colonia__c = sadd.CAZB_Colonia;
        saddObj.CAZPB_Estado__c = sadd.CAZB_Estado;
        saddObj.CAZPB_Municipio__c = sadd.CAZB_Municipio;
        saddObj.CAZPB_No_exterior__c = sadd.CAZB_No_exterior;
        saddObj.CAZPB_No_interior__c = sadd.CAZB_No_interior;
        saddObj.CAZPB_Pais__c = sadd.CAZB_Pais;
        saddObj.CAZPS_Calle__c = sadd.CAZS_Calle;
        saddObj.CAZPS_Ciudad__c = sadd.CAZS_Ciudad;
        saddObj.CAZPS_CodigoPostal__c = sadd.CAZS_CodigoPostal;
        saddObj.CAZPS_Colonia__c = sadd.CAZS_Colonia;
        saddObj.CAZPS_Estado__c = sadd.CAZS_Estado;
        saddObj.CAZPS_Municipio__c = sadd.CAZS_Municipio;
        saddObj.CAZPS_No_exterior__c = sadd.CAZS_No_exterior;
        saddObj.CAZPS_No_interior__c = sadd.CAZS_No_interior;
        saddObj.CAZPS_Pais__c = sadd.CAZS_Pais;
        saddObj.CAZ_VieneDeWS__c = sadd.CAZ_VieneDeWS;
        saddObj.RecordTypeId = Schema.SObjectType.Solicitud_de_actualizacion_de_datos__c.getRecordTypeInfosByDeveloperName().get(system.label.SActualizacionDato_developerName).getRecordTypeId();
        
        if(!String.isEmpty(idCuenta)) {
            // select Id from Account where CAZ_IdExterno__c =: idCuenta
            list<Account> cuantaUnica = Database.query(system.label.CAZ_WS_SADeDatos);
            system.debug('CAZ_WS_SActualizacionDato ::: cuantaUnica: ' + cuantaUnica);

            if(!cuantaUnica.isEmpty()) {
                saddObj.CAZ_Cuenta__c = cuantaUnica[0].Id;
                system.debug('CAZ_WS_SActualizacionDato ::: cuantaUnica[0].Id: ' + saddObj.CAZ_Cuenta__c);
            }
        }
        list_saddObj.add(saddObj);

        // false: indica que se insertaran tantos registros sean posibles
        Database.SaveResult[] dbsr = Database.insert(list_saddObj, false);
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

// JSON para metodo de prueba
/*
{
  "CAZ_IdExterno": "A001",
  "CAZ_Email": "cliente@correo.com",
  "CAZB_Calle": "Av. Reforma",
  "CAZB_Ciudad": "Ciudad de México",
  "CAZB_CodigoPostal": "06000",
  "CAZB_Colonia": "Centro",
  "CAZB_Estado": "CDMX",
  "CAZB_Municipio": "Cuauhtémoc",
  "CAZB_No_exterior": "100",
  "CAZB_No_interior": "10A",
  "CAZB_Pais": "México",
  "CAZS_Calle": "Av. Insurgentes",
  "CAZS_Ciudad": "Ciudad de México",
  "CAZS_CodigoPostal": "03100",
  "CAZS_Colonia": "Del Valle",
  "CAZS_Estado": "CDMX",
  "CAZS_Municipio": "Benito Juárez",
  "CAZS_No_exterior": "250",
  "CAZS_No_interior": "5B",
  "CAZS_Pais": "México",
  "CAZ_VieneDeWS": true
}
*/