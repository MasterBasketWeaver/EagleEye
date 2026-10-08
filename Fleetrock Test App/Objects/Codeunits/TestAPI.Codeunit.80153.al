// Published as the FleetrockTestAPI web service so tests can be run from outside
// the client: POST ODataV4/FleetrockTestAPI_RunTests?company=<name>
codeunit 80153 "EE Test API"
{
    procedure RunTests(): Text
    var
        TestResults: Codeunit "EE Test Results";
    begin
        TestResults.Reset();
        if not Codeunit.Run(Codeunit::"EE Test Runner") then
            TestResults.Add('EE Test Runner', 'OnRun', false, GetLastErrorText(), GetLastErrorCallStack());
        exit(TestResults.AsText());
    end;
}
