public class CAZ_AclaracionPagoQueueable implements Queueable, Database.AllowsCallouts {
    private Id caseId;
    private String claveCliente;
    private String numeroFactura;
    
    public CAZ_AclaracionPagoQueueable(Id caseId, String claveCliente, String numeroFactura) {
        this.caseId = caseId;
        this.claveCliente = claveCliente;
        this.numeroFactura = numeroFactura;
    }
    
    public void execute(QueueableContext context) {
        // Usamos el mock por defecto para desarrollo.
        // En producción esto se reemplazaría por la implementación real.
        CAZ_IJDEAclaracionService service = new CAZ_JDEAclaracionServiceMock();
        
        CAZ_JDEAclaracionResponse response = service.consultarAbono(this.claveCliente, this.numeroFactura);
        
        Case casoToUpdate = new Case(Id = this.caseId);
        
        if (response.success) {
            if (response.abonoEncontrado) {
                casoToUpdate.CAZ_AbonoEncontrado__c = true;
                casoToUpdate.CAZ_MontoPagado__c = response.montoAbono;
                casoToUpdate.CAZ_FechaPago__c = response.fechaAbono;
                casoToUpdate.CAZ_ReferenciaBancaria__c = response.referencia;
                // Si el abono es encontrado, se puede iniciar el proceso de revisión o cerrarlo
                casoToUpdate.Status = 'En Revisión';
            } else {
                casoToUpdate.CAZ_AbonoEncontrado__c = false;
                // Si no se encuentra, la Tesorería debe revisar manualmente
                casoToUpdate.Status = 'En Revisión';
            }
        } else {
            // Error en la integración
            casoToUpdate.Status = 'En Revisión';
            // Se puede agregar un flag de error de integración en el futuro
        }
        
        try {
            update casoToUpdate;
            
            // Agregar un comentario al caso con el detalle
            CaseComment comment = new CaseComment();
            comment.ParentId = this.caseId;
            comment.CommentBody = 'Resultado de búsqueda en JDE: ' + response.message;
            insert comment;
        } catch (Exception e) {
            System.debug('Error actualizando el caso en CAZ_AclaracionPagoQueueable: ' + e.getMessage());
        }
    }
}
