table 80006 "EE Part Line Staging"
{
    DataClassification = CustomerContent;
    Caption = 'Part Line Staging';
    // LookupPageId = "EE Staged Purchased Lines";
    // DrillDownPageId = "EE Staged Purchased Lines";

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
        }
        field(3; "Task Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "Header Id"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5; "Task Id"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; "task_part_id"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; "part_id"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; "part_number"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; "part_description"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(15; "part_system_code"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(16; "part_type"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(17; "part_price"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(18; "part_quantity"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(19; "part_subtotal"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "part_tax_rate"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(21; "part_warranty_savings"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(22; "part_location"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(23; "tire_brand"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; "tire_product_line"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(25; "tire_size"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(26; "tire_type"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(27; date_added; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_added (UTC)';
        }
        field(28; "Added At"; DateTime)
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
        key(K2; "Header Id", "Header Entry No.") { }
        key(K3; "Task Id", "Task Entry No.") { }
        key(K4; "Header Id", "Header Entry No.", "Task Id", "Task Entry No.") { }
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
        Rec."Added At" := 0DT;
        if Rec.date_added <> '' then
            if Evaluate(Rec."Added At", Rec.date_added) then
                Rec."Added At" := Rec."Added At" + TimezoneOffset;
    end;
}