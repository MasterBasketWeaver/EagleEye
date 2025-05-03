table 80302 "EEMCP Carrier Data"
{
    Caption = 'Carrier Data';
    DataClassification = CustomerContent;

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
    }

    keys
    {
        key(PK; "DOT No.")
        {
            Clustered = true;
        }
        key(K2; "Docket No.") { }
    }
}