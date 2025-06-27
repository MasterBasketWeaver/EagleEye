tableextension 80150 "EEC Vendor2" extends Vendor
{
    fields
    {
        field(80150; "EEC NonMandatory Ext. Doc. No."; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Non-Mandatory Ext. Doc. No.';
        }
        field(80160; "EEC Updated Payment Terms"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Updated Payment Terms';
            Editable = false;
        }
        field(80161; "EEC Updated Payment Method"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Updated Payment Method';
            Editable = false;
        }
    }
}