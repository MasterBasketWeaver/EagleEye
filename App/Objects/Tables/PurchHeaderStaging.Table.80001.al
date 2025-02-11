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
        field(11; supplier_name; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; supplier_custom_id; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; recipient_name; Text[50])
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
        }
        field(17; date_opened; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(18; date_received; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(19; date_closed; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
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
            CalcFormula = count("EE Purch. Line Staging" where(id = field(id), "Header Entry No." = field("Entry No.")));
            Editable = false;
        }
        field(100; "Insert Error"; Boolean)
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
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(K2; id) { }
    }

    procedure FormatDateValues()
    begin
        Rec.Created := 0DT;
        Rec.Opened := 0DT;
        Rec.Received := 0DT;
        Rec.Closed := 0DT;
        if Rec.date_created <> '' then
            Evaluate(Rec.Created, Rec.date_created);
        if Rec.date_opened <> '' then
            Evaluate(Rec.Opened, Rec.date_opened);
        if Rec.date_received <> '' then
            Evaluate(Rec.Received, Rec.date_received);
        if Rec.date_closed <> '' then
            Evaluate(Rec.Closed, Rec.date_closed);
    end;
}