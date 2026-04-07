public class SActualizacionDato_solicitud implements Queueable {
    public Boolean exitoError {get; set;}
    public String idRegistro {get; set;}

    public SActualizacionDato_solicitud(Boolean er, String idr) {
        exitoError = er;
        idRegistro = idr;
    }

    public void execute(QueueableContext context) {
        system.debug('Exito / error: ' + exitoError);
        system.debug('Registro: ' + idRegistro);

        String idTR = Schema.SObjectType.Solicitud_de_actualizacion_de_datos__c.getRecordTypeInfosByDeveloperName().get(system.label.SActualizacionDato_developerName).getRecordTypeId();
        system.debug('idTR: ' + idTR);

        // Se consulta el registro de Solicitudes de actualización de datos para actualizar su estado
        // select Id, CAZ_Estado__c from Solicitud_de_actualizacion_de_datos__c where CAZ_Cuenta__c =: idRegistro and CAZ_VieneDeWS__c = true and RecordTypeId =: idTR and CAZ_Estado__c = 'Recibido'
        list<Solicitud_de_actualizacion_de_datos__c> actualizaEstado = Database.query(system.label.CAZ_SAD_aceptada);
        system.debug('actualizaEstado: ' + actualizaEstado.size());

        for(Solicitud_de_actualizacion_de_datos__c forData : actualizaEstado) {
            forData.CAZ_Estado__c = exitoError ? 'Aprobado' : 'Rechazado';
            system.debug('forData.CAZ_Estado__c: ' + forData.CAZ_Estado__c);
        }
        Database.update(actualizaEstado,false);
    }
}