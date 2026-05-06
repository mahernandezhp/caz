List<CAZ_SolicitudCredito__c> records = [SELECT Id, CAZ_Cuenta__c FROM CAZ_SolicitudCredito__c WHERE CAZ_Cuenta__c = null];
for(CAZ_SolicitudCredito__c req : records) {
    req.CAZ_Cuenta__c = '001WD00000bjdERYAY';
}
update records;
