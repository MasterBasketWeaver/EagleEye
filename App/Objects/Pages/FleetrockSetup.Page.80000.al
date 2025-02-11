page 80000 "EE Fleetrock Setup"
{
    SourceTable = "EE Fleetrock Setup";
    ApplicationArea = all;
    UsageCategory = Administration;
    Caption = 'Fleetrock Setup';

    layout
    {
        area(Content)
        {
            field("Integration URL"; Rec."Integration URL")
            {
                ApplicationArea = All;
                ShowMandatory = true;
            }
            field("Username"; Rec.Username)
            {
                ApplicationArea = All;
                ShowMandatory = true;
            }
            field("API Key"; Rec."API Key")
            {
                ApplicationArea = All;
                ShowMandatory = true;
            }
            field("API Token"; Rec."API Token")
            {
                ApplicationArea = All;
            }
            field("API Token Expiry Date"; Rec."API Token Expiry Date")
            {
                ApplicationArea = all;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Refresh API Token")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Refresh;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                begin
                    Message(FleetrockMgt.CheckToGetAPIToken(Rec));
                end;
            }
            action("Get Units")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Union;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                begin
                    FleetrockMgt.GetUnits();
                end;
            }
            action("Get Suppliers")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Vendor;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                begin
                    FleetrockMgt.GetSuppliers();
                end;
            }
            action("Get Open POs")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Purchase;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                begin
                    FleetrockMgt.GetPurchaseOrders(Enum::"EE Purch. Order Status"::Open);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(true);
        end;
    end;
}