public class CAZ_WS_SComplementoBase {
    public String Sucursal {get; set;}
    public String TipoOrden {get; set;}
    public Integer Distribuidor {get; set;}
    public String Fecha {get; set;}
    public Integer Cantidad {get; set;}
    public String Articulo {get; set;}
    public String NoSalesForce{get; set;}

    public CAZ_WS_SComplementoBase() {
        Sucursal = null;
        TipoOrden = null;
        Distribuidor = 0;
        Fecha = null;
        Cantidad = 0;
        Articulo = null;
        NoSalesForce = null;
    }
}

/*
PETICION
{
  "Sucursal" : "PT90",
  "TipoOrden" : "BB",
  "Distribuidor" : "20366",
  "Fecha" : "25/03/2026",
  "Cantidad" : 50,
  "Articulo" : "TIPO CPC 40 GR",
  "NoSalesForce" : "?"
}

SUCCESS
{
  "Success" : true,
  "Mesagge" : "Operacion correcta",
  "Data" : {
    "TipoOrden" : "BB",
	"NumeroOrden" : "2234"
  }
}

ERROR
{
  "Success" : false,
  "Mesagge" : "Descripcion del error",
  "Data" : null
}
*/