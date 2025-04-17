page 80100 "EE Alvys Setup"
{
    Caption = 'Alvys Setup';
    ApplicationArea = all;
    UsageCategory = Administration;
    SourceTable = "EE Alvys Setup";

    layout
    {
        area(Content)
        {
            field("Integration URL"; Rec."Integration URL")
            {
                ApplicationArea = All;
                Caption = 'Integration URL';
            }
            field("Tenant ID"; Rec."Tenant ID")
            {
                ApplicationArea = All;
                Caption = 'Tenant ID';
            }
            field("Client ID"; Rec."Client ID")
            {
                ApplicationArea = All;
                Caption = 'Client ID';
            }
            field("Client Secret"; Rec."Client Secret")
            {
                ApplicationArea = All;
                Caption = 'Client Secret';
            }
            field("API Token"; Rec."API Token")
            {
                ApplicationArea = All;
                Caption = 'API Token';
            }
            field("API Token Expiry DateTime"; Rec."API Token Expiry DateTime")
            {
                ApplicationArea = All;
                Caption = 'API Token Expiry DateTime';
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
                // AlvysMgt: Codeunit "EE Alvys Mgt.";
                // TestCodeunit: Codeunit "EE Codeunit Test";
                begin
                    // Message(AlvysMgt.CheckToGetAPIToken(Rec));

                    // TestCodeunit.TestAPICall();
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