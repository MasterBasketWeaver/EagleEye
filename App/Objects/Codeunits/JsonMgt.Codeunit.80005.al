codeunit 80005 "EE Json Mgt."
{
    SingleInstance = true;

    procedure GetJsonValueAsText(var JsonObj: JsonObject; KeyName: Text): Text
    var
        T: JsonToken;
    begin
        if not JsonObj.Get(KeyName, T) then
            exit('');
        exit(T.AsValue().AsText());
    end;

    procedure GetJsonValueAsDecimal(var JsonObj: JsonObject; KeyName: Text): Decimal
    var
        T: JsonToken;
    begin
        if not JsonObj.Get(KeyName, T) then
            exit(0);
        if Format(T.AsValue()) = '""' then
            exit(0);
        exit(T.AsValue().AsDecimal());
    end;
}