table 80002 "EE Purch. Line Staging"
{
    DataClassification = CustomerContent;
    Caption = 'Purch. Line Staging';
    LookupPageId = "EE Staged Purchased Lines";
    DrillDownPageId = "EE Staged Purchased Lines";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "Header Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "EE Purch. Header Staging"."Entry No.";
        }
        field(10; "Header id"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; part_id; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; part_number; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; part_description; Text[250])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; part_system_code; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(15; part_type; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(16; tag; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(17; part_quantity; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(18; unit_price; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(19; line_total; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; date_added; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50; "Added"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51; "Added (Local Time)"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(K2; "Header id", "Header Entry No.") { }
    }

    trigger OnInsert()
    begin
        FormatDateValues();
    end;

    procedure FormatDateValues()
    var
        TypeHelper: Codeunit "Type Helper";
        TimezoneOffset: Duration;
    begin
        if not TypeHelper.GetUserTimezoneOffset(TimezoneOffset) then
            TimezoneOffset := 0;

        Rec.Added := 0DT;
        if Rec.date_added <> '' then
            if Evaluate(Rec.Added, Rec.date_added) then
                Rec."Added (Local Time)" := Rec.Added + TimezoneOffset;
    end;
}