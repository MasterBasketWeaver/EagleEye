tableextension 80150 "EEC Vendor2" extends Vendor
{
    fields
    {
        field(80150; "EEC NonMandatory Ext. Doc. No."; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Non-Mandatory Ext. Doc. No.';
        }
    }
}