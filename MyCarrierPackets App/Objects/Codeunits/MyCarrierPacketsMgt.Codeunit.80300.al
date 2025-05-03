codeunit 80300 "EEMCP My Carrier Packets Mgt."
{
    var
        MyCarrierPacketsSetup: Record "EEMCP MyCarrierPackets Setup";
        FleetrockSetup: Record "EE Fleetrock Setup";
        RestAPIMgt: Codeunit "EEMCP REST API Mgt.";
        JsonMgt: Codeunit "EE Json Mgt.";
        FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
        LoadedSetup, LoadedFleetrock : Boolean;


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

        ResponseBody := RestAPIMgt.GetResponseWithEncodedFormDataBodyAsJsonObject('POST', URL, FormData);
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
        TotalPages, PageSize, i : Integer;
    begin
        GetAndCheckSetup();
        URL := StrSubstNo('%1/api/v1/Carrier/MonitoredCarrierData?pageNumber=%2&pageSize=%3', MyCarrierPacketsSetup."Integration URL", 1, 1);
        RestAPIMgt.AddHeader(Headers, 'Authorization', StrSubstNo('Bearer %1', CheckToGetAPIToken()));

        JsonTkn := RestAPIMgt.GetResponseAsJsonToken('POST', URL, 'totalPages', Headers);
        if not TryToGetTokenAsInteger(JsonTkn, TotalPages) then begin
            JsonTkn.WriteTo(s);
            Error('Unable to get record count from response:\%1', s);
        end;
        PageSize := 5000;
        TotalPages := Round(TotalPages / PageSize, 1, '>');
        for i := 1 to TotalPages do begin
            URL := StrSubstNo('%1/api/v1/Carrier/MonitoredCarriers?pageNumber=%2&pagesize=%3', MyCarrierPacketsSetup."Integration URL", i, PageSize);
            JsonArry := RestAPIMgt.GetResponseAsJsonArray(URL, '', 'POST', JsonBody, Headers);
            InsertCarriers(JsonArry);
        end;

        Carrier.SetCurrentKey("Requires Update");
        Carrier.SetRange("Requires Update", true);
        if MyCarrierPacketsSetup."Monitored Carrier Cutoff" <> 0DT then
            Carrier.SetFilter("Last Modifued At", '>=%1', MyCarrierPacketsSetup."Monitored Carrier Cutoff");
        if Carrier.FindSet(true) then
            repeat
                GetCarrierData(Carrier, Headers);
                CreateAndUpdateVendorFromCarrier(Carrier, false);
            until Carrier.Next() = 0;
    end;


    local procedure InsertCarriers(var CarrierJsonArray: JsonArray): Boolean
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



    procedure GetCarrierData(var Carrier: Record "EEMCP Carrier")
    var
        Headers: HttpHeaders;
    begin
        RestAPIMgt.AddHeader(Headers, 'Authorization', StrSubstNo('Bearer %1', CheckToGetAPIToken()));
        GetCarrierData(Carrier, Headers);
    end;


    local procedure GetCarrierData(var Carrier: Record "EEMCP Carrier"; var Headers: HttpHeaders)
    var
        CarrierData: Record "EEMCP Carrier Data";
        JsonBody, CarrierJsonObj : JsonObject;
        JsonArry: JsonArray;
        JsonTkn: JsonToken;
        RecVar: Variant;
        URL: Text;
    begin
        URL := StrSubstNo('%1/api/v1/carrier/getcustomerpacketwithsw?DOTNumber=%2', MyCarrierPacketsSetup."Integration URL", Carrier."DOT No.");
        CarrierJsonObj := RestAPIMgt.GetResponseAsJsonObject('POST', URL, '', JsonBody, Headers);

        if not CarrierData.Get(Carrier."DOT No.") then begin
            CarrierData.Init();
            CarrierData."DOT No." := Carrier."DOT No.";
            CarrierData."Docket No." := Carrier."Docket No.";
            CarrierData.Insert(false);
        end;
        RecVar := CarrierData;
        FleetrockMgt.PopulateStagingTable(RecVar, CarrierJsonObj, Database::"EEMCP Carrier Data", CarrierData.FieldNo(LegalName), true);
        if CarrierJsonObj.Contains('CarrierPaymentInfo') then
            if CarrierJsonObj.Get('CarrierPaymentInfo', JsonTkn) and not IsJsonTokenNull(JsonTkn) then begin
                JsonBody := JsonTkn.AsObject();
                FleetrockMgt.PopulateStagingTable(RecVar, JsonBody, Database::"EEMCP Carrier Data", CarrierData.FieldNo(BankRoutingNumber), true);
            end;
        if CarrierJsonObj.Contains('FactoringRemit') then
            if CarrierJsonObj.Get('FactoringRemit', JsonTkn) and not IsJsonTokenNull(JsonTkn) then begin
                JsonBody := JsonTkn.AsObject();
                FleetrockMgt.PopulateStagingTable(RecVar, JsonBody, Database::"EEMCP Carrier Data", CarrierData.FieldNo(FactoringCompanyID), true);
            end;
        CarrierData := RecVar;
        if CarrierJsonObj.Contains('CarrierPaymentTypes') then
            if CarrierJsonObj.Get('CarrierPaymentTypes', JsonTkn) and not IsJsonTokenNull(JsonTkn) then begin
                JsonArry := JsonTkn.AsArray();
                if JsonArry.Get(0, JsonTkn) then begin
                    JsonBody := JsonTkn.AsObject();
                    if JsonBody.Get('PaymentType', JsonTkn) then begin
                        JsonBody := JsonTkn.AsObject();
                        CarrierData.CarrierPaymentType := JsonMgt.GetJsonValueAsText(JsonBody, 'Type');
                    end;
                end;
            end;
        if CarrierJsonObj.Contains('CarrierPaymentTerms') then
            if CarrierJsonObj.Get('CarrierPaymentTerms', JsonTkn) and not IsJsonTokenNull(JsonTkn) then begin
                JsonArry := JsonTkn.AsArray();
                if JsonArry.Get(0, JsonTkn) then begin
                    JsonBody := JsonTkn.AsObject();
                    if JsonBody.Get('PaymentTerm', JsonTkn) then begin
                        JsonBody := JsonTkn.AsObject();
                        CarrierData.PaymentTermsDays := JsonMgt.GetJsonValueAsInteger(JsonBody, 'Days');
                    end;
                end;
            end;
        CarrierData.Modify(false);
        Carrier."Requires Update" := false;
        Carrier.Modify(false);
        Commit();
    end;

    [TryFunction]
    local procedure TryToGetTokenAsInteger(var JsonTkn: JsonToken; var Result: Integer)
    begin
        Result := JsonTkn.AsValue().AsInteger();
    end;

    local procedure IsJsonTokenNull(var JsonTkn: JsonToken): Boolean
    begin
        if not JsonTkn.IsValue() then
            exit(false);
        exit(JsonTkn.AsValue().IsNull());
    end;



    local procedure GetAndCheckFleetrockSetup()
    begin
        if LoadedFleetrock then
            exit;
        FleetrockSetup.Get();
        FleetrockSetup.TestField("Vendor Posting Group");
        FleetrockSetup.TestField("Tax Area Code");
        LoadedFleetrock := true;
    end;

    procedure CreateAndUpdateVendorFromCarrier(var Carrier: Record "EEMCP Carrier"; ForceUpdate: Boolean)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        CarrierData: Record "EEMCP Carrier Data";

        CountryRegion: Record "Country/Region";
        Currency: Record Currency;
        s: Text;
    begin
        GetAndCheckFleetrockSetup();

        if ForceUpdate then
            Carrier."Requires Update" := true;
        if not CarrierData.Get(Carrier."DOT No.") or Carrier."Requires Update" then
            GetCarrierData(Carrier);
        if not CarrierData.Get(Carrier."DOT No.") then
            Error('Carrier data not found for DOT No. %1', Carrier."DOT No.");

        if not Vendor.Get(Carrier."Docket No.") then begin
            Vendor.Init();
            Vendor."No." := Carrier."Docket No.";
            Vendor.Validate("No.");
            Vendor.Validate("EEMCP Dot No.", Carrier."DOT No.");
            Vendor.Insert(true);
        end;
        Vendor.Validate("Vendor Posting Group", FleetrockSetup."Vendor Posting Group");
        Vendor.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
        Vendor.Validate("Tax Liable", true);
        if CarrierData.PaymentTermsDays > 0 then
            Vendor.Validate("Payment Terms Code", FleetrockMgt.GetPaymentTerms(CarrierData.PaymentTermsDays));
        Vendor."Name" := CopyStr(CarrierData.LegalName, 1, MaxStrLen(Vendor."Name"));
        Vendor."Name 2" := CopyStr(CarrierData.DBAName, 1, MaxStrLen(Vendor."Name 2"));
        Vendor.Address := CopyStr(CarrierData.Address1, 1, MaxStrLen(Vendor.Address));
        Vendor."Address 2" := CopyStr(CarrierData.Address2, 1, MaxStrLen(Vendor."Address 2"));
        Vendor.City := CopyStr(CarrierData.City, 1, MaxStrLen(Vendor.City));
        Vendor."Post Code" := CopyStr(CarrierData.Zipcode, 1, MaxStrLen(Vendor."Post Code"));
        s := CopyStr(CarrierData.Country, 1, MaxStrLen(Vendor."Country/Region Code"));
        if not CountryRegion.Get(CopyStr(CarrierData.Country, 1, MaxStrLen(Vendor."Country/Region Code"))) then begin
            CountryRegion.SetRange(Name, CopyStr(CarrierData.Country, 1, MaxStrLen(CountryRegion.Name)));
            if CountryRegion.FindFirst() then
                Vendor.Validate("Country/Region Code", CountryRegion.Code);
        end else
            Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor."Phone No." := CopyStr(CarrierData.Phone, 1, MaxStrLen(Vendor."Phone No."));
        Vendor."Mobile Phone No." := CopyStr(CarrierData.CellPhone, 1, MaxStrLen(Vendor."Mobile Phone No."));
        Vendor."E-Mail" := CopyStr(CarrierData.Email, 1, MaxStrLen(Vendor."E-Mail"));
        if CarrierData.RemitCurrency <> '' then begin
            s := CopyStr(CarrierData.RemitCurrency, 1, MaxStrLen(Vendor."Currency Code"));
            if Currency.Get(s) then
                Vendor.Validate("Currency Code", Currency.Code);
        end;
        Vendor.Modify(true);

        if (CarrierData.BankName <> '') or (CarrierData.CarrierPaymentType = 'ACH') then begin
            s := CopyStr(CarrierData.BankName, 1, MaxStrLen(VendorBankAccount.Code));
            if s = '' then
                s := Vendor."No.";
            if not VendorBankAccount.Get(Vendor."No.", s) then begin
                VendorBankAccount.Init();
                VendorBankAccount.Validate("Vendor No.", Vendor."No.");
                VendorBankAccount.Validate(Code, s);
                VendorBankAccount.Insert(true);
            end;
            VendorBankAccount.Name := CopyStr(CarrierData.BankAccountName, 1, MaxStrLen(VendorBankAccount.Name));
            VendorBankAccount.Address := CopyStr(CarrierData.RemitAddress1, 1, MaxStrLen(VendorBankAccount.Address));
            VendorBankAccount."Address 2" := CopyStr(CarrierData.RemitAddress2, 1, MaxStrLen(VendorBankAccount."Address 2"));
            VendorBankAccount.City := CopyStr(CarrierData.RemitCity, 1, MaxStrLen(VendorBankAccount.City));
            VendorBankAccount."Post Code" := CopyStr(CarrierData.RemitZipcode, 1, MaxStrLen(VendorBankAccount."Post Code"));
            VendorBankAccount.County := CopyStr(CarrierData.RemitState, 1, MaxStrLen(VendorBankAccount.County));
            s := CopyStr(CarrierData.RemitCountry, 1, MaxStrLen(VendorBankAccount."Country/Region Code"));
            if not CountryRegion.Get(s) then begin
                CountryRegion.SetRange(Name, s);
                if CountryRegion.FindFirst() then
                    VendorBankAccount.Validate("Country/Region Code", CountryRegion.Code);
            end else
                VendorBankAccount.Validate("Country/Region Code", CountryRegion.Code);

            VendorBankAccount."Phone No." := CopyStr(CarrierData.BankPhone, 1, MaxStrLen(VendorBankAccount."Phone No."));
            VendorBankAccount."E-Mail" := CopyStr(CarrierData.RemitEmail, 1, MaxStrLen(VendorBankAccount."E-Mail"));
            VendorBankAccount."Bank Account No." := CopyStr(CarrierData.BankAccountNumber, 1, MaxStrLen(VendorBankAccount."Bank Account No."));
            VendorBankAccount."Bank Branch No." := CopyStr(CarrierData.BankRoutingNumber, 1, MaxStrLen(VendorBankAccount."Bank Branch No."));
            if Vendor."Currency Code" <> '' then
                VendorBankAccount.Validate("Currency Code", Vendor."Currency Code");
            VendorBankAccount.Modify(true);
        end;

        //place at end and reloads Vendor so as to not interfere with code in base app to set Vendor Payment Method
        if CarrierData.CarrierPaymentType = 'ACH' then begin
            VendorBankAccount."Use for Electronic Payments" := true;
            VendorBankAccount.Modify(true);
            Vendor.Get(VendorBankAccount."Vendor No.");
            Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
            Vendor.Modify(true);
        end;

        Commit();
    end;

}