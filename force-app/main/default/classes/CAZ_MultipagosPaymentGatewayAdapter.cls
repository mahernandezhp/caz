/**
 * ============================================================================
 * Clase: CAZ_MultipagosPaymentGatewayAdapter
 * ============================================================================
 * Propósito:
 * Adapter stub requerido por PaymentGatewayProvider para registrar
 * el gateway "Multipagos BBVA" en Salesforce Payments.
 *
 * IMPORTANTE:
 * Este adapter NO se usa para callouts reales. El flujo Multipagos es
 * browser-to-browser (form POST), no server-to-server. Esta clase existe
 * únicamente para satisfacer el contrato de PaymentGatewayProvider y
 * permitir crear el registro PaymentGateway que vincula los Payment records.
 *
 * @author  Arquitecto Salesforce
 * @version 1.0
 * ============================================================================
 */
global with sharing class CAZ_MultipagosPaymentGatewayAdapter implements commercepayments.PaymentGatewayAdapter {

    private static final String LOG_PREFIX = 'CAZ_MultipagosPaymentGatewayAdapter';

    /**
     * ============================================================================
     * Método: processRequest
     * ============================================================================
     * Propósito:
     * Método requerido por la interfaz PaymentGatewayAdapter. No se utiliza
     * en el flujo Multipagos (el pago se procesa vía form POST en el browser).
     * Retorna siempre un response indicando que este adapter no soporta
     * callouts directos.
     *
     * Parámetros:
     * @param gatewayContext Contexto del gateway proporcionado por Salesforce
     *
     * Retorno:
     * @return commercepayments.GatewayResponse con error informativo
     * ============================================================================
     */
    global commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext) {
        System.debug(LoggingLevel.WARN, LOG_PREFIX + ' | processRequest | Este adapter es un stub. Multipagos usa form POST, no callouts server-to-server.');

        commercepayments.SaleResponse saleResponse = new commercepayments.SaleResponse();
        saleResponse.setGatewayResultCode('UNSUPPORTED');
        saleResponse.setGatewayMessage('Multipagos usa form POST browser-to-browser. Este adapter es un stub de registro.');
        saleResponse.setSalesforceResultCodeInfo(
            new commercepayments.SalesforceResultCodeInfo(
                commercepayments.SalesforceResultCode.Decline
            )
        );

        return saleResponse;
    }
}