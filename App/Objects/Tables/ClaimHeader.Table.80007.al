table 80007 "EE Claim Header"
{
    DataClassification = CustomerContent;
    Caption = 'Claim Header';
    LookupPageId = "EE Staged Claim Headers";
    DrillDownPageId = "EE Staged Claim Headers";


    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "id"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "group"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; "unit_number"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; "vendor_name"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; "supplier_name"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; "supplier_custom_id"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(15; "reference_number"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(16; "credit_number"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(17; "check_number"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(18; "tag"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(19; "status"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "odometer_miles"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(21; "engine_hours"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(22; "date_failure"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(23; "created_by"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; "date_created"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(25; "date_opened"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(26; "date_closed"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(27; "claim_amount"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(28; "amount_paid"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50; "Failure DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51; "Created DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(52; "Opened DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(53; "Closed DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(54; Lines; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("EE Claim Line" where("Header id" = field(id), "Header Entry No." = field("Entry No.")));
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
        // field(104; "Document No."; Code[20])
        // {
        //     DataClassification = CustomerContent;
        //     Editable = false;
        //     TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
        // }
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
        ClaimLine: Record "EE Claim Line";
    begin
        ClaimLine.SetRange("Header Entry No.", Rec."Entry No.");
        ClaimLine.DeleteAll(true);
    end;


    procedure FormatDateValues()
    var
        TypeHelper: Codeunit "Type Helper";
        TimezoneOffset: Duration;
    begin
        Rec."Created DateTime" := 0DT;
        Rec."Opened DateTime" := 0DT;
        Rec."Closed DateTime" := 0DT;
        Rec."Failure DateTime" := 0DT;

        if not TypeHelper.GetUserTimezoneOffset(TimezoneOffset) then
            TimezoneOffset := 0;

        if Rec.date_created <> '' then
            if Evaluate(Rec."Created DateTime", Rec.date_created) then
                Rec."Created DateTime" += TimezoneOffset;
        if Rec.date_opened <> '' then
            if Evaluate(Rec."Opened DateTime", Rec.date_opened) then
                Rec."Opened DateTime" += TimezoneOffset;
        if Rec.date_failure <> '' then
            if Evaluate(Rec."Failure DateTime", Rec.date_failure) then
                Rec."Failure DateTime" += TimezoneOffset;
        if Rec.date_closed <> '' then
            if Evaluate(Rec."Closed DateTime", Rec.date_closed) then
                Rec."Closed DateTime" += TimezoneOffset;
    end;
}