page 80005 "EE Staged Task Lines"
{
    ApplicationArea = all;
    SourceTable = "EE Task Line Staging";
    UsageCategory = Lists;
    Caption = 'Staged Task Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = List;

    layout
    {
        area(Content)
        {
            repeater(Line)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Header Entry No."; Rec."Header Entry No.")
                {
                    ApplicationArea = all;
                }
                field("Header Id"; Rec."Header Id")
                {
                    ApplicationArea = all;
                }
                field(task_id; Rec.task_id)
                {
                    ApplicationArea = all;
                }
                field("Part Lines"; Rec."Part Lines")
                {
                    ApplicationArea = all;
                }
                field(labor_hourly_rate; Rec.labor_hourly_rate)
                {
                    ApplicationArea = all;
                }
                field(labor_type; Rec.labor_type)
                {
                    ApplicationArea = all;
                }
                field(labor_hours; Rec.labor_hours)
                {
                    ApplicationArea = all;
                }
                field(labor_subtotal; Rec.labor_subtotal)
                {
                    ApplicationArea = all;
                }
                field(labor_tax_rate; Rec.labor_tax_rate)
                {
                    ApplicationArea = all;
                }
                field(labor_warranty_savings; Rec.labor_warranty_savings)
                {
                    ApplicationArea = all;
                }
                field(labor_complaint; Rec.labor_complaint)
                {
                    ApplicationArea = all;
                }
                field(labor_cause_code; Rec.labor_cause_code)
                {
                    ApplicationArea = all;
                }
                field(labor_correction_code; Rec.labor_correction_code)
                {
                    ApplicationArea = all;
                }
                field(labor_system_code; Rec.labor_system_code)
                {
                    ApplicationArea = all;
                }
                field(labor_system_component_code; Rec.labor_system_component_code)
                {
                    ApplicationArea = all;
                }
                field(scheduled_maintenance_id; Rec.scheduled_maintenance_id)
                {
                    ApplicationArea = all;
                }
                field(issue_id; Rec.issue_id)
                {
                    ApplicationArea = all;
                }
                field(assigned_to; Rec.assigned_to)
                {
                    ApplicationArea = all;
                }
                field(date_added; Rec.date_added)
                {
                    ApplicationArea = all;
                }
                field("Added At"; Rec."Added At")
                {
                    ApplicationArea = all;
                }
                field(Imported; Rec.SystemCreatedAt)
                {
                    ApplicationArea = all;
                }
                field("Imported By"; Rec.SystemCreatedBy)
                {
                    ApplicationArea = all;
                }
            }
        }
    }
}