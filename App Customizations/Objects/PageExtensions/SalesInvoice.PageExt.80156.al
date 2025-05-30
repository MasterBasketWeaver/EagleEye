pageextension 80156 "EEC Sales Invoice" extends "Sales Invoice"
{
    layout
    {
        modify("Payment Terms Code")
        {
            trigger OnBeforeValidate()
            begin
                Rec."EEC Updated Payment Terms" := true;
            end;
        }
        modify("Payment Method Code")
        {
            trigger OnBeforeValidate()
            begin
                Rec."EEC Updated Payment Method" := true;
            end;
        }
    }
}