public with sharing class CAZ_MultipagosSignatureService {

    /**
     * ----------------------------------------------------------------------------
     * Clase: CAZ_MultipagosSignatureService
     * ----------------------------------------------------------------------------
     * Propósito:
     * Centraliza la lógica de generación y validación de firmas criptográficas
     * requeridas por la integración con Multipagos.
     *
     * Responsabilidades principales:
     * 1. Generar la firma del request que Salesforce enviará a Multipagos.
     * 2. Generar la firma esperada del response recibido desde Multipagos.
     * 3. Validar si la firma recibida coincide con la calculada localmente.
     *
     * Alcance:
     * - Esta clase no crea pagos.
     * - Esta clase no consulta metadata.
     * - Esta clase no realiza callouts.
     * - Esta clase solo encapsula lógica criptográfica y validaciones básicas.
     *
     * Consideraciones:
     * - Usa HMAC SHA-256 mediante Crypto.generateMac().
     * - Devuelve la firma en hexadecimal minúsculo.
     * - Normaliza el monto a 2 decimales para garantizar consistencia.
     * - Está pensada para ser reutilizada desde el servicio de pagos.
     * ----------------------------------------------------------------------------
     */

    private static final String LOG_PREFIX = 'CAZ_MultipagosSignatureService';

    /**
     * ----------------------------------------------------------------------------
     * Método: generateRequestSignature
     * ----------------------------------------------------------------------------
     * Propósito:
     * Generar la firma del request que será enviada a Multipagos.
     *
     * Regla de negocio:
     * La cadena base se construye concatenando:
     * - multipagosOrder
     * - multipagosReference
     * - amount normalizado a 2 decimales
     *
     * Parámetros:
     * @param multipagosOrder      Identificador de orden enviado como mp_order.
     * @param multipagosReference  Referencia enviada como mp_reference.
     * @param amount               Monto enviado como mp_amount.
     * @param secretKey            Llave secreta usada para HMAC SHA-256.
     *
     * Retorno:
     * @return Firma en formato hexadecimal minúsculo.
     *
     * Excepciones:
     * Lanza AuraHandledException si falta un dato obligatorio.
     * ----------------------------------------------------------------------------
     */
    public static String generateRequestSignature(
        String multipagosOrder,
        String multipagosReference,
        Decimal amount,
        String secretKey
    ) {
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | generateRequestSignature | Inicio');
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateRequestSignature | multipagosOrder=' + multipagosOrder);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateRequestSignature | multipagosReference=' + multipagosReference);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateRequestSignature | amount=' + amount);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateRequestSignature | secretKeyProvided=' + !String.isBlank(secretKey));

        validateRequired(multipagosOrder, 'multipagosOrder');
        validateRequired(multipagosReference, 'multipagosReference');
        validateRequired(secretKey, 'secretKey');
        validateAmount(amount);

        String normalizedAmount = normalizeAmount(amount);
        String raw = multipagosOrder + multipagosReference + normalizedAmount;

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateRequestSignature | normalizedAmount=' + normalizedAmount);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateRequestSignature | rawString=' + raw);

        String signature = generateHmacSha256Hex(raw, secretKey);

        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | generateRequestSignature | Firma generada correctamente');
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateRequestSignature | signature=' + signature);

        return signature;
    }

    /**
     * ----------------------------------------------------------------------------
     * Método: generateResponseSignature
     * ----------------------------------------------------------------------------
     * Propósito:
     * Generar la firma esperada del response recibido desde Multipagos.
     *
     * Regla de negocio:
     * La cadena base se construye concatenando:
     * - multipagosOrder
     * - multipagosReference
     * - amount normalizado a 2 decimales
     * - authorization
     *
     * Parámetros:
     * @param multipagosOrder      Identificador de orden recibido o esperado.
     * @param multipagosReference  Referencia recibida o esperada.
     * @param amount               Monto asociado a la transacción.
     * @param authorization        Número de autorización recibido.
     * @param secretKey            Llave secreta usada para HMAC SHA-256.
     *
     * Retorno:
     * @return Firma esperada en formato hexadecimal minúsculo.
     *
     * Excepciones:
     * Lanza AuraHandledException si falta un dato obligatorio.
     * ----------------------------------------------------------------------------
     */
    public static String generateResponseSignature(
        String multipagosOrder,
        String multipagosReference,
        Decimal amount,
        String authorization,
        String secretKey
    ) {
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | generateResponseSignature | Inicio');
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateResponseSignature | multipagosOrder=' + multipagosOrder);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateResponseSignature | multipagosReference=' + multipagosReference);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateResponseSignature | amount=' + amount);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateResponseSignature | authorization=' + authorization);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateResponseSignature | secretKeyProvided=' + !String.isBlank(secretKey));

        validateRequired(multipagosOrder, 'multipagosOrder');
        validateRequired(multipagosReference, 'multipagosReference');
        validateRequired(authorization, 'authorization');
        validateRequired(secretKey, 'secretKey');
        validateAmount(amount);

        String normalizedAmount = normalizeAmount(amount);
        String raw = multipagosOrder + multipagosReference + normalizedAmount + authorization;

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateResponseSignature | normalizedAmount=' + normalizedAmount);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateResponseSignature | rawString=' + raw);

        String signature = generateHmacSha256Hex(raw, secretKey);

        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | generateResponseSignature | Firma generada correctamente');
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateResponseSignature | signature=' + signature);

        return signature;
    }

    /**
     * ----------------------------------------------------------------------------
     * Método: isResponseSignatureValid
     * ----------------------------------------------------------------------------
     * Propósito:
     * Validar si la firma recibida desde Multipagos coincide con la firma
     * calculada localmente en Salesforce.
     *
     * Flujo:
     * 1. Verifica que la firma recibida no venga vacía.
     * 2. Recalcula la firma esperada usando los datos de la transacción.
     * 3. Compara ambas firmas en minúsculas.
     *
     * Parámetros:
     * @param multipagosOrder      Identificador de orden.
     * @param multipagosReference  Referencia de la transacción.
     * @param amount               Monto de la transacción.
     * @param authorization        Número de autorización recibido.
     * @param secretKey            Llave secreta.
     * @param receivedSignature    Firma recibida desde Multipagos.
     *
     * Retorno:
     * @return true si la firma coincide; false en caso contrario.
     * ----------------------------------------------------------------------------
     */
    public static Boolean isResponseSignatureValid(
        String multipagosOrder,
        String multipagosReference,
        Decimal amount,
        String authorization,
        String secretKey,
        String receivedSignature
    ) {
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | isResponseSignatureValid | Inicio');
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | isResponseSignatureValid | receivedSignature=' + receivedSignature);

        if (String.isBlank(receivedSignature)) {
            System.debug(LoggingLevel.WARN, LOG_PREFIX + ' | isResponseSignatureValid | La firma recibida está vacía');
            return false;
        }

        String expectedSignature = generateResponseSignature(
            multipagosOrder,
            multipagosReference,
            amount,
            authorization,
            secretKey
        );

        String normalizedReceivedSignature = receivedSignature.trim().toLowerCase();
        Boolean isValid = expectedSignature == normalizedReceivedSignature;

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | isResponseSignatureValid | expectedSignature=' + expectedSignature);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | isResponseSignatureValid | normalizedReceivedSignature=' + normalizedReceivedSignature);
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | isResponseSignatureValid | isValid=' + isValid);

        return isValid;
    }

    /**
     * ----------------------------------------------------------------------------
     * Método: normalizeAmount
     * ----------------------------------------------------------------------------
     * Propósito:
     * Convertir el monto a una representación consistente con 2 decimales.
     *
     * Ejemplos:
     * - 1500    -> 1500.00
     * - 89.5    -> 89.50
     * - 10.257  -> 10.26
     *
     * Parámetros:
     * @param amount Monto a normalizar.
     *
     * Retorno:
     * @return Monto en formato String con 2 decimales.
     * ----------------------------------------------------------------------------
     */
    private static String normalizeAmount(Decimal amount) {
        Decimal scaled = amount.setScale(2);
        String normalized = String.valueOf(scaled);

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | normalizeAmount | original=' + amount + ' | normalized=' + normalized);

        return normalized;
    }

    /**
     * ----------------------------------------------------------------------------
     * Método: generateHmacSha256Hex
     * ----------------------------------------------------------------------------
     * Propósito:
     * Ejecutar la operación criptográfica HMAC SHA-256 sobre la cadena base
     * usando la llave secreta proporcionada.
     *
     * Parámetros:
     * @param rawValue  Cadena base que será firmada.
     * @param secretKey Llave secreta usada para la firma.
     *
     * Retorno:
     * @return Firma en formato hexadecimal minúsculo.
     * ----------------------------------------------------------------------------
     */
    private static String generateHmacSha256Hex(String rawValue, String secretKey) {
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateHmacSha256Hex | rawValue=' + rawValue);
        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateHmacSha256Hex | secretKeyLength=' + (secretKey == null ? 0 : secretKey.length()));

        Blob mac = Crypto.generateMac(
            'HmacSHA256',
            Blob.valueOf(rawValue),
            Blob.valueOf(secretKey)
        );

        String hexSignature = EncodingUtil.convertToHex(mac).toLowerCase();

        System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' | generateHmacSha256Hex | hexSignature=' + hexSignature);

        return hexSignature;
    }

    /**
     * ----------------------------------------------------------------------------
     * Método: validateRequired
     * ----------------------------------------------------------------------------
     * Propósito:
     * Validar que un parámetro String obligatorio contenga valor.
     *
     * Parámetros:
     * @param value      Valor a validar.
     * @param fieldName  Nombre lógico del parámetro para el mensaje de error.
     *
     * Excepciones:
     * Lanza AuraHandledException si el valor está vacío o nulo.
     * ----------------------------------------------------------------------------
     */
    private static void validateRequired(String value, String fieldName) {
        if (String.isBlank(value)) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | validateRequired | Parámetro vacío: ' + fieldName);
            throw new AuraHandledException('El parámetro ' + fieldName + ' es obligatorio.');
        }
    }

    /**
     * ----------------------------------------------------------------------------
     * Método: validateAmount
     * ----------------------------------------------------------------------------
     * Propósito:
     * Validar que el monto obligatorio no venga nulo.
     *
     * Parámetros:
     * @param amount Monto a validar.
     *
     * Excepciones:
     * Lanza AuraHandledException si el monto es nulo.
     * ----------------------------------------------------------------------------
     */
    private static void validateAmount(Decimal amount) {
        if (amount == null) {
            System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | validateAmount | El monto es nulo');
            throw new AuraHandledException('El monto es obligatorio.');
        }
    }
}