pageextension 80155 "EEC Sales Rec. Setup2" extends "Sales & Receivables Setup"
{
    layout
    {
        addlast(General)
        {
            field("EE Default Payment Terms"; Rec."EEC Default Payment Terms")
            {
                ApplicationArea = all;
                ShowMandatory = true;
                ToolTip = 'Specifies the default customer posting group for the Sales Invoices.';
            }
            field("EE Default Cust. Post. Group"; Rec."EEC Default Cust. Post. Group")
            {
                ApplicationArea = all;
                ShowMandatory = true;
                ToolTip = 'Specifies the default customer posting group for the customer.';
            }
            field("EE Default Tax Area Code"; Rec."EEC Default Tax Area Code")
            {
                ApplicationArea = all;
            }
        }
    }
}