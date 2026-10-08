codeunit 80151 "EE Test Runner"
{
    Subtype = TestRunner;
    TestIsolation = Codeunit;

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"EE Fleetrock ID Posting Test");
    end;

    trigger OnBeforeTestRun(CodeunitId: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        ClearLastError();
        exit(true);
    end;

    trigger OnAfterTestRun(CodeunitId: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    var
        TestResults: Codeunit "EE Test Results";
    begin
        if FunctionName = '' then
            exit;
        TestResults.Add(CodeunitName, FunctionName, IsSuccess, GetLastErrorText(), GetLastErrorCallStack());
    end;
}
