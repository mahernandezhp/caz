trigger SActualizacionDato on Solicitud_de_actualizacion_de_datos__c (before insert, after insert) {
    // Se obtiene el Id del Tipo de registro
    String idTR_SAD = Schema.SObjectType.Solicitud_de_actualizacion_de_datos__c.getRecordTypeInfosByDeveloperName().get(system.label.SActualizacionDato_developerName).getRecordTypeId();

    if(trigger.isInsert) {
        if(trigger.isBefore) {
            if(system.label.CAZ_stopTriggerSActualizacionDato == 'No') {
                // Flujo para mostrar los campos de Cuenta (direccion) en la Solicitud de actualizacion
                // Se almacenan las Cuentas a consultar
                list<Solicitud_de_actualizacion_de_datos__c> idRegistros = new list<Solicitud_de_actualizacion_de_datos__c>();
                for(Solicitud_de_actualizacion_de_datos__c forData : trigger.new) {
                    forData.RecordTypeId = idTR_SAD;
                    if(forData.RecordTypeId == idTR_SAD) {
                        idRegistros.add(forData);
                    }
                }
                
                // Se consultan todas las Cuentas para procesar la informacion entrante, ya sea registro a mano o automatico
                if(!idRegistros.isEmpty()) {
                    SActualizacionDato_cuenta.actualizaCampos(idRegistros);
                }
            }
        }        
        if(trigger.isAfter) {
            // Se hace la actualizacion de la informacion directamente en la Cuenta
            list<Solicitud_de_actualizacion_de_datos__c> registrosConCopia = new list<Solicitud_de_actualizacion_de_datos__c>();
            if(system.label.CAZ_stopTriggerSActualizacionDato == 'No') {
                for(Solicitud_de_actualizacion_de_datos__c forData : trigger.new) {
                    if(forData.RecordTypeId == idTR_SAD && forData.CAZ_VieneDeWS__c) {
                        registrosConCopia.add(forData);
                    }
                }

                // Se consultan las Cuentas para actualizar la informacion que tiene origen en el servicio externo
                if(!registrosConCopia.isEmpty()) {
                    SActualizacionDato_cuenta.autoActualizacion(registrosConCopia);
                }
            }
        }
    }
}