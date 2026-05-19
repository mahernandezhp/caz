public class CAZ_JDEAclaracionServiceMock implements CAZ_IJDEAclaracionService {
    
    public CAZ_JDEAclaracionResponse consultarAbono(String claveCliente, String numeroFactura) {
        CAZ_JDEAclaracionResponse response = new CAZ_JDEAclaracionResponse();
        
        // Simulación de delay de red o procesamiento si se quisiera, pero en Apex sincrono no usamos sleep.
        
        if (numeroFactura == 'ERROR500') {
            response.success = false;
            response.message = 'Error de conexión con JD Edwards';
            return response;
        }

        if (numeroFactura == 'NO_ENCONTRADO') {
            response.success = true;
            response.abonoEncontrado = false;
            response.message = 'No se encontró el abono en JD Edwards';
            return response;
        }
        
        // Simular respuesta exitosa con datos encontrados
        response.success = true;
        response.abonoEncontrado = true;
        response.montoAbono = 15000.00;
        response.fechaAbono = Date.today().addDays(-2);
        response.referencia = 'REF-' + numeroFactura;
        response.message = 'Abono encontrado exitosamente en JD Edwards';
        
        return response;
    }
}
