codeunit 81000 "EE Fleetrock Audit Mgt"
{
    Access = Public;

    var
        Tolerance: Decimal;
        SetupMissingErr: Label 'Fleetrock setup is not configured. Open the Fleetrock Setup page first.';
        HttpStatusErr: Label 'Fleetrock GET %1 returned HTTP status %2.', Comment = '%1 = url, %2 = status';
        HttpCallErr: Label 'Fleetrock GET %1 failed to send.', Comment = '%1 = url';
        ParseErr: Label 'Could not parse JSON response from %1.', Comment = '%1 = url';
        DoneMsg: Label 'Fleetrock audit complete. %1 issue(s) recorded.', Comment = '%1 = count';

    /// <summary>
    /// Entry point called from the list page. Clears existing issues,
    /// fetches Purchase Orders and Repair Orders from Fleetrock, runs the
    /// arithmetic checks and writes any mismatches to "EE Fleetrock Audit Issue".
    /// </summary>
    procedure RefreshAudit()
    var
        Setup: Record "EE Fleetrock Setup";
        AuditIssue: Record "EE Fleetrock Audit Issue";
        RefreshAt: DateTime;
        IssueCount: Integer;
    begin
        Tolerance := 0.01;
        RefreshAt := CurrentDateTime();

        if not Setup.FindFirst() then
            Error(SetupMissingErr);

        AuditIssue.LockTable();
        AuditIssue.DeleteAll();

        if (Setup."Username" <> '') and (Setup."API Key" <> '') then begin
            AuditOrders(Setup, Setup."Username", Setup."API Key", Enum::"EE Fleetrock Order Kind"::"Purchase Order", RefreshAt);
            AuditOrders(Setup, Setup."Username", Setup."API Key", Enum::"EE Fleetrock Order Kind"::"Repair Order", RefreshAt);
        end;

        if (Setup."Vendor Username" <> '') and (Setup."Vendor API Key" <> '') then begin
            AuditOrders(Setup, Setup."Vendor Username", Setup."Vendor API Key", Enum::"EE Fleetrock Order Kind"::"Purchase Order", RefreshAt);
            AuditOrders(Setup, Setup."Vendor Username", Setup."Vendor API Key", Enum::"EE Fleetrock Order Kind"::"Repair Order", RefreshAt);
        end;

        Commit();
        IssueCount := AuditIssue.Count();
        Message(DoneMsg, IssueCount);
    end;

    local procedure AuditOrders(Setup: Record "EE Fleetrock Setup"; Username: Text; ApiKey: Text; Kind: Enum "EE Fleetrock Order Kind"; RefreshAt: DateTime) IssueCount: Integer
    var
        JsonResp: JsonObject;
        Orders: JsonArray;
        OrderToken: JsonToken;
        OrdersToken: JsonToken;
        Url: Text;
        EndpointPath: Text;
        EventName: Text;
        ResultKey: Text;
        i: Integer;
    begin
        case Kind of
            Enum::"EE Fleetrock Order Kind"::"Purchase Order":
                begin
                    EndpointPath := 'GetPO';
                    EventName := 'Received';
                    ResultKey := 'purchase_orders';
                end;
            Enum::"EE Fleetrock Order Kind"::"Repair Order":
                begin
                    EndpointPath := 'GetRO';
                    EventName := 'invoiced';
                    ResultKey := 'repair_orders';
                end;
        end;

        Url := BuildUrl(Setup, Username, ApiKey, EndpointPath, EventName);
        JsonResp := FetchJson(Url);

        if not JsonResp.Get(ResultKey, OrdersToken) then
            exit(0);
        if not OrdersToken.IsArray() then
            exit(0);

        Orders := OrdersToken.AsArray();
        for i := 0 to Orders.Count() - 1 do begin
            Orders.Get(i, OrderToken);
            case Kind of
                Enum::"EE Fleetrock Order Kind"::"Purchase Order":
                    IssueCount += AuditPO(OrderToken.AsObject(), Username, RefreshAt);
                Enum::"EE Fleetrock Order Kind"::"Repair Order":
                    IssueCount += AuditRO(OrderToken.AsObject(), Username, RefreshAt);
            end;
        end;
    end;

    local procedure AuditPO(PO: JsonObject; Credential: Text; RefreshAt: DateTime) IssueCount: Integer
    var
        Lines: JsonArray;
        LineToken: JsonToken;
        LineObj: JsonObject;
        OrderId: Text;
        SumLineTotals: Decimal;
        Qty: Decimal;
        Price: Decimal;
        LineTotal: Decimal;
        Expected: Decimal;
        Grand: Decimal;
        Subtotal: Decimal;
        Tax: Decimal;
        Shipping: Decimal;
        Other: Decimal;
        ExpectedGrand: Decimal;
        PartNo: Text;
        PartDesc: Text;
        LineRef: Text;
        Msg: Text;
        i: Integer;
    begin
        OrderId := JsonText(PO, 'id');
        Lines := JsonArrayFrom(PO, 'line_items');

        for i := 0 to Lines.Count() - 1 do begin
            Lines.Get(i, LineToken);
            LineObj := LineToken.AsObject();
            Qty := JsonDecimal(LineObj, 'part_quantity');
            Price := JsonDecimal(LineObj, 'unit_price');
            LineTotal := JsonDecimal(LineObj, 'line_total');
            PartNo := JsonText(LineObj, 'part_number');
            PartDesc := JsonText(LineObj, 'part_description');
            Expected := Round(Qty * Price, 0.0001);
            LineRef := StrSubstNo('Line %1', i + 1);

            if not Near(Expected, LineTotal) then begin
                Msg := StrSubstNo('Line %1 total %2 does not match quantity %3 x unit price %4 = %5 (off by %6).',
                        i + 1, FormatMoney(LineTotal), Format(Qty), FormatMoney(Price),
                        FormatMoney(Expected), FormatMoney(LineTotal - Expected));
                InsertIssue(Enum::"EE Fleetrock Order Kind"::"Purchase Order", Credential, OrderId,
                            Enum::"EE Fleetrock Issue Code"::L1, LineRef, PartNo, PartDesc,
                            Format(Qty), FormatMoney(Price), Expected, LineTotal, Msg, RefreshAt);
                IssueCount += 1;
            end;
            SumLineTotals += LineTotal;
        end;

        Grand := JsonDecimal(PO, 'grand_total');
        Subtotal := JsonDecimal(PO, 'subtotal');
        Tax := JsonDecimal(PO, 'tax_total');
        Shipping := JsonDecimal(PO, 'shipping_total');
        Other := JsonDecimal(PO, 'other_total');

        ExpectedGrand := Round(SumLineTotals + Tax + Shipping + Other, 0.0001);
        if not Near(ExpectedGrand, Grand) then begin
            Msg := StrSubstNo('Header grand total %1 does not match the calculated total %2 (off by %3). Calculation: sum of line totals %4 + tax %5 + shipping %6 + other %7.',
                    FormatMoney(Grand), FormatMoney(ExpectedGrand), FormatMoney(Grand - ExpectedGrand),
                    FormatMoney(SumLineTotals), FormatMoney(Tax), FormatMoney(Shipping), FormatMoney(Other));
            InsertIssue(Enum::"EE Fleetrock Order Kind"::"Purchase Order", Credential, OrderId,
                        Enum::"EE Fleetrock Issue Code"::H1, '', '', '', '', '',
                        ExpectedGrand, Grand, Msg, RefreshAt);
            IssueCount += 1;
        end;

        if not Near(Subtotal, SumLineTotals) then begin
            Msg := StrSubstNo('Header subtotal %1 does not match the sum of line totals %2 (off by %3).',
                    FormatMoney(Subtotal), FormatMoney(SumLineTotals), FormatMoney(Subtotal - SumLineTotals));
            InsertIssue(Enum::"EE Fleetrock Order Kind"::"Purchase Order", Credential, OrderId,
                        Enum::"EE Fleetrock Issue Code"::H1, '', '', '', '', '',
                        SumLineTotals, Subtotal, Msg, RefreshAt);
            IssueCount += 1;
        end;
    end;

    local procedure AuditRO(RO: JsonObject; Credential: Text; RefreshAt: DateTime) IssueCount: Integer
    var
        Tasks: JsonArray;
        Parts: JsonArray;
        TaskToken: JsonToken;
        PartToken: JsonToken;
        TaskObj: JsonObject;
        PartObj: JsonObject;
        OrderId: Text;
        TaskId: Text;
        SumLabor: Decimal;
        SumParts: Decimal;
        SumLineTax: Decimal;
        Hours: Decimal;
        Rate: Decimal;
        LaborSub: Decimal;
        LaborTaxRate: Decimal;
        Complaint: Text;
        ExpectedLabor: Decimal;
        Qty: Decimal;
        Price: Decimal;
        Sub: Decimal;
        TaxRate: Decimal;
        PartNo: Text;
        PartDesc: Text;
        ExpectedP: Decimal;
        HeaderLabor: Decimal;
        HeaderParts: Decimal;
        AddChg: Decimal;
        AddChgRate: Decimal;
        TaxTotal: Decimal;
        Credit: Decimal;
        Grand: Decimal;
        ExpectedGrand: Decimal;
        ExpectedTax: Decimal;
        Msg: Text;
        LineRef: Text;
        t: Integer;
        p: Integer;
    begin
        OrderId := JsonText(RO, 'id');
        Tasks := JsonArrayFrom(RO, 'tasks');

        for t := 0 to Tasks.Count() - 1 do begin
            Tasks.Get(t, TaskToken);
            TaskObj := TaskToken.AsObject();
            TaskId := JsonText(TaskObj, 'task_id');
            if TaskId = '' then
                TaskId := Format(t + 1);
            Hours := JsonDecimal(TaskObj, 'labor_hours');
            Rate := JsonDecimal(TaskObj, 'labor_hourly_rate');
            LaborSub := JsonDecimal(TaskObj, 'labor_subtotal');
            LaborTaxRate := JsonDecimal(TaskObj, 'labor_tax_rate');
            Complaint := DelChr(JsonText(TaskObj, 'labor_complaint'), '<>', ' ');
            ExpectedLabor := Round(Hours * Rate, 0.0001);
            LineRef := StrSubstNo('Task %1 (labor)', TaskId);

            if not Near(ExpectedLabor, LaborSub) then begin
                Msg := StrSubstNo('Task %1 labor subtotal %2 does not match %3 hours x %4/hr = %5 (off by %6).',
                        TaskId, FormatMoney(LaborSub), Format(Hours), FormatMoney(Rate),
                        FormatMoney(ExpectedLabor), FormatMoney(LaborSub - ExpectedLabor));
                InsertIssue(Enum::"EE Fleetrock Order Kind"::"Repair Order", Credential, OrderId,
                            Enum::"EE Fleetrock Issue Code"::L1, LineRef, '', Complaint,
                            StrSubstNo('%1 hrs', Format(Hours)), StrSubstNo('%1/hr', FormatMoney(Rate)),
                            ExpectedLabor, LaborSub, Msg, RefreshAt);
                IssueCount += 1;
            end;
            SumLabor += LaborSub;
            SumLineTax += LaborSub * LaborTaxRate / 100;

            Parts := JsonArrayFrom(TaskObj, 'parts');
            for p := 0 to Parts.Count() - 1 do begin
                Parts.Get(p, PartToken);
                PartObj := PartToken.AsObject();
                Qty := JsonDecimal(PartObj, 'part_quantity');
                Price := JsonDecimal(PartObj, 'part_price');
                Sub := JsonDecimal(PartObj, 'part_subtotal');
                TaxRate := JsonDecimal(PartObj, 'part_tax_rate');
                PartNo := JsonText(PartObj, 'part_number');
                PartDesc := JsonText(PartObj, 'part_description');
                ExpectedP := Round(Qty * Price, 0.0001);
                LineRef := StrSubstNo('Task %1 part %2', TaskId, p + 1);

                if not Near(ExpectedP, Sub) then begin
                    Msg := StrSubstNo('Task %1 part subtotal %2 does not match quantity %3 x price %4 = %5 (off by %6).',
                            TaskId, FormatMoney(Sub), Format(Qty), FormatMoney(Price),
                            FormatMoney(ExpectedP), FormatMoney(Sub - ExpectedP));
                    InsertIssue(Enum::"EE Fleetrock Order Kind"::"Repair Order", Credential, OrderId,
                                Enum::"EE Fleetrock Issue Code"::L1, LineRef, PartNo, PartDesc,
                                Format(Qty), FormatMoney(Price), ExpectedP, Sub, Msg, RefreshAt);
                    IssueCount += 1;
                end;
                SumParts += Sub;
                SumLineTax += Sub * TaxRate / 100;
            end;
        end;

        HeaderLabor := JsonDecimal(RO, 'labor_total');
        HeaderParts := JsonDecimal(RO, 'part_total');
        AddChg := JsonDecimal(RO, 'additional_charges');
        AddChgRate := JsonDecimal(RO, 'additional_charges_tax_rate');
        TaxTotal := JsonDecimal(RO, 'tax_total');
        Credit := JsonDecimal(RO, 'credit_amount');
        Grand := JsonDecimal(RO, 'grand_total');

        SumLineTax += AddChg * AddChgRate / 100;

        if not Near(SumLabor, HeaderLabor) then begin
            Msg := StrSubstNo('Header labor total %1 does not match the sum of task labor subtotals %2 (off by %3).',
                    FormatMoney(HeaderLabor), FormatMoney(SumLabor), FormatMoney(HeaderLabor - SumLabor));
            InsertIssue(Enum::"EE Fleetrock Order Kind"::"Repair Order", Credential, OrderId,
                        Enum::"EE Fleetrock Issue Code"::H1, '', '', '', '', '',
                        SumLabor, HeaderLabor, Msg, RefreshAt);
            IssueCount += 1;
        end;

        if not Near(SumParts, HeaderParts) then begin
            Msg := StrSubstNo('Header parts total %1 does not match the sum of part subtotals %2 (off by %3).',
                    FormatMoney(HeaderParts), FormatMoney(SumParts), FormatMoney(HeaderParts - SumParts));
            InsertIssue(Enum::"EE Fleetrock Order Kind"::"Repair Order", Credential, OrderId,
                        Enum::"EE Fleetrock Issue Code"::H1, '', '', '', '', '',
                        SumParts, HeaderParts, Msg, RefreshAt);
            IssueCount += 1;
        end;

        ExpectedGrand := Round(SumLabor + SumParts + AddChg + TaxTotal - Credit, 0.0001);
        if not Near(ExpectedGrand, Grand) then begin
            Msg := StrSubstNo('Header grand total %1 does not match the calculated total %2 (off by %3). Calculation: labor %4 + parts %5 + additional charges %6 + tax %7 - credit %8.',
                    FormatMoney(Grand), FormatMoney(ExpectedGrand), FormatMoney(Grand - ExpectedGrand),
                    FormatMoney(SumLabor), FormatMoney(SumParts), FormatMoney(AddChg),
                    FormatMoney(TaxTotal), FormatMoney(Credit));
            InsertIssue(Enum::"EE Fleetrock Order Kind"::"Repair Order", Credential, OrderId,
                        Enum::"EE Fleetrock Issue Code"::H1, '', '', '', '', '',
                        ExpectedGrand, Grand, Msg, RefreshAt);
            IssueCount += 1;
        end;

        ExpectedTax := Round(SumLineTax, 0.0001);
        if not Near(ExpectedTax, TaxTotal) then begin
            Msg := StrSubstNo('Header tax total %1 does not match the sum of per-line tax amounts %2 (off by %3).',
                    FormatMoney(TaxTotal), FormatMoney(ExpectedTax), FormatMoney(TaxTotal - ExpectedTax));
            InsertIssue(Enum::"EE Fleetrock Order Kind"::"Repair Order", Credential, OrderId,
                        Enum::"EE Fleetrock Issue Code"::H2, '', '', '', '', '',
                        ExpectedTax, TaxTotal, Msg, RefreshAt);
            IssueCount += 1;
        end;
    end;

    local procedure InsertIssue(OrderKind: Enum "EE Fleetrock Order Kind"; Credential: Text; OrderId: Text;
                                IssueCode: Enum "EE Fleetrock Issue Code"; LineRef: Text; PartNo: Text;
                                PartDesc: Text; QtyText: Text; UnitPriceText: Text; Expected: Decimal;
                                Actual: Decimal; Msg: Text; RefreshAt: DateTime)
    var
        AuditIssue: Record "EE Fleetrock Audit Issue";
        Existing: Record "EE Fleetrock Audit Issue";
        ExpRounded: Decimal;
        ActRounded: Decimal;
    begin
        ExpRounded := Round(Expected, 0.01);
        ActRounded := Round(Actual, 0.01);

        Existing.SetRange("Order Kind", OrderKind);
        Existing.SetRange("Order ID", CopyStr(OrderId, 1, MaxStrLen(Existing."Order ID")));
        Existing.SetRange("Issue Code", IssueCode);
        Existing.SetRange("Line Ref", CopyStr(LineRef, 1, MaxStrLen(Existing."Line Ref")));
        Existing.SetRange("Expected Amount", ExpRounded);
        Existing.SetRange("Actual Amount", ActRounded);
        if not Existing.IsEmpty() then
            exit;

        AuditIssue.Init();
        AuditIssue."Order Kind" := OrderKind;
        AuditIssue."Credential" := CopyStr(Credential, 1, MaxStrLen(AuditIssue."Credential"));
        AuditIssue."Order ID" := CopyStr(OrderId, 1, MaxStrLen(AuditIssue."Order ID"));
        AuditIssue."Issue Code" := IssueCode;
        AuditIssue."Line Ref" := CopyStr(LineRef, 1, MaxStrLen(AuditIssue."Line Ref"));
        AuditIssue."Part Number" := CopyStr(PartNo, 1, MaxStrLen(AuditIssue."Part Number"));
        AuditIssue."Part Description" := CopyStr(PartDesc, 1, MaxStrLen(AuditIssue."Part Description"));
        AuditIssue.Quantity := CopyStr(QtyText, 1, MaxStrLen(AuditIssue.Quantity));
        AuditIssue."Unit Price" := CopyStr(UnitPriceText, 1, MaxStrLen(AuditIssue."Unit Price"));
        AuditIssue."Expected Amount" := ExpRounded;
        AuditIssue."Actual Amount" := ActRounded;
        AuditIssue.Difference := Round(Actual - Expected, 0.01);
        AuditIssue.Message := CopyStr(Msg, 1, MaxStrLen(AuditIssue.Message));
        AuditIssue."Refreshed At" := RefreshAt;
        AuditIssue.Insert(true);
    end;

    local procedure BuildUrl(Setup: Record "EE Fleetrock Setup"; Username: Text; ApiKey: Text; EndpointPath: Text; EventName: Text) Url: Text
    var
        BaseUrl: Text;
        StartText: Text;
        EndText: Text;
    begin
        BaseUrl := GetBaseUrl(Setup);
        StartText := GetStartDate(Setup);
        EndText := GetEndDate(Setup);

        if BaseUrl.EndsWith('/') then
            BaseUrl := CopyStr(BaseUrl, 1, StrLen(BaseUrl) - 1);
        if not (BaseUrl.EndsWith('/API') or BaseUrl.EndsWith('/api')) then
            BaseUrl := BaseUrl + '/API';

        Url := StrSubstNo('%1/%2?username=%3&event=%4&token=%5&start=%6&end=%7',
                BaseUrl, EndpointPath, Username, EventName, ApiKey, StartText, EndText);
    end;

    local procedure FetchJson(Url: Text) Result: JsonObject
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
    begin
        Client.Timeout(240000);
        if not Client.Get(Url, Response) then
            Error(HttpCallErr, Url);
        if not Response.IsSuccessStatusCode() then
            Error(HttpStatusErr, Url, Response.HttpStatusCode());
        Response.Content().ReadAs(ResponseText);
        if not Result.ReadFrom(ResponseText) then
            Error(ParseErr, Url);
    end;

    local procedure Near(A: Decimal; B: Decimal): Boolean
    begin
        exit(Abs(A - B) <= Tolerance);
    end;

    local procedure FormatMoney(Amount: Decimal): Text
    var
        Rounded: Decimal;
    begin
        Rounded := Round(Amount, 0.01);
        if Rounded < 0 then
            exit(StrSubstNo('-$%1', Format(-Rounded, 0, '<Precision,2:2><Standard Format,0>')));
        exit(StrSubstNo('$%1', Format(Rounded, 0, '<Precision,2:2><Standard Format,0>')));
    end;

    local procedure JsonText(Obj: JsonObject; KeyName: Text) Ret: Text
    var
        Tok: JsonToken;
    begin
        if not Obj.Get(KeyName, Tok) then
            exit('');
        if not Tok.IsValue() then
            exit('');
        if Tok.AsValue().IsNull() then
            exit('');
        exit(Tok.AsValue().AsText());
    end;

    local procedure JsonDecimal(Obj: JsonObject; KeyName: Text) Ret: Decimal
    var
        Tok: JsonToken;
        TextValue: Text;
    begin
        if not Obj.Get(KeyName, Tok) then
            exit(0);
        if not Tok.IsValue() then
            exit(0);
        if Tok.AsValue().IsNull() then
            exit(0);
        TextValue := Tok.AsValue().AsText();
        if TextValue = '' then
            exit(0);
        if not Evaluate(Ret, TextValue, 9) then
            if not Evaluate(Ret, TextValue) then
                exit(0);
    end;

    local procedure JsonArrayFrom(Obj: JsonObject; KeyName: Text) Ret: JsonArray
    var
        Tok: JsonToken;
    begin
        if not Obj.Get(KeyName, Tok) then
            exit(Ret);
        if not Tok.IsArray() then
            exit(Ret);
        exit(Tok.AsArray());
    end;

    local procedure GetBaseUrl(Setup: Record "EE Fleetrock Setup"): Text
    begin
        if Setup."Integration URL" <> '' then
            exit(Setup."Integration URL");
        exit('https://www.fleetrock.com/API');
    end;

    local procedure GetStartDate(Setup: Record "EE Fleetrock Setup"): Text
    var
        D: Date;
    begin
        D := DT2Date(Setup."Earliest Import DateTime");
        if D = 0D then
            D := Today();
        exit(Format(D, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure GetEndDate(Setup: Record "EE Fleetrock Setup"): Text
    var
        D: Date;
    begin
        D := CalcDate('<+1Y>', Today());
        exit(Format(D, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;
}
