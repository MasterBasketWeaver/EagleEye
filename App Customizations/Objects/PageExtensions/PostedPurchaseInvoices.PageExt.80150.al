pageextension 80150 "EEC Posted Purch. Invoices." extends "Posted Purchase Invoices"
{
    layout
    {
        addafter("No.")
        {
            field("EE Load No."; LoadNo)
            {
                ApplicationArea = all;
                Editable = false;
                Caption = 'Load Number';
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        if RecRef.FieldExist(50200) then
            LoadNo := Format(RecRef.Field(50200).Value());
    end;

    var
        LoadNo: Text;
}