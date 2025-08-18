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
                field("Vendor No."; Rec."Vendor No.")
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
                field("Last Attempted Update"; Rec."Last Attempted Update")
                {
                    ApplicationArea = all;
                }
                field("Error Message"; Rec."Error Message")
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
            action("View Error")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Error;
                Enabled = Rec."Error Message" <> '';

                trigger OnAction()
                begin
                    Message('%1\%2', Rec."Error Message", Rec."Error Stack");
                end;
            }
            action("Get Data")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Refresh;

                trigger OnAction()
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
            action("Create/Update Vendor")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Vendor;

                trigger OnAction()
                var
                    Vendor: Record Vendor;

                    ContBusRel: Record "Contact Business Relation";
                begin
                    MCPMgt.CreateAndUpdateVendorFromCarrier(Rec, true);
                    if Vendor.Get(Rec."Vendor No.") then
                        Page.Run(Page::"Vendor Card", Vendor);
                end;
            }
            action("Update All Vendors")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = VendorCode;

                trigger OnAction()
                var
                    Carrier: Record "EEMCP Carrier";
                    Window: Dialog;
                    i, RecCount : Integer;
                    PopulateVendors: Boolean;
                begin
                    if not Confirm('Are you sure you want to update all vendors?') then
                        exit;

                    PopulateVendors := Confirm('Update vendor records?', false);

                    // Carrier.SetFilter("Docket No.", '<>%1', '');
                    if not Carrier.FindSet(true) then
                        exit;
                    RecCount := Carrier.Count();
                    Window.Open('Updating\#1###');
                    if PopulateVendors then
                        repeat
                            i += 1;
                            Window.Update(1, StrSubstNo('%1 of %2', i, RecCount));
                            // MCPMgt.GetCarrierData(Carrier);
                            MCPMgt.CreateAndUpdateVendorFromCarrier(Carrier, false);
                        until Carrier.Next() = 0
                    else
                        repeat
                            i += 1;
                            Window.Update(1, StrSubstNo('%1 of %2', i, RecCount));
                            MCPMgt.GetCarrierData(Carrier);
                        until Carrier.Next() = 0;
                    Window.Close();
                end;
            }


        }
    }

    var
        MCPMgt: Codeunit "EEMCP My Carrier Packets Mgt.";
}