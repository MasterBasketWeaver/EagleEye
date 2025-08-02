pageextension 80000 "EE Vendor Card" extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field("EE Source Type"; Rec."EE Source Type")
            {
                ApplicationArea = all;
            }
            field("EE Source No."; Rec."EE Source No.")
            {
                ApplicationArea = all;
            }
            field("EE Export Event Type"; Rec."EE Export Event Type")
            {
                ApplicationArea = all;
            }
        }
    }
    actions
    {
        addlast(Processing)
        {
            action("EE Send Vendor Details")
            {
                ApplicationArea = all;
                Caption = 'Send Vendor Details';
                Image = LaunchWeb;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    if FleetrockMgt.SendVendorDetails(Rec, Enum::"EE Event Type"::Updated) then begin
                        Rec."EE Export Event Type" := Enum::"EE Event Type"::" ";
                        Rec.Modify(false);
                        CurrPage.Update();
                    end else
                        Error(GetLastErrorText());
                end;
            }
            action("EE Get Vendor Details")
            {
                ApplicationArea = all;
                Caption = 'Get Vendor Details';
                Image = Delegate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    Rec.TestField("EE Source Type", Enum::"EE Source Type"::Fleetrock);
                    FleetrockMgt.UpdateVendor(Rec, Rec."EE Source No.", false);
                end;
            }
        }
    }

    var
        FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
}