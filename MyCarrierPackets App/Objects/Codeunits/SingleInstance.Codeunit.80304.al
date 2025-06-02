codeunit 80304 "EEMCP Single Instance"
{
    SingleInstance = true;

    procedure GetUpdatedFromMCP(): Boolean
    begin
        exit(UpdatedFromMCP);
    end;

    procedure SetUpdatedFromMCP(Status: Boolean)
    begin
        UpdatedFromMCP := Status;
    end;

    var
        UpdatedFromMCP: Boolean;
}