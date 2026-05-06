tableextension 80005 "EE Sales Inv. Header" extends "Sales Invoice Header"
{
    fields
    {
        field(80000; "EE Fleetrock ID"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Fleetrock ID';
        }
        field(80005; "EE Sent Payment"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Sent Payment';
        }
        field(80006; "EE Sent Payment DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Sent Payment DateTime';
        }
        field(80007; "EE No Repair Order On Payment"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'No Repair Order On Payment';
            ToolTip = 'Specifies if there is no related Repair Order found when trying to send a payment update to Fleetrock.';
        }
        field(80010; "EE Load Number"; Code[35])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Load Number';
        }
    }

    keys
    {
        key(FleetrockID; "EE Fleetrock ID") { }
    }
}