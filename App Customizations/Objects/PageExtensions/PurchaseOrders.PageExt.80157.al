pageextension 80157 "EEC Purchase Order List" extends "Purchase Order List"
{
    actions
    {
        addlast(processing)
        {
            action("EEC Delete Invalid Orders")
            {
                ApplicationArea = all;
                Image = Delete;

                trigger OnAction()
                var
                    PurchHeader: Record "Purchase Header";
                begin
                    if not Confirm('Delete all invalid orders?') then
                        exit;
                    PurchHeader.SetRange("Document Type", Rec."Document Type"::Order);
                    PurchHeader.SetRange("Buy-from Vendor No.", '');
                    PurchHeader.Delete(true);
                end;
            }
        }
    }
}