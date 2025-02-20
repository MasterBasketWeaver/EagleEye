table 80004 "EE Sales Header Staging"
{
    DataClassification = CustomerContent;
    Caption = 'Sales Header Staging';
    LookupPageId = "EE Staged Repair Order Headers";
    DrillDownPageId = "EE Staged Repair Order Headers";

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
        field(11; group; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; ro_group_hierarchy; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; vin; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; unit_number; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(15; unit_type; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(16; custom_asset_id; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(17; vendor_name; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(18; vendor_company_id; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(19; vendor_city; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; vendor_state; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(21; vendor_province; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(22; vendor_zip_code; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(23; vendor_timezone; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; customer_name; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(25; customer_company_id; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(26; odometer_miles; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(27; engine_hours; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(28; priority_code; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(29; cost_center; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(30; tag; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(31; status; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(32; created_by; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(33; date_created; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_created (UTC)';
        }
        field(34; date_started; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_started (UTC)';
        }
        field(35; date_expected_finish; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_expected_finish (UTC)';
        }
        field(36; date_finished; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_finished (UTC)';
        }
        field(37; date_invoiced; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_invoiced (UTC)';
        }
        field(38; date_invoice_paid; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'date_invoice_paid (UTC)';
        }
        field(39; po_number; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(40; labor_total; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(41; part_total; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(42; additional_charges; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(43; additional_charges_tax_rate; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(44; tax_total; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(45; credit_amount; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(46; estimate; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(47; estimate_accept_amount; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(48; grand_total; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(49; paid_amount; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50; remit_to; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51; remit_to_company_id; Text[50])
        {
            DataClassification = CustomerContent;
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
        field(110; "Task Lines"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("EE Task Line Staging" where("Header Id" = field(id), "Header Entry No." = field("Entry No.")));
            Editable = false;
        }
        field(111; "Part Lines"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("EE Part Line Staging" where("Header Id" = field(id), "Header Entry No." = field("Entry No.")));
            Editable = false;
        }
        field(120; "Created At"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(121; "Started At"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(122; "Expected Finish At"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(123; "Finished At"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(124; "Invoiced At"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(125; "Invoice Paid At"; DateTime)
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

    trigger OnInsert()
    begin
        FormatDateValues();
    end;

    procedure FormatDateValues()
    var
        TypeHelper: Codeunit "Type Helper";
        TimezoneOffset: Duration;
    begin
        Rec."Created At" := 0DT;
        Rec."Started At" := 0DT;
        Rec."Expected Finish At" := 0DT;
        Rec."Finished At" := 0DT;
        Rec."Invoiced At" := 0DT;
        Rec."Invoice Paid At" := 0DT;

        if not TypeHelper.GetUserTimezoneOffset(TimezoneOffset) then
            TimezoneOffset := 0;

        if Rec.date_created <> '' then
            if Evaluate(Rec."Created At", Rec.date_created) then
                Rec."Created At" += TimezoneOffset;
        if Rec.date_started <> '' then
            if Evaluate(Rec."Started At", Rec.date_started) then
                Rec."Started At" += TimezoneOffset;
        if Rec.date_expected_finish <> '' then
            if Evaluate(Rec."Expected Finish At", Rec.date_expected_finish) then
                Rec."Expected Finish At" += TimezoneOffset;
        if Rec.date_finished <> '' then
            if Evaluate(Rec."Finished At", Rec.date_finished) then
                Rec."Finished At" += TimezoneOffset;
        if Rec.date_invoiced <> '' then
            if Evaluate(Rec."Invoiced At", Rec.date_invoiced) then
                Rec."Invoiced At" += TimezoneOffset;
        if Rec.date_invoice_paid <> '' then
            if Evaluate(Rec."Invoice Paid At", Rec.date_invoice_paid) then
                Rec."Invoice Paid At" += TimezoneOffset;
    end;
}