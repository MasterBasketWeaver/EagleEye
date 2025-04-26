pageextension 80152 "EEC Purchase Payables Setup" extends "Purchases & Payables Setup"
{
    layout
    {
        addlast(General)
        {
            field("EE ACH Payment Method"; Rec."EEC ACH Payment Method")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the ACH payment method code for vendors with at least one bank account assigned.';
            }
        }
    }
}