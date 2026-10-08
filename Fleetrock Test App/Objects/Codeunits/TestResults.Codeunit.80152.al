// Single instance so results recorded inside the test runner's isolated
// transaction survive its rollback.
codeunit 80152 "EE Test Results"
{
    SingleInstance = true;

    var
        Results: JsonArray;

    procedure Reset()
    begin
        Clear(Results);
    end;

    procedure Add(CodeunitName: Text; FunctionName: Text; IsSuccess: Boolean; ErrorText: Text; CallStack: Text)
    var
        Result: JsonObject;
    begin
        Result.Add('codeunit', CodeunitName);
        Result.Add('test', FunctionName);
        Result.Add('success', IsSuccess);
        if not IsSuccess then begin
            Result.Add('error', ErrorText);
            Result.Add('callStack', CallStack);
        end;
        Results.Add(Result);
    end;

    procedure AsText() ResultText: Text
    begin
        Results.WriteTo(ResultText);
    end;
}
