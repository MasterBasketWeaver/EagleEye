tableextension 80151 "EE Purchase Payables Setup" extends "Purchases & Payables Setup"
{
    fields
    {
        field(80150; "EE ACH Payment Method"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'ACH Payment Method';
            TableRelation = "Payment Method".Code;
        }
    }
}