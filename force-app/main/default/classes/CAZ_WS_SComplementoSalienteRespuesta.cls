public class CAZ_WS_SComplementoSalienteRespuesta {
    public Boolean Success {get; set;}
    public String Mesagge {get; set;}
    public CAZ_WS_SComplementoSalienteEstatus Data {get; set;}

    public CAZ_WS_SComplementoSalienteRespuesta() {
        Success = false;
        Mesagge = null;
        Data = new CAZ_WS_SComplementoSalienteEstatus();
    }
}