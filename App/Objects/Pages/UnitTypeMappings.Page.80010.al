page 80010 "EE Unit Type Mappings"
{
    PageType = List;
    SourceTable = "EE Unit Type Mapping";
    Caption = 'Unit Type Mappings';
    ApplicationArea = all;
    UsageCategory = Lists;
    DelayedInsert = true;
    LinksAllowed = false;
    AnalysisModeEnabled = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Unit Type"; Rec."Unit Type")
                {
                    ShowMandatory = true;
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ShowCaption = true;
                }
            }
        }
    }
}