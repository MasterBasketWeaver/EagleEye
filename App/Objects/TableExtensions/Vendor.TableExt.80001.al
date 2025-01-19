tableextension 80001 "EE Vendor" extends Vendor
{
    fields
    {
        field(80000; "EE Source Type"; Enum "EE Source Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Source Type';
            Editable = false;
        }
        field(80001; "EE Source No."; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Source No.';
            Editable = false;
        }
    }
}