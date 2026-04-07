public class SActualizacionDato_cuenta {
    public static void actualizaCampos(list<Solicitud_de_actualizacion_de_datos__c> triggerNew) {
        // Definicion de variables
        list<String> idCuentas = new list<String>();
        list<Account> registroCuentas = new list<Account>();
        map<String, Account> mapaCuentas = new map<String, Account>();

        // Se extraen los Ids para consultar los registros
        for(Solicitud_de_actualizacion_de_datos__c forData : triggerNew) {
            idCuentas.add(forData.CAZ_Cuenta__c);
        }
        system.debug('SActualizacionDato ::: idCuentas ::: ' + idCuentas);

        // Se consulta la información de la Cuenta para mostrarlos como solo lectura
        if(!idCuentas.isEmpty()) {
            // select Id, CAZB_Colonia__c, CAZB_Municipio__c, CAZB_No_exterior__c, CAZB_No_interior__c, CAZS_Colonia__c, CAZS_Municipio__c, CAZS_No_exterior__c, CAZS_No_interior__c, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet, ShippingCity, ShippingCountry, ShippingPostalCode, ShippingState, ShippingStreet, CAZ_IdExterno__c, CAZ_Correo_institucional__c, CAZ_Direccion_plantilla_B__c, CAZ_Direccion_plantilla_S__c from Account where Id IN : idCuentas
            registroCuentas = Database.query(system.label.CAZ_Cuenta_soloLectura);
            system.debug('registroCuentas ::: size ::: ' + registroCuentas.size());

            // Se agrupa la informacion
            if(!registroCuentas.isEmpty()) {
                for(Account forData : registroCuentas) {
                    mapaCuentas.put(forData.Id, forData);
                }
                system.debug('mapaCuentas ::: size ::: ' + mapaCuentas.size());
            }
        }

        // Se consulta la informacion de la Cuenta y se asigna a la solicitud de informacion
        if(!registroCuentas.isEmpty()) {
            for(Solicitud_de_actualizacion_de_datos__c forData : triggerNew) {
                // Se extrae la informacion especifica del objeto de Cuenta
                Account cuentaForData = mapaCuentas.get(forData.CAZ_Cuenta__c);

                // Campos
                forData.CAZB_Ciudad__c = cuentaForData.BillingCity;
                forData.CAZB_Pais__c = cuentaForData.BillingCountry;
                forData.CAZB_CodigoPostal__c = cuentaForData.BillingPostalCode;
                forData.CAZB_Estado__c = cuentaForData.BillingState;
                forData.CAZB_Calle__c = cuentaForData.BillingStreet;
                // - - - - -
                forData.CAZS_Ciudad__c = cuentaForData.ShippingCity;
                forData.CAZS_Pais__c = cuentaForData.ShippingCountry;
                forData.CAZS_CodigoPostal__c = cuentaForData.ShippingPostalCode;
                forData.CAZS_Estado__c = cuentaForData.ShippingState;
                forData.CAZS_Calle__c = cuentaForData.ShippingStreet;
                // - - - - -
                forData.CAZB_Colonia__c = cuentaForData.CAZB_Colonia__c;
                forData.CAZB_Municipio__c = cuentaForData.CAZB_Municipio__c;
                forData.CAZB_No_exterior__c = cuentaForData.CAZB_No_exterior__c;
                forData.CAZB_No_interior__c = cuentaForData.CAZB_No_interior__c;
                // - - - - -
                forData.CAZS_Colonia__c = cuentaForData.CAZS_Colonia__c;
                forData.CAZS_Municipio__c = cuentaForData.CAZS_Municipio__c;
                forData.CAZS_No_exterior__c = cuentaForData.CAZS_No_exterior__c;
                forData.CAZS_No_interior__c = cuentaForData.CAZS_No_interior__c;
                // - - - - -
                forData.CAZ_IdExterno__c = cuentaForData.CAZ_IdExterno__c;
                forData.CAZ_Email__c = cuentaForData.CAZ_Correo_institucional__c;
                // - - - - -
                forData.CAZ_Correo_institucional__c = cuentaForData.CAZ_Correo_institucional__c;
                forData.CAZ_Direccion_plantilla_B__c = cuentaForData.CAZ_Direccion_plantilla_B__c;
                forData.CAZ_Direccion_plantilla_s__c = cuentaForData.CAZ_Direccion_plantilla_S__c;
            }
        }
    }

    public static void autoActualizacion(list<Solicitud_de_actualizacion_de_datos__c> triggerNew) {
        // Definicion de variables
        list<Account> registroCuentas = null;
        map<String, Solicitud_de_actualizacion_de_datos__c> sad_cuenta = new map<String, Solicitud_de_actualizacion_de_datos__c>();
        map<String, Account> query_cuenta = new map<String, Account>();

        // Se extrae la informacion
        for(Solicitud_de_actualizacion_de_datos__c forData : triggerNew) {
            sad_cuenta.put(forData.CAZ_IdExterno__c, forData);
        }

        // Se consulta y organiza la informacion de la Cuenta
        registroCuentas = [select Id, CAZB_Colonia__c, CAZB_Municipio__c, CAZB_No_exterior__c, CAZB_No_interior__c, CAZS_Colonia__c, CAZS_Municipio__c, CAZS_No_exterior__c, CAZS_No_interior__c, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet, ShippingCity, ShippingCountry, ShippingPostalCode, ShippingState, ShippingStreet, CAZ_IdExterno__c, CAZ_Correo_institucional__c, CAZ_Direccion_plantilla_B__c, CAZ_Direccion_plantilla_S__c from Account where CAZ_IdExterno__c IN : sad_cuenta.keySet()];
        for(Account forData : registroCuentas) {
            Solicitud_de_actualizacion_de_datos__c sadTemp = sad_cuenta.get(forData.CAZ_IdExterno__c);
            forData.CAZB_Colonia__c = sadTemp.CAZPB_Colonia__c;
            forData.CAZB_Municipio__c = sadTemp.CAZPB_Municipio__c;
            forData.CAZB_No_exterior__c = sadTemp.CAZPB_No_exterior__c;
            forData.CAZB_No_interior__c = sadTemp.CAZPB_No_interior__c;
            forData.CAZS_Colonia__c = sadTemp.CAZPS_Colonia__c;
            forData.CAZS_Municipio__c = sadTemp.CAZPS_Municipio__c;
            forData.CAZS_No_exterior__c = sadTemp.CAZPS_No_exterior__c;
            forData.CAZS_No_interior__c = sadTemp.CAZPS_No_interior__c;
            forData.BillingCity = sadTemp.CAZPB_Ciudad__c;
            forData.BillingCountry = sadTemp.CAZPB_Pais__c;
            forData.BillingPostalCode = sadTemp.CAZPB_CodigoPostal__c;
            forData.BillingState = sadTemp.CAZPB_Estado__c;
            forData.BillingStreet = sadTemp.CAZPB_Calle__c;
            forData.ShippingCity = sadTemp.CAZPS_Ciudad__c;
            forData.ShippingCountry = sadTemp.CAZPS_Pais__c;
            forData.ShippingPostalCode = sadTemp.CAZPS_CodigoPostal__c;
            forData.ShippingState = sadTemp.CAZPS_Estado__c;
            forData.ShippingStreet = sadTemp.CAZPS_Calle__c;
            forData.CAZ_Correo_institucional__c = sadTemp.CAZP_Email__c;
        }

        // Se guarda la informacion y se finaliza el flujo
        // Se actualiza el registro. false: indica que se insertaran tantos registros sean posibles
        Database.SaveResult[] dbsr = Database.update(registroCuentas, false);
        for(Database.SaveResult forData : dbsr) {
            if(forData.isSuccess()) {
                system.debug('Registro actualizado correctamente');
                system.debug('Registro a enviar: ' + forData.Id);
                //Id jobID = System.enqueueJob(new SActualizacionDato_solicitud(true, forData.Id), 1);
                Id jobID = System.enqueueJob(new SActualizacionDato_solicitud(true, forData.Id));
            }
            else {
                for(Database.Error forDataError : forData.getErrors()) {
                    system.debug('Error ::: ' + 'Detalle ::: ' + forDataError.getStatusCode() + ' ::: ' + forDataError.getMessage() + ' ::: Afectando los campos: ' + forDataError.getFields());
                }
                //Id jobID = System.enqueueJob(new SActualizacionDato_solicitud(false, forData.Id), 1);
                Id jobID = System.enqueueJob(new SActualizacionDato_solicitud(false, forData.Id));
            }
        }
    }
}