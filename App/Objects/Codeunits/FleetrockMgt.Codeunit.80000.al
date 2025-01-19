codeunit 80000 "EE Fleetrock Mgt."
{
    [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterInsertEvent, '', false, false)]
    local procedure GLAccountOnAfterInsert(var Rec: Record "G/L Account")
    begin
        SyncGLToFleetRock(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterModifyEvent, '', false, false)]
    local procedure GLAccountOnAfterModify(var Rec: Record "G/L Account")
    begin
        SyncGLToFleetRock(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterDeleteEvent, '', false, false)]
    local procedure GLAccountOnAfterDelete(var Rec: Record "G/L Account")
    begin
        SyncGLToFleetRock(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterRenameEvent, '', false, false)]
    local procedure GLAccountOnRenameDelete(var Rec: Record "G/L Account")
    begin
        SyncGLToFleetRock(Rec, false);
    end;

    procedure SyncGLToFleetRock(var GLAccount: Record "G/L Account"; Deleted: Boolean)
    begin

    end;
}