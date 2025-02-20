table 80005 "EE Task Line Staging"
{
    DataClassification = CustomerContent;
    Caption = 'Task Line Staging';
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
        field(10; "Header Id"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; task_id; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; labor_hourly_rate; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; labor_type; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; labor_hours; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(15; labor_subtotal; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(16; labor_tax_rate; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(17; labor_warranty_savings; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(18; labor_complaint; Text[250])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(19; labor_cause_code; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; labor_correction_code; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(21; labor_system_code; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(22; labor_system_component_code; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(23; scheduled_maintenance_id; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; issue_id; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(25; assigned_to; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(26; date_added; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_added (UTC)';
        }
        field(27; "Added At"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99; "Part Lines"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("EE Part Line Staging" where("Task Id" = field(task_id), "Task Entry No." = field("Entry No.")));
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