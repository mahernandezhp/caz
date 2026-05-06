global class CAZ_WS_IU_ContactosRespuesta {
    global Boolean Success {get; set;}
    global String Mesagge {get; set;}
    global String Data {get; set;}

    global CAZ_WS_IU_ContactosRespuesta() {
        Success = false;
        Mesagge = null;
        Data = null;
    }
}