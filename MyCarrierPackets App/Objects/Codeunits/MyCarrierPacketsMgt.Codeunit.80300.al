codeunit 80300 "EEMCP My Carrier Packets Mgt."
{
    var
        MyCarrierPacketsSetup: Record "EEMCP MyCarrierPackets Setup";
        RestAPIMgt: Codeunit "EE REST API Mgt.";
        JsonMgt: Codeunit "EE Json Mgt.";
        LoadedSetup: Boolean;


    local procedure GetAndCheckSetup()
    begin
        if LoadedSetup then
            exit;
        MyCarrierPacketsSetup.Get();
        MyCarrierPacketsSetup.TestField("Integration URL");
        MyCarrierPacketsSetup.TestField(Username);
        MyCarrierPacketsSetup.TestField(Password);
        LoadedSetup := true;
    end;

    procedure CheckToGetAPIToken(): Text
    var
        ResponseText: Text;
    begin
        GetAndCheckSetup();
        if (MyCarrierPacketsSetup."API Token" <> '') and (MyCarrierPacketsSetup."API Token Expiry DateTime" > CurrentDateTime()) then
            exit(MyCarrierPacketsSetup."API Token");
        exit(CheckToGetAPIToken(MyCarrierPacketsSetup));
    end;

    procedure CheckToGetAPIToken(var MyCarrierPacketsSetup: Record "EEMCP MyCarrierPackets Setup"): Text
    var
        FormData: Dictionary of [Text, Text];
        JsonTkn: JsonToken;
        ResponseBody: JsonObject;
        Expires: DateTime;
        URL, s : Text;
    begin
        URL := StrSubstNo('%1/token', MyCarrierPacketsSetup."Integration URL");

        FormData.Add('grant_type', 'password');
        FormData.Add('username', MyCarrierPacketsSetup.Username);
        FormData.Add('password', MyCarrierPacketsSetup.Password);

        ResponseBody := GetResponseWithEncodedFormDataBodyAsJsonObject('POST', URL, FormData);
        if ResponseBody.Get('access_token', JsonTkn) then begin
            JsonTkn.WriteTo(s);
            MyCarrierPacketsSetup.Validate("API Token", s.Replace('"', ''));
        end else
            Error('Token %1 not found in response:\%2', 'access_token', ResponseBody);
        if ResponseBody.Get('refresh_token', JsonTkn) then begin
            JsonTkn.WriteTo(s);
            MyCarrierPacketsSetup.Validate("API Refresh Token", s.Replace('"', ''));
        end;
        if ResponseBody.Get('.expires', JsonTkn) then begin
            JsonTkn.WriteTo(s);
            if Evaluate(Expires, s.Replace('"', '')) then
                MyCarrierPacketsSetup.Validate("API Token Expiry DateTime", Expires);
        end;

        exit(MyCarrierPacketsSetup."API Token");
    end;






    procedure GetCompletedPackets(FromDate: Date; ToDate: Date): JsonArray
    var
        PassedHeaders: HttpHeaders;
        JsonArry: JsonArray;
        URL: Text;
        FromDateTime, ToDateTime : DateTime;
    begin
        GetAndCheckSetup();
        if MyCarrierPacketsSetup."Last Packet DateTime" <> 0DT then begin
            URL := StrSubstNo('%1/api/v1/Carrier/completedpackets?fromDate=%2&toDate=%3', MyCarrierPacketsSetup."Integration URL", FormatDateTime(MyCarrierPacketsSetup."Last Packet DateTime"), FormatDateTime(CurrentDateTime()))
        end else
            URL := StrSubstNo('%1/api/v1/Carrier/completedpackets?fromDate=%2&toDate=%3', MyCarrierPacketsSetup."Integration URL", Format(FromDate), Format(ToDate));
        RestAPIMgt.AddHeader(PassedHeaders, 'Authorization', StrSubstNo('Bearer %1', CheckToGetAPIToken()));
        MyCarrierPacketsSetup."Last Packet DateTime" := CurrentDateTime();
        MyCarrierPacketsSetup.Modify(true);
        exit(RestAPIMgt.GetResponseAsJsonArray(URL, 'POST', PassedHeaders));
    end;

    local procedure FormatDateTime(DateTime: DateTime): Text
    var
        TempDate: Date;
        TempTime: Time;
    begin
        TempDate := DateTime.Date();
        TempTime := DateTime.Time();

        exit(StrSubstNo('%1-%2-%3T%4:%5:%6', TempDate.Year(), PadLeft(Format(TempDate.Month()), 2), PadLeft(Format(TempDate.Day()), 2),
            PadLeft(Format(TempTime.Hour()), 2), PadLeft(Format(TempTime.Minute()), 2), PadLeft(Format(TempTime.Second()), 2)));
    end;

    local procedure PadLeft(Input: Text; Length: Integer): Text
    var
        Output: Text;
    begin
        if (Length <= 0) or (StrLen(Input) >= Length) or (Input = '') then
            exit(Input);
        Output := Input;
        while StrLen(Output) < Length do
            Output := '0' + Output;
        exit(Output);
    end;






    procedure GetMonitoredCarrierData()
    var
        Carrier: Record "EEMCP Carrier";

        Headers: HttpHeaders;
        JsonArry: JsonArray;
        JsonBody: JsonObject;
        JsonTkn: JsonToken;
        URL, s : Text;
        TotalPages, PageSize, i, SessionId : Integer;


        start: DateTime;
        Window: Dialog;
    begin
        //https://api.mycarrierpackets.com/api/v1/Carrier/MonitoredCarrierData?pageNumber=29&pageSize=500

        GetAndCheckSetup();

        //initial call to get page record count
        URL := StrSubstNo('%1/api/v1/Carrier/MonitoredCarrierData?pageNumber=%2&pageSize=%3', MyCarrierPacketsSetup."Integration URL", 1, 1);
        RestAPIMgt.AddHeader(Headers, 'Authorization', StrSubstNo('Bearer %1', CheckToGetAPIToken()));

        JsonTkn := RestAPIMgt.GetResponseAsJsonToken('POST', URL, 'totalPages', Headers);
        if not TryToGetTokenAsInteger(JsonTkn, TotalPages) then begin
            JsonTkn.WriteTo(s);
            Error('Unable to get record count from response:\%1', s);
        end;
        PageSize := 5000;
        TotalPages := Round(TotalPages / PageSize, 1, '>');

        //https://api.mycarrierpackets.com/api/v1/Carrier/MonitoredCarriers?pageNumber=3&pagesize=5000

        if GuiAllowed then begin
            start := CurrentDateTime();
            Window.Open('Getting Data\#1##\#2##');
            Carrier.Reset();
            Carrier.DeleteAll(false);
            for i := 1 to TotalPages do begin
                Window.Update(1, StrSubstNo('%1 of %2', i, TotalPages));
                Window.Update(2, CurrentDateTime - start);
                // URL := StrSubstNo('%1/api/v1/Carrier/MonitoredCarrierData?pageNumber=%2&pageSize=%3', MyCarrierPacketsSetup."Integration URL", i, PageSize);
                // JsonArry := RestAPIMgt.GetResponseAsJsonArray(URL, 'data', 'POST', JsonBody, Headers);
                URL := StrSubstNo('%1/api/v1/Carrier/MonitoredCarriers?pageNumber=%2&pagesize=%3', MyCarrierPacketsSetup."Integration URL", i, PageSize);
                JsonArry := RestAPIMgt.GetResponseAsJsonArray(URL, '', 'POST', JsonBody, Headers);
                InsertCarrierData(JsonArry);
                Window.Update(2, CurrentDateTime - start);
            end;
            Window.Close();
            if not Confirm('%1, %2', false, Carrier.Count, CurrentDateTime - start) then
                exit;
        end else
            for i := 1 to TotalPages do begin
                // URL := StrSubstNo('%1/api/v1/Carrier/MonitoredCarrierData?pageNumber=%2&pageSize=%3', MyCarrierPacketsSetup."Integration URL", i, PageSize);
                // JsonArry := RestAPIMgt.GetResponseAsJsonArray(URL, 'data', 'POST', JsonBody, Headers);
                URL := StrSubstNo('%1/api/v1/Carrier/MonitoredCarriers?pageNumber=%2&pagesize=%3', MyCarrierPacketsSetup."Integration URL", i, PageSize);
                JsonArry := RestAPIMgt.GetResponseAsJsonArray(URL, '', 'POST', JsonBody, Headers);
                InsertCarrierData(JsonArry);
            end;

        Carrier.SetCurrentKey("Requires Update");
        Carrier.SetRange("Requires Update", true);
        if Carrier.FindSet(true) then
            repeat
                GetCarrierData(Carrier, Headers);
            until Carrier.Next() = 0;
    end;


    local procedure InsertCarrierData(var CarrierJsonArray: JsonArray): Boolean
    var
        Carrier: Record "EEMCP Carrier";
        CarrierJsonObj: JsonObject;
        JsonTkn: JsonToken;
        DocketNumber: Text;
        DOTNumber: Integer;
        LastModified: DateTime;
    begin
        foreach JsonTkn in CarrierJsonArray do begin
            CarrierJsonObj := JsonTkn.AsObject();
            DOTNumber := JsonMgt.GetJsonValueAsInteger(CarrierJsonObj, 'DOTNumber');
            LastModified := JsonMgt.GetJsonValueAsDateTime(CarrierJsonObj, 'LastModifiedDate');
            if (DOTNumber <> 0) and (LastModified <> 0DT) then
                if not Carrier.Get(DOTNumber) then begin
                    Carrier.Init();
                    Carrier."DOT No." := DOTNumber;
                    Carrier."Docket No." := CopyStr(JsonMgt.GetJsonValueAsText(CarrierJsonObj, 'DocketNumber'), 1, MaxStrLen(Carrier."Docket No."));
                    Carrier."Last Modifued At" := JsonMgt.GetJsonValueAsDateTime(CarrierJsonObj, 'LastModifiedDate');
                    Carrier."Requires Update" := true;
                    Carrier.Insert(false);
                    Carrier.SystemModifiedAt := currentDateTime();
                end else
                    if LastModified > Carrier."Last Modifued At" then begin
                        Carrier."Last Modifued At" := LastModified;
                        Carrier."Requires Update" := true;
                        Carrier.Modify(false);
                    end;
        end;
        Commit();
    end;


    local procedure GetCarrierData(var Carrier: Record "EEMCP Carrier"; var Headers: HttpHeaders)
    var
        CarrierData: Record "EEMCP Carrier Data";
        JsonBody: JsonObject;
        JsonArry: JsonArray;
        URL: Text;
    begin

        //https://api.mycarrierpackets.com/api/v1/carrier/getcustomerpacketwithsw?DOTNumber=4295343
        URL := StrSubstNo('%1/api/v1/carrier/getcustomerpacketwithsw?DOTNumber=%2', MyCarrierPacketsSetup."Integration URL", Carrier."DOT No.");

        JsonArry := RestAPIMgt.GetResponseAsJsonArray(URL, '', 'POST', JsonBody, Headers);


        Carrier."Requires Update" := false;
        Carrier.Modify(false);
        Commit();
    end;


    [TryFunction]
    local procedure TryToGetTokenAsInteger(var JsonTkn: JsonToken; var Result: Integer)
    begin
        Result := JsonTkn.AsValue().AsInteger();
    end;





    procedure InsertCompletedPackets(var CompletedPackets: JsonArray): Boolean
    var
        JsonTkn: JsonToken;
        PacketJsonObj: JsonObject;
    begin
        foreach JsonTkn in CompletedPackets do begin
            // LineEntryNo += 1;
            PacketJsonObj := JsonTkn.AsObject();
            // PurchLineStaging.Init();
            // PurchLineStaging."Entry No." := LineEntryNo;
            // PurchLineStaging."Header Entry No." := PurchHeaderStaging."Entry No.";
            // PurchLineStaging."Header id" := PurchHeaderStaging.id;
            // PurchLineStaging.part_id := JsonMgt.GetJsonValueAsText(LineJsonObj, 'part_id');
            // PurchLineStaging.part_number := JsonMgt.GetJsonValueAsText(LineJsonObj, 'part_number');
            // PurchLineStaging.part_description := JsonMgt.GetJsonValueAsText(LineJsonObj, 'part_description');
            // PurchLineStaging.part_system_code := JsonMgt.GetJsonValueAsText(LineJsonObj, 'part_system_code');
            // PurchLineStaging.part_type := JsonMgt.GetJsonValueAsText(LineJsonObj, 'part_type');
            // PurchLineStaging.tag := JsonMgt.GetJsonValueAsText(LineJsonObj, 'tag');
            // PurchLineStaging.part_quantity := JsonMgt.GetJsonValueAsDecimal(LineJsonObj, 'part_quantity');
            // PurchLineStaging.unit_price := JsonMgt.GetJsonValueAsDecimal(LineJsonObj, 'unit_price');
            // PurchLineStaging.line_total := JsonMgt.GetJsonValueAsDecimal(LineJsonObj, 'line_total');
            // PurchLineStaging.date_added := JsonMgt.GetJsonValueAsText(LineJsonObj, 'date_added');
            // PurchLineStaging.Insert(true);
        end;
    end;



    procedure GetResponseWithEncodedFormDataBodyAsJsonObject(Method: Text; URL: Text; var FormData: Dictionary of [Text, Text]): Variant
    var
        ResponseText: Text;
        JsonObj: JsonObject;
    begin
        if not SendEncodedFormDataRequest(Method, URL, FormData, ResponseText) then
            Error(ResponseText);
        JsonObj.ReadFrom(ResponseText);
        exit(JsonObj);
    end;

    local procedure SendEncodedFormDataRequest(Method: Text; URL: Text; var FormData: Dictionary of [Text, Text]; var ResponseText: Text): Boolean
    var
        HttpClient: HttpClient;
        Headers: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        ContentText: TextBuilder;
        i: Integer;
    begin
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method(Method);

        ContentText.Append(StrSubstNo('%1=%2', FormData.Keys.Get(1), Encode(FormData.Values.Get(1))));
        if FormData.Count() > 1 then
            for i := 2 to FormData.Count() do
                ContentText.Append(StrSubstNo('&%1=%2', FormData.Keys.Get(i), Encode(FormData.Values.Get(i))));

        Content.WriteFrom(ContentText.ToText());
        HttpRequestMessage.Content(Content);

        Content.GetHeaders(Headers);
        RestAPIMgt.AddHeader(Headers, 'charset', 'UTF-8');
        RestAPIMgt.AddHeader(Headers, 'Content-Type', 'application/x-www-form-urlencoded');

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            ResponseText := StrSubstNo('Unable to send request:\%1', GetLastErrorText());
            exit(false);
        end;

        HttpResponseMessage.Content().ReadAs(ResponseText);
        exit(HttpResponseMessage.IsSuccessStatusCode());
    end;





    local procedure Encode(Input: Text): Text
    begin
        exit(TypeHelper.UrlEncode(Input));
    end;







    var
        TypeHelper: Codeunit "Type Helper";
}