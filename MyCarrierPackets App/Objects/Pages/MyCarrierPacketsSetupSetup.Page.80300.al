page 80300 "EEMCP My Carrier Packets Setup"
{
    Caption = 'My Carrier Packets Setup';
    ApplicationArea = all;
    UsageCategory = Administration;
    SourceTable = "EEMCP MyCarrierPackets Setup";

    layout
    {
        area(Content)
        {
            field("Integration URL"; Rec."Integration URL")
            {
                ApplicationArea = All;
            }
            field("Tenant ID"; Rec.Username)
            {
                ApplicationArea = All;
            }
            field("Client ID"; Rec.Password)
            {
                ApplicationArea = All;
            }
            field("API Token"; Rec."API Token")
            {
                ApplicationArea = All;
            }
            field("API Refresh Token"; Rec."API Refresh Token")
            {
                ApplicationArea = all;
            }
            field("API Token Expiry DateTime"; Rec."API Token Expiry DateTime")
            {
                ApplicationArea = All;
            }
            field("Last Packet DateTime"; Rec."Last Packet DateTime")
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
                    MyCarrierPacketsMgt: Codeunit "EEMCP My Carrier Packets Mgt.";
                begin
                    Message(MyCarrierPacketsMgt.CheckToGetAPIToken(Rec));
                    Rec.Modify(true);
                end;
            }
            action("Get Completed Packets")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Refresh;

                trigger OnAction()
                var
                    MyCarrierPacketsMgt: Codeunit "EEMCP My Carrier Packets Mgt.";
                    JsonArry: JsonArray;
                    s: Text;
                begin
                    JsonArry := MyCarrierPacketsMgt.GetCompletedPackets(Today(), Today());
                    JsonArry.WriteTo(s);
                    Message(s);
                end;
            }
            action("Get Monitored Carriers")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Refresh;

                trigger OnAction()
                var
                    MyCarrierPacketsMgt: Codeunit "EEMCP My Carrier Packets Mgt.";
                    JsonArry: JsonArray;
                    s: Text;
                begin
                    MyCarrierPacketsMgt.GetMonitoredCarrierData();
                    // JsonArry.WriteTo(s);
                    // Message(s);
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