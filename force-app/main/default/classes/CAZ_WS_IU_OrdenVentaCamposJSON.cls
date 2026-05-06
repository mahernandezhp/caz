global class CAZ_WS_IU_OrdenVentaCamposJSON {
    public Decimal CAZ_MontoTotal {get; set;}
    public Integer CAZ_CapacidadRetiro {get; set;}
    public String CAZ_ClaveJDE {get; set;}
    public String CAZ_CreadoPor {get; set;}
    public String CAZ_Estado {get; set;}
    public String CAZ_FechaCancelacionPedido {get; set;}
    public String CAZ_FechaDeCreacion {get; set;}
    public String CAZ_FechaPedido {get; set;}
    public String CAZ_FechaUltimaModificacion {get; set;}
    public String CAZ_IdExternoA {get; set;}
    public String CAZ_NombrePedido {get; set;}
    public String CAZ_Planta {get; set;}
    public String CAZ_Producto {get; set;}
    public String CAZ_TipoDeDocumento {get; set;}	// Considerar o no
    public String CAZ_UnidadDeNegocio {get; set;}	// Considerar o no

    public CAZ_WS_IU_OrdenVentaCamposJSON() {
        CAZ_MontoTotal = 0;
        CAZ_CapacidadRetiro = 0;
        CAZ_ClaveJDE = null;
        CAZ_CreadoPor = null;
        CAZ_Estado = null;
        CAZ_FechaCancelacionPedido = null;
        CAZ_FechaDeCreacion = null;
        CAZ_FechaPedido = null;
        CAZ_FechaUltimaModificacion = null;
        CAZ_IdExternoA = null;
        CAZ_NombrePedido = null;
        CAZ_Planta = null;
        CAZ_Producto = null;
        CAZ_TipoDeDocumento = null;
        CAZ_UnidadDeNegocio = null;
    }
}