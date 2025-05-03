table 80300 "EEMCP MyCarrierPackets Setup"
{
    Caption = 'MyCarrierPackets Setup';
    DataClassification = CustomerContent;
    // DrillDownPageId = "EEMCP Fleetrock Setup";
    // LookupPageId = "EEMCP Fleetrock Setup";

    fields
    {
        field(1; "Primary Key"; Code[1])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "Integration URL"; Text[128])
        {
            DataClassification = CustomerContent;
        }
        field(3; "Username"; Text[64])
        {
            DataClassification = CustomerContent;
        }
        field(4; "Password"; Text[64])
        {
            DataClassification = CustomerContent;
        }
        field(5; "API Token"; Text[1024])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6; "API Token Expiry DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7; "API Refresh Token"; Text[64])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Last Packet DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(11; "Monitored Carrier Cutoff"; DateTime)
        {
            DataClassification = CustomerContent;
        }

    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}