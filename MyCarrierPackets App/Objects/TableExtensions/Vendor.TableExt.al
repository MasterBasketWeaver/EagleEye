tableextension 80300 "EEMCP Vendor" extends Vendor
{
    fields
    {
        field(80300; "Dot No."; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "EEMCP Carrier"."DOT No.";
        }
    }
}