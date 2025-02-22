page 80006 "EE Staged Part Lines"
{
    ApplicationArea = all;
    SourceTable = "EE Part Line Staging";
    UsageCategory = Lists;
    Caption = 'Staged Part Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTableView = sorting("Entry No.") order(descending);

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
                field("Task Entry No."; Rec."Task Entry No.")
                {
                    ApplicationArea = all;
                }
                field("Header Id"; Rec."Header Id")
                {
                    ApplicationArea = all;
                }
                field("Task Id"; Rec."Task Id")
                {
                    ApplicationArea = all;
                }
                field(task_part_id; Rec.task_part_id)
                {
                    ApplicationArea = all;
                }
                field(part_id; Rec.part_id)
                {
                    ApplicationArea = all;
                }
                field(part_number; Rec.part_number)
                {
                    ApplicationArea = all;
                }
                field(part_description; Rec.part_description)
                {
                    ApplicationArea = all;
                }
                field(part_system_code; Rec.part_system_code)
                {
                    ApplicationArea = all;
                }
                field(part_type; Rec.part_type)
                {
                    ApplicationArea = all;
                }
                field(part_price; Rec.part_price)
                {
                    ApplicationArea = all;
                }
                field(part_quantity; Rec.part_quantity)
                {
                    ApplicationArea = all;
                }
                field(part_subtotal; Rec.part_subtotal)
                {
                    ApplicationArea = all;
                }
                field(part_tax_rate; Rec.part_tax_rate)
                {
                    ApplicationArea = all;
                }
                field(part_warranty_savings; Rec.part_warranty_savings)
                {
                    ApplicationArea = all;
                }
                field(part_location; Rec.part_location)
                {
                    ApplicationArea = all;
                }
                field(tire_brand; Rec.tire_brand)
                {
                    ApplicationArea = all;
                }
                field(tire_product_line; Rec.tire_product_line)
                {
                    ApplicationArea = all;
                }
                field(tire_size; Rec.tire_size)
                {
                    ApplicationArea = all;
                }
                field(tire_type; Rec.tire_type)
                {
                    ApplicationArea = all;
                }
                field(date_added; Rec.date_added)
                {
                    ApplicationArea = all;
                    Caption = 'date_added (UTC)';
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