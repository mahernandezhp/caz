global class CAZ_WS_IU_CuentasCamposJSON {
    // --- Asignacion directa de valores
    public Boolean CAZ_Usuario_activo {get; set;}

    public String ClaveJDE {get; set;}
    public String RFC {get; set;}
    public String CAZ_Email {get; set;}
    public String Phone {get; set;}

    public String CAZ_IdExterno {get; set;}
    public String CAZ_NombreDeLaCuenta {get; set;}

    public String CAZB_Calle {get; set;}
    public String CAZB_Ciudad {get; set;}
    public String CAZB_CodigoPostal {get; set;}
    public String CAZB_Colonia {get; set;}
    public String CAZB_Estado {get; set;}
    public String CAZB_Municipio {get; set;}
    public String CAZB_No_exterior {get; set;}
    public String CAZB_No_interior {get; set;}
    public String CAZB_Pais {get; set;}

    public String CAZS_Calle {get; set;}
    public String CAZS_Ciudad {get; set;}
    public String CAZS_CodigoPostal {get; set;}
    public String CAZS_Colonia {get; set;}
    public String CAZS_Estado {get; set;}
    public String CAZS_Municipio {get; set;}
    public String CAZS_No_exterior {get; set;}
    public String CAZS_No_interior {get; set;}
    public String CAZS_Pais {get; set;}
    
    // --- Asignacion indirecta de valores
    public String CuentaPricipal {get; set;}

    // Constructor base
    public CAZ_WS_IU_CuentasCamposJSON() {
        CAZ_Usuario_activo = false;
        //---
        ClaveJDE = null;
        RFC = null;
        CAZ_Email = null;
        Phone = null;
        // ---
        CAZ_IdExterno = null;
        CAZ_NombreDeLaCuenta = null;
        //---
        CAZB_Calle = null;
        CAZB_Ciudad = null;
        CAZB_CodigoPostal = null;
        CAZB_Colonia = null;
        CAZB_Estado = null;
        CAZB_Municipio = null;
        CAZB_No_exterior = null;
        CAZB_No_interior = null;
        CAZB_Pais = null;
        //---
        CAZS_Calle = null;
        CAZS_Ciudad = null;
        CAZS_CodigoPostal = null;
        CAZS_Colonia = null;
        CAZS_Estado = null;
        CAZS_Municipio = null;
        CAZS_No_exterior = null;
        CAZS_No_interior = null;
        //---
        cuentaPricipal = null;
    }
}