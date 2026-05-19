public interface CAZ_IJDEAclaracionService {
    /**
     * Busca los abonos/facturas en JDE usando la clave de cliente y el número de factura.
     */
    CAZ_JDEAclaracionResponse consultarAbono(String claveCliente, String numeroFactura);
}
