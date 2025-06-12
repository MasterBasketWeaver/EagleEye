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
                    Carrier."Last Modifued At" := LastModified;
                    Carrier."Requires Update" := true;
                    Carrier.Insert(false);
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
        FleetrockMgt.PopulateStagingTable(RecVar, CarrierJsonObj, Database::"EEMCP Carrier Data", CarrierData.FieldNo(LegalName), 99, true);
        if CarrierJsonObj.Contains('CarrierPaymentInfo') then
            if CarrierJsonObj.Get('CarrierPaymentInfo', JsonTkn) and not IsJsonTokenNull(JsonTkn) then begin
                JsonBody := JsonTkn.AsObject();
                FleetrockMgt.PopulateStagingTable(RecVar, JsonBody, Database::"EEMCP Carrier Data",
                    CarrierData.FieldNo(BankRoutingNumber), CarrierData.FieldNo(RemitCurrency), true);
            end;
        if CarrierJsonObj.Contains('FactoringRemit') then
            if CarrierJsonObj.Get('FactoringRemit', JsonTkn) and not IsJsonTokenNull(JsonTkn) then begin
                JsonBody := JsonTkn.AsObject();
                FleetrockMgt.PopulateStagingTable(RecVar, JsonBody, Database::"EEMCP Carrier Data",
                    CarrierData.FieldNo(FactoringCompanyID), CarrierData.FieldNo(FactoringPhone), true);
            end;
        if CarrierJsonObj.Contains('CarrierRemit') then
            if CarrierJsonObj.Get('CarrierRemit', JsonTkn) and not IsJsonTokenNull(JsonTkn) then begin
                JsonBody := JsonTkn.AsObject();
                FleetrockMgt.PopulateStagingTable(RecVar, JsonBody, Database::"EEMCP Carrier Data",
                CarrierData.FieldNo(CarrierRemitEmail), CarrierData.FieldNo(CarrierRemitZipCode), true);
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
        if CarrierJsonObj.Contains('CarrierTINMatchings') then
            if CarrierJsonObj.Get('CarrierTINMatchings', JsonTkn) and not IsJsonTokenNull(JsonTkn) then begin
                JsonArry := JsonTkn.AsArray();
                if JsonArry.Get(0, JsonTkn) then begin
                    JsonBody := JsonTkn.AsObject();
                    CarrierData.TIN := JsonMgt.GetJsonValueAsText(JsonBody, 'TIN');
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
        FleetrockSetup.TestField("Payment Terms");
        LoadedFleetrock := true;
    end;

    procedure CreateAndUpdateVendorFromCarrier(var Carrier: Record "EEMCP Carrier"; ForceUpdate: Boolean)
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentMethod: Record "Payment Method";
        Contact: Record Contact;
        CarrierData: Record "EEMCP Carrier Data";
        CarrierData2: Record "EEMCP Carrier Data";
        Currency: Record Currency;
        CountryCode: Code[10];
        s: Text;
    begin
        GetAndCheckFleetrockSetup();

        if ForceUpdate then
            Carrier."Requires Update" := true;
        if not CarrierData.Get(Carrier."DOT No.") or Carrier."Requires Update" then
            GetCarrierData(Carrier);
        if not CarrierData.Get(Carrier."DOT No.") then
            Error('Carrier data not found for DOT No. %1', Carrier."DOT No.");

        if (Carrier."DOT No." = 0) and (Carrier."Docket No." = '') then
            Error('Carrier %1 missing both DOT No. and Docket No.', Carrier.SystemId);

        if Carrier."Vendor No." = '' then begin
            if Carrier."Docket No." <> '' then
                Carrier."Vendor No." := Carrier."Docket No.".Replace('MC', '')
            else if Carrier."DOT No." <> 0 then
                Carrier."Vendor No." := Format(Carrier."DOT No.");
            Carrier.Modify(true);
        end;

        if not Vendor.Get(Carrier."Vendor No.") then begin
            Vendor.Init();
            Vendor."No." := Carrier."Vendor No.";
            Vendor.Validate("No.");
            Vendor.Insert(true);
        end;

        if (Vendor."EEMCP Docket No." = '') and (Carrier."Docket No." <> '') then
            Vendor.Validate("EEMCP Docket No.", Carrier."Docket No.");
        if (Vendor."EEMCP Dot No." = 0) and (Carrier."DOT No." <> 0) then
            Vendor.Validate("EEMCP Dot No.", Carrier."DOT No.");
        Vendor.Validate("Vendor Posting Group", FleetrockSetup."Vendor Posting Group");
        Vendor.Validate("Tax Area Code", '');
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Payment Terms Code", FleetrockSetup."Payment Terms");
        Vendor."Name" := CopyStr(CarrierData.LegalName, 1, MaxStrLen(Vendor."Name"));
        Vendor."Name 2" := CopyStr(CarrierData.DBAName, 1, MaxStrLen(Vendor."Name 2"));

        Contact.SetRange(Name, Vendor.Name);
        Contact.SetRange("Company Name", Vendor.Name);
        Contact.DeleteAll(true);

        CountryCode := GetCountryCode(CarrierData.Country);
        if CountryCode <> '' then
            Vendor.Validate("Country/Region Code", CountryCode);
        Vendor.Address := CopyStr(CarrierData.Address1, 1, MaxStrLen(Vendor.Address));
        Vendor."Address 2" := CopyStr(CarrierData.Address2, 1, MaxStrLen(Vendor."Address 2"));
        Vendor.City := CopyStr(CarrierData.City, 1, MaxStrLen(Vendor.City));
        Vendor.County := CopyStr(CarrierData.State, 1, MaxStrLen(Vendor.County));
        Vendor."Post Code" := CopyStr(CarrierData.Zipcode, 1, MaxStrLen(Vendor."Post Code"));
        Vendor."Phone No." := CopyStr(CarrierData.Phone, 1, MaxStrLen(Vendor."Phone No."));
        Vendor."Mobile Phone No." := CopyStr(CarrierData.CellPhone, 1, MaxStrLen(Vendor."Mobile Phone No."));
        Vendor."E-Mail" := CopyStr(CarrierData.Email, 1, MaxStrLen(Vendor."E-Mail"));
        if CarrierData.RemitCurrency <> '' then begin
            s := CopyStr(CarrierData.RemitCurrency, 1, MaxStrLen(Vendor."Currency Code"));
            if Currency.Get(s) then
                Vendor.Validate("Currency Code", Currency.Code);
        end;
        Vendor."Federal ID No." := CopyStr(CarrierData.TIN, 1, MaxStrLen(Vendor."Federal ID No."));
        Vendor.Modify(true);

        if CarrierData.FactoringCompanyName = '' then
            if (CarrierData.BankAccountNumber <> '') or (CarrierData.CarrierPaymentType = 'ACH') then begin
                AddVendorBankAccount(Vendor, VendorBankAccount, CarrierData);
                Vendor.Get(Vendor."No.");
                Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
            end;

        VendorBankAccount.SetRange("Vendor No.", Vendor."No.");
        if VendorBankAccount.IsEmpty() then
            if PaymentMethod.Get('check') then
                Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);

        if Vendor."Payment Method Code" = 'ACH' then
            if CarrierData.RemitEmail <> '' then
                AddVendorDocumentLayouts(Vendor, CarrierData.RemitEmail)
            else
                if Vendor."E-Mail" <> '' then
                    AddVendorDocumentLayouts(Vendor, Vendor."E-Mail");

        Commit();
    end;


    local procedure AddVendorBankAccount(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; var CarrierData: Record "EEMCP Carrier Data")
    var
        CountryCode: Code[10];
        s: Text;
    begin
        s := 'ACH';
        if not VendorBankAccount.Get(Vendor."No.", s) then begin
            VendorBankAccount.Init();
            VendorBankAccount.Validate("Vendor No.", Vendor."No.");
            VendorBankAccount.Validate(Code, s);
            VendorBankAccount.Insert(true);
        end;

        if CarrierData.BankAccountName <> '' then
            VendorBankAccount.Name := CopyStr(CarrierData.BankAccountName, 1, MaxStrLen(VendorBankAccount.Name));
        CountryCode := GetCountryCode(CarrierData.Country);
        if CountryCode <> '' then
            VendorBankAccount.Validate("Country/Region Code", CountryCode);
        VendorBankAccount.Address := CopyStr(CarrierData.CarrierRemitAddress1, 1, MaxStrLen(VendorBankAccount.Address));
        VendorBankAccount."Address 2" := CopyStr(CarrierData.CarrierRemitAddress2, 1, MaxStrLen(VendorBankAccount."Address 2"));
        VendorBankAccount.City := CopyStr(CarrierData.CarrierRemitCity, 1, MaxStrLen(VendorBankAccount.City));
        VendorBankAccount."Post Code" := CopyStr(CarrierData.CarrierRemitZipCode, 1, MaxStrLen(Vendor."Post Code"));
        VendorBankAccount.County := CopyStr(CarrierData.CarrierRemitStateProvince, 1, MaxStrLen(VendorBankAccount.County));

        VendorBankAccount."Phone No." := CopyStr(CarrierData.BankPhone, 1, MaxStrLen(VendorBankAccount."Phone No."));
        VendorBankAccount."E-Mail" := CopyStr(CarrierData.RemitEmail, 1, MaxStrLen(VendorBankAccount."E-Mail"));
        VendorBankAccount."Bank Account No." := CopyStr(CarrierData.BankAccountNumber, 1, MaxStrLen(VendorBankAccount."Bank Account No."));
        VendorBankAccount."Transit No." := CopyStr(CarrierData.BankRoutingNumber, 1, MaxStrLen(VendorBankAccount."Bank Branch No."));
        if Vendor."Currency Code" <> '' then
            VendorBankAccount.Validate("Currency Code", Vendor."Currency Code");

        if (CarrierData.CarrierPaymentType = 'ACH') or (VendorBankAccount.Code = 'ACH') then
            VendorBankAccount."Use for Electronic Payments" := true;

        SingleInstance.SetUpdatedFromMCP(true);
        VendorBankAccount.Modify(true);
        SingleInstance.SetUpdatedFromMCP(false);
    end;




    procedure AddVendorDocumentLayouts(var Vendor: Record Vendor; EmailAddr: Text)
    begin
        AddVendorDocumentLayout(Vendor, EmailAddr, 'CTS Email Body 10083', 'EEL Remite', Enum::"Report Selection Usage"::"V.Remittance", Report::"Export Electronic Payments");
        AddVendorDocumentLayout(Vendor, EmailAddr, 'CTS Email Body', '', Enum::"Report Selection Usage"::"P.V.Remit.", Report::"Remittance Advice - Entries");
    end;

    local procedure AddVendorDocumentLayout(var Vendor: Record Vendor; EmailAddr: Text; BodyLayout: Text; AttachmentLayout: Text; Usage: Enum "Report Selection Usage"; ReportID: Integer)
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        CustomReportSelection.SetRange("Source Type", Database::Vendor);
        CustomReportSelection.SetRange("Source No.", Vendor."No.");
        CustomReportSelection.SetRange(Usage, Usage);
        if not CustomReportSelection.FindFirst() then begin
            CustomReportSelection.Init();
            CustomReportSelection.Validate("Source Type", Database::Vendor);
            CustomReportSelection.Validate("Source No.", Vendor."No.");
            CustomReportSelection.Validate(Usage, Usage);
            CustomReportSelection.Validate("Report ID", ReportID);
            CustomReportSelection.Insert(true);
        end;
        CustomReportSelection.Validate("Report ID", ReportID);
        CustomReportSelection.Validate("Send To Email", EmailAddr);
        CustomReportSelection.Validate("Use for Email Body", true);
        CustomReportSelection.Validate("Use for Email Attachment", Usage = Enum::"Report Selection Usage"::"P.V.Remit.");
        GetLayoutDetails(CustomReportSelection, 'CTS Email Body 10083', true);
        if CompanyName.Contains('CTS') then
            GetLayoutDetails(CustomReportSelection, 'CTS Email Body', true)
        else
            GetLayoutDetails(CustomReportSelection, 'EEL Remite', false);
        CustomReportSelection.Modify(true);
    end;

    local procedure GetLayoutDetails(var CustomReportSelection: Record "Custom Report Selection"; LayoutName: Text; Body: Boolean)
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        if LayoutName = '' then
            exit;
        ReportLayoutList.SetRange("Report ID", CustomReportSelection."Report ID");
        ReportLayoutList.SetRange(Name, LayoutName);
        if ReportLayoutList.FindFirst() then
            if Body then begin
                CustomReportSelection.Validate("Email Body Layout Name", ReportLayoutList.Name);
                CustomReportSelection.Validate("Email Body Layout AppID", ReportLayoutList."Application ID");
            end else begin
                CustomReportSelection.Validate("Email Attachment Layout Name", ReportLayoutList.Name);
                CustomReportSelection.Validate("Email Body Layout AppID", ReportLayoutList."Application ID");
            end;
    end;


    local procedure GetCountryCode(Input: Text): Code[10]
    var
        CountryRegion: Record "Country/Region";
        s: Text;
    begin
        if Input.ToLower() = UnitedStatesLower then
            exit('US');
        s := CopyStr(Input, 1, MaxStrLen(CountryRegion.Code));
        if not CountryRegion.Get(s) then begin
            CountryRegion.SetRange(Name, CopyStr(Input, 1, MaxStrLen(CountryRegion.Name)));
            if CountryRegion.FindFirst() then
                exit(CountryRegion.Code);
        end else
            exit(CountryRegion.Code);
    end;


    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", OnAfterModifyEvent, '', false, false)]
    local procedure VendorBankAccountOnAfterModifyEvent(var Rec: Record "Vendor Bank Account"; RunTrigger: Boolean)
    begin
        Rec."EEMCP Updated From MCP" := SingleInstance.GetUpdatedFromMCP();
        if not Rec."EEMCP Updated From MCP" then begin
            Rec."EEMCP Last Non-MCP Update By" := UserId();
            Rec."EEMCP Last Non-MCP Update At" := CurrentDateTime();
        end;
    end;


    var

        SingleInstance: Codeunit "EEMCP Single Instance";

        UnitedStatesLower: Label 'united states';
}