page 80301 "EEMCP Carriers"
{
    SourceTable = "EEMCP Carrier";
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    AnalysisModeEnabled = false;
    LinksAllowed = false;
    Caption = 'Carriers';

    layout
    {
        area(Content)
        {
            repeater(Line)
            {
                field("DOT No."; Rec."DOT No.")
                {
                    ApplicationArea = all;
                }
                field("Docket No."; Rec."Docket No.")
                {
                    ApplicationArea = all;
                }
                field("Last Modifued At"; Rec."Last Modifued At")
                {
                    ApplicationArea = all;
                }
                field("Requires Update"; Rec."Requires Update")
                {
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Get Data")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Refresh;

                trigger OnAction()
                var
                    MCPMgt: Codeunit "EEMCP My Carrier Packets Mgt.";
                begin
                    MCPMgt.GetCarrierData(Rec);
                end;
            }
            action("View Data")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = CodesList;
                RunObject = page "EEMCP Carrier Data";
                RunPageLink = "DOT No." = field("DOT No.");
                RunPageMode = View;
            }
        }
    }
}