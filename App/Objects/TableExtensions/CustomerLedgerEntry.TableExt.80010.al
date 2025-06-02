tableextension 80010 "EE Customer Ledger Entry" extends "Cust. Ledger Entry"
{
    fields
    {
        field(80010; "EE Load Number"; Code[35])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Sales Invoice Header"."EE Load Number" where("No." = field("Document No.")));
            Editable = false;
            Caption = 'Load Number';
        }
    }
}