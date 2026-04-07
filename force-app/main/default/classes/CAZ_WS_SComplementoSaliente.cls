public class CAZ_WS_SComplementoSaliente {
    public String Sucursal {get; set;}
    public String TipoOrden {get; set;}
    public Integer Distribuidor {get; set;}
    public String Fecha {get; set;}
    public Integer Cantidad {get; set;}
    public String Articulo {get; set;}
    public String NoSalesForce{get; set;}

    public CAZ_WS_SComplementoSaliente() {
        Sucursal = null;
        TipoOrden = null;
        Distribuidor = 0;
        Fecha = '31/12/2000';
        Cantidad = 0;
        Articulo = 'Texto';
        NoSalesForce = '1234567890';
    }
}