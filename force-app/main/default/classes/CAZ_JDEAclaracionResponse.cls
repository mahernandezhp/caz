public class CAZ_JDEAclaracionResponse {
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public Boolean abonoEncontrado { get; set; }
    @AuraEnabled public Decimal montoAbono { get; set; }
    @AuraEnabled public Date fechaAbono { get; set; }
    @AuraEnabled public String referencia { get; set; }

    public CAZ_JDEAclaracionResponse() {
        this.success = false;
        this.abonoEncontrado = false;
    }
}
