public class CAZ_WS_SComplementoSalienteEstatus {
    public Boolean Success {get; set;}
    public String Mesagge {get; set;}
    public CAZ_WS_SComplementoSalienteEstatusN0 Data {get; set;}

    public CAZ_WS_SComplementoSalienteEstatus() {
        Success = false;
        Mesagge = 'Texto';
        Data = new CAZ_WS_SComplementoSalienteEstatusN0();
    }
}