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
                Editable = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Get API Token")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                Image = Refresh;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                begin
                    Message(FleetrockMgt.CheckToGetAPIToken(Rec));
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