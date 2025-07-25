table 80001 "EE Purch. Header Staging"
{
    DataClassification = CustomerContent;
    Caption = 'Purch. Header Staging';
    LookupPageId = "EE Staged Purchased Headers";
    DrillDownPageId = "EE Staged Purchased Headers";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; id; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; supplier_name; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; supplier_custom_id; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; recipient_name; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; tag; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(15; status; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(16; date_created; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_created (UTC)';
        }
        field(17; date_opened; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_opened (UTC)';
        }
        field(18; date_received; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_received (UTC)';
        }
        field(19; date_closed; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_closed (UTC)';
        }
        field(20; payment_term_days; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(21; invoice_number; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(22; subtotal; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(23; tax_total; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; shipping_total; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(25; other_total; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(26; grand_total; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50; Created; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51; Opened; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(52; Received; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(53; Closed; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(54; Lines; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("EE Purch. Line Staging" where("Header id" = field(id), "Header Entry No." = field("Entry No.")));
            Editable = false;
        }
        field(60; remit_to; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(61; remit_to_company_id; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(100; "Import Error"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(101; "Processed Error"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(102; "Error Message"; Text[1024])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(103; "Processed"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(104; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
        }
        field(105; "Imported By"; Code[50])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field(SystemCreatedBy)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(K2; id) { }
    }

    trigger OnInsert()
    begin
        FormatDateValues();
    end;

    trigger OnDelete()
    var
        PurchLineStaging: Record "EE Purch. Line Staging";
    begin
        PurchLineStaging.SetRange("Header Entry No.", Rec."Entry No.");
        PurchLineStaging.DeleteAll(true);
    end;

    procedure FormatDateValues()
    var
        TypeHelper: Codeunit "Type Helper";
        TimezoneOffset: Duration;
    begin
        Rec.Created := 0DT;
        Rec.Opened := 0DT;
        Rec.Received := 0DT;
        Rec.Closed := 0DT;

        if not TypeHelper.GetUserTimezoneOffset(TimezoneOffset) then
            TimezoneOffset := 0;

        if Rec.date_created <> '' then
            if Evaluate(Rec.Created, Rec.date_created) then
                Rec.Created += TimezoneOffset;
        if Rec.date_opened <> '' then
            if Evaluate(Rec.Opened, Rec.date_opened) then
                Rec.Opened += TimezoneOffset;
        if Rec.date_received <> '' then
            if Evaluate(Rec.Received, Rec.date_received) then
                Rec.Received += TimezoneOffset;
        if Rec.date_closed <> '' then
            if Evaluate(Rec.Closed, Rec.date_closed) then
                Rec.Closed += TimezoneOffset;
    end;
}