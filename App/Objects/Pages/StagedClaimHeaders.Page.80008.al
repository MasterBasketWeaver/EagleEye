page 80008 "EE Staged Claim Headers"
{
    PageType = List;
    SourceTable = "EE Claim Header";
    Caption = 'Staged Claim Headers';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    LinksAllowed = false;
    AnalysisModeEnabled = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Line)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = all;
                }
                field(id; Rec.id)
                {
                    ApplicationArea = all;
                }
                field(Lines; Rec.Lines)
                {
                    ApplicationArea = all;
                }
                field(group; Rec.group)
                {
                    ApplicationArea = all;
                }
                field(unit_number; Rec.unit_number)
                {
                    ApplicationArea = all;
                }
                field(vendor_name; Rec.vendor_name)
                {
                    ApplicationArea = all;
                }
                field(supplier_name; Rec.supplier_name)
                {
                    ApplicationArea = all;
                }
                field(supplier_custom_id; Rec.supplier_custom_id)
                {
                    ApplicationArea = all;
                }
                field(reference_number; Rec.reference_number)
                {
                    ApplicationArea = all;
                }
                field(credit_number; Rec.credit_number)
                {
                    ApplicationArea = all;
                }
                field(check_number; Rec.check_number)
                {
                    ApplicationArea = all;
                }
                field(tag; Rec.tag)
                {
                    ApplicationArea = all;
                }
                field(status; Rec.status)
                {
                    ApplicationArea = all;
                }
                field(odometer_miles; Rec.odometer_miles)
                {
                    ApplicationArea = all;
                }
                field(engine_hours; Rec.engine_hours)
                {
                    ApplicationArea = all;
                }
                field(date_failure; Rec.date_failure)
                {
                    ApplicationArea = all;
                }
                field(created_by; Rec.created_by)
                {
                    ApplicationArea = all;
                }
                field(date_created; Rec.date_created)
                {
                    ApplicationArea = all;
                }
                field(date_opened; Rec.date_opened)
                {
                    ApplicationArea = all;
                }
                field(date_closed; Rec.date_closed)
                {
                    ApplicationArea = all;
                }
                field(claim_amount; Rec.claim_amount)
                {
                    ApplicationArea = all;
                }
                field(amount_paid; Rec.amount_paid)
                {
                    ApplicationArea = all;
                }
                field("Failure DateTime"; Rec."Failure DateTime")
                {
                    ApplicationArea = all;
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = all;
                }
                field("Opened DateTime"; Rec."Opened DateTime")
                {
                    ApplicationArea = all;
                }
                field("Closed DateTime"; Rec."Closed DateTime")
                {
                    ApplicationArea = all;
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ApplicationArea = all;
                    Caption = 'Imported At';
                }
            }
        }
    }
}