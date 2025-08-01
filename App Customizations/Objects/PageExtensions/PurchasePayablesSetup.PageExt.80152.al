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
            field("EEC Check Payment Method"; Rec."EEC Check Payment Method")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the check payment method code for vendors with no bank accounts assigned.';
            }
            field("EE Default Payment Terms"; Rec."EEC Default Payment Terms")
            {
                ApplicationArea = all;
                ShowMandatory = true;
                ToolTip = 'Specifies the default payment terms code for vendors and purchase invoices.';
            }
            field("EEC Default Payment Method"; Rec."EEC Default Payment Method")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the default payment method to be used when creating new vendors.';
            }
            field("EE Default Vendor. Post. Group"; Rec."EEC Default Vend. Post. Group")
            {
                ApplicationArea = all;
                ShowMandatory = true;
                ToolTip = 'Specifies the default vendor posting group to be used when creating new vendors.';
            }
        }
    }
}