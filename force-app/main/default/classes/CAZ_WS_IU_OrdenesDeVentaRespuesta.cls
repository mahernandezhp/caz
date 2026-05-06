global class CAZ_WS_IU_OrdenesDeVentaRespuesta {
    global Boolean Success {get; set;}
    global String Mesagge {get; set;}
    global String Data {get; set;}

    global CAZ_WS_IU_OrdenesDeVentaRespuesta() {
        Success = false;
        Mesagge = '';
        Data = null;
    }
}