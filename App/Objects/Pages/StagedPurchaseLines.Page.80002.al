page 80002 "EE Staged Purchased Lines"
{
    ApplicationArea = all;
    SourceTable = "EE Purch. Line Staging";
    UsageCategory = Lists;
    Caption = 'Staged Purchase Lines';
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
                field(id; Rec.id)
                {
                    ApplicationArea = All;
                }
                field("Header Entry No."; Rec."Header Entry No.")
                {
                    ApplicationArea = all;
                }
                field(part_id; Rec.part_id)
                {
                    ApplicationArea = All;
                }
                field(part_number; Rec.part_number)
                {
                    ApplicationArea = All;
                }
                field(part_description; Rec.part_description)
                {
                    ApplicationArea = All;
                }
                field(part_system_code; Rec.part_system_code)
                {
                    ApplicationArea = All;
                }
                field(part_type; Rec.part_type)
                {
                    ApplicationArea = All;
                }
                field(tag; Rec.tag)
                {
                    ApplicationArea = All;
                }
                field(part_quantity; Rec.part_quantity)
                {
                    ApplicationArea = All;
                }
                field(unit_price; Rec.unit_price)
                {
                    ApplicationArea = All;
                }
                field(line_total; Rec.line_total)
                {
                    ApplicationArea = All;
                }
                field(date_added; Rec.date_added)
                {
                    ApplicationArea = all;
                }
                field(Added; Rec.Added)
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