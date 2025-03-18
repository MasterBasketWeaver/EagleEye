codeunit 80100 "EE Alvys Mgt."
{
    var
        AlvysSetup: Record "EE Alvys Setup";
        RestAPIMgt: Codeunit "EE REST API Mgt.";
        JsonMgt: Codeunit "EE Json Mgt.";


    local procedure GetAndCheckSetup()
    begin
        AlvysSetup.Get();
        AlvysSetup.TestField("Integration URL");
        AlvysSetup.TestField("Tenant ID");
        AlvysSetup.TestField("Client ID");
        AlvysSetup.TestField("Client Secret");
    end;

    procedure CheckToGetAPIToken(): Text
    var
        ResponseText: Text;
    begin
        GetAndCheckSetup();
        if (AlvysSetup."API Token" <> '') and (AlvysSetup."API Token Expiry DateTime" >= CurrentDateTime()) then
            exit(AlvysSetup."API Token");
        exit(CheckToGetAPIToken(AlvysSetup));
    end;

    procedure CheckToGetAPIToken(var AlvysSetup: Record "EE Alvys Setup"): Text
    var
        JsonTkn: JsonToken;
        HourDelay: Duration;
        SendTime: DateTime;
        JsonBody: JsonObject;
        URL: Text;
    begin
        SendTime := CurrentDateTime();
        URL := StrSubstNo('%1/api/authentication/%2/token', AlvysSetup."Integration URL", AlvysSetup."Tenant ID");
        //AlvysSetup."Client ID", AlvysSetup."Client Secret")

        // {
        //     "tenant_id": "EA455",
        //     "client_id": "4d476e6d-67c5-4be4-965d-f4d8cff83655",
        //     "client_secret": "ZFM5OJbjRU6YNOdR8qCF4/yMuIzDi3y/LFPD+lCQTK4bj9Uw7MoAfXZKBrs4mQoj5Jf6eZtMVnx0H8L6BPUt0w==",
        //     "grant_type": "client_credentials"
        // }

        JsonBody.Add('tenant_id', AlvysSetup."Tenant ID");
        JsonBody.Add('client_id', AlvysSetup."Client ID");
        JsonBody.Add('client_secret', AlvysSetup."Client Secret");
        JsonBody.Add('grant_type', 'client_credentials');


        JsonTkn := RestAPIMgt.GetResponseWithJsonBodyAsJsonToken('POST', URL, 'access_token', JsonBody);
        JsonTkn.WriteTo(AlvysSetup."API Token");

        HourDelay := 3600;
        AlvysSetup.Validate("API Token", AlvysSetup."API Token".Replace('"', ''));
        AlvysSetup.Validate("API Token Expiry DateTime", SendTime + HourDelay);
        // AlvysSetup.Validate("Use API Token", true);
        AlvysSetup.Modify(true);
        exit(AlvysSetup."API Token");
    end;
}