pageextension 80301 "EEMCP Vendor Card" extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field("EEMCP Dot No."; Rec."EEMCP Dot No.")
            {
                ApplicationArea = all;
            }
            field("EEMCP Docket No."; Rec."EEMCP Docket No.")
            {
                ApplicationArea = all;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action("EEMCP Set Layout Attachemnt")
            {
                ApplicationArea = all;
                Caption = 'Set Layout Attachemnt';
                Image = Document;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    CarrierData: Record "EEMCP Carrier Data";
                    MCPMgt: Codeunit "EEMCP My Carrier Packets Mgt.";
                begin
                    if CarrierData.Get(Rec."EEMCP Dot No.") and (CarrierData.RemitEmail <> '') then
                        MCPMgt.AddVendorDocumentLayouts(Rec, CarrierData.RemitEmail)
                    else
                        if Rec."E-Mail" <> '' then
                            MCPMgt.AddVendorDocumentLayouts(Rec, Rec."E-Mail")
                        else
                            Error('No carrier data or email address found for vendor %1', Rec.Name);
                end;
            }
        }
    }
}