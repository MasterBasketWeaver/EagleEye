table 80301 "EEMCP Carrier"
{
    Caption = 'Carrier';
    DataClassification = CustomerContent;
    DrillDownPageId = "EEMCP Carriers";
    LookupPageId = "EEMCP Carriers";

    fields
    {
        field(1; "DOT No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "Docket No."; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(3; "Last Modifued At"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "Requires Update"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5; "Vendor No."; Code[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Vendor."No.";
        }
        field(10; "Error Message"; Text[512])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; "Error Stack"; Text[2048])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; "Last Attempted Update"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "DOT No.")
        {
            Clustered = true;
        }
        key(K2; "Docket No.") { }
        key(K3; "Requires Update") { }
    }

    trigger OnDelete()
    var
        CarrierData: Record "EEMCP Carrier Data";
    begin
        if CarrierData.Get("DOT No.") then
            CarrierData.Delete(true);
    end;
}