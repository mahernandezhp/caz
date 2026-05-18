global class CAZ_WS_IU_ContactosEstructura {
    global String IdAccount {get; set;}
    global String Distribuidor {get; set;}
    global String Nombre {get; set;}
    global String Nombre2 {get; set;}
    global String Apellidos {get; set;}
    global String Email {get; set;}
    global String Telefono {get; set;}

    global CAZ_WS_IU_ContactosEstructura() {
        IdAccount = null;
        Distribuidor = null;
        Nombre = null;
        Nombre2 = null;
        Apellidos = null;
        Email = null;
        Telefono = null;
    }
}