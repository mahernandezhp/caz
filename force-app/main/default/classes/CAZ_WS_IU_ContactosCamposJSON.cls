global class CAZ_WS_IU_ContactosCamposJSON {
    public String CAZ_Cuenta {get; set;}
  //public String CAZ_ClaveJDE{get; set;}
    public String CAZ_Nombre {get; set;}
    public String CAZ_SegundoNombre {get; set;}
    public String CAZ_Apellidos {get; set;}
    public String CAZ_Email {get; set;}
    public String CAZ_Telefono {get; set;}
    public Boolean CAZ_Factura {get; set;}
    public String CAZ_IdExterno {get; set;}

    public CAZ_WS_IU_ContactosCamposJSON() {
        CAZ_Cuenta = null;
        CAZ_Nombre = null;
        CAZ_SegundoNombre = null;
        CAZ_Apellidos = null;
        CAZ_Email = null;
        CAZ_Telefono = null;
        CAZ_Factura = false;
        CAZ_IdExterno = null;
    }
}