codeunit 80150 "EE Custom Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "No.", false, false)]
    local procedure PurchaseLineOnAfterValidateNo(var Rec: Record "Purchase Line")
    begin
        if Rec."Description 2" = '' then
            Rec."Description 2" := CopyStr(Rec.Description, 1, MaxStrLen(Rec."Description 2"));
    end;
}