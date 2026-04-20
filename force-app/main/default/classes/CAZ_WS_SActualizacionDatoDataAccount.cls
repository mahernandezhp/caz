public class CAZ_WS_SActualizacionDatoDataAccount {
    public static Account creaCuenta(String nombreCuenta, String idUnico) {
        // Definicion de variables
        list<Account> listaCuenta = new list<Account>();
        Account nuevaCuenta = new Account();

        nuevaCuenta.Name = nombreCuenta;
        nuevaCuenta.CAZ_IdExterno__c = idUnico;
        nuevaCuenta.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(system.label.CuentaPropia_developerName).getRecordTypeId();
        listaCuenta.add(nuevaCuenta);

        // false: indica que se insertaran tantos registros sean posibles
        Database.SaveResult[] dbsr = Database.insert(listaCuenta, false);
        for(Database.SaveResult forData : dbsr) {
            if(forData.isSuccess()) {
                system.debug('Registro recibido y almacenado correctamente');
            }
            else {
                for(Database.Error forDataError : forData.getErrors()) {
                    system.debug('Error ::: ' + forDataError.getStatusCode() + ' ::: ' + forDataError.getMessage() + ' ::: ' + forDataError.getFields());
                }
            }
        }

        // Se regresa el registro creado
        return listaCuenta[0];
    }
}