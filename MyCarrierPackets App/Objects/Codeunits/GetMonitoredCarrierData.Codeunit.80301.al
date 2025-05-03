codeunit 80301 "EEMCP Get Monitored Data"
{
    TableNo = "Name/Value Buffer";

    trigger OnRun()
    var
        CarrierData: Record "EEMCP Carrier Data";
        MCPMgt: Codeunit "EEMCP My Carrier Packets Mgt.";
        RestAPIMgt: Codeunit "EE REST API Mgt.";
        JsonMgt: Codeunit "EE JSON Mgt.";
        Headers: HttpHeaders;
        JsonArry: JsonArray;
        JsonBody, CarrierJsonObj : JsonObject;
        JsonTkn: JsonToken;
        DocketNumber: Text;
    begin
        if Rec."Value Long" = '' then
            exit;
        RestAPIMgt.AddHeader(Headers, 'Authorization', StrSubstNo('Bearer %1', MCPMgt.CheckToGetAPIToken()));
        JsonArry := RestAPIMgt.GetResponseAsJsonArray(Rec."Value Long", 'data', 'POST', JsonBody, Headers);

        foreach JsonTkn in JsonArry do begin
            CarrierJsonObj := JsonTkn.AsObject();

            DocketNumber := CopyStr(JsonMgt.GetJsonValueAsText(CarrierJsonObj, 'docketNumber'), 1, MaxStrLen(CarrierData."Docket No."));
            if DocketNumber <> '' then
                if not CarrierData.Get(DocketNumber) then begin
                    CarrierData.Init();
                    CarrierData."Docket No." := DocketNumber;
                    CarrierData.Insert(false);
                end;
        end;
    end;
}