codeunit 80301 "LWA Access Token"
{
    trigger OnRun()
    begin

    end;

    procedure Refresh_LWA_Token(): Text
    var
        client: HttpClient;
        cont: HttpContent;
        header: HttpHeaders;
        response: HttpResponseMessage;
        Jobject: JsonObject;
        tmpString: Text;
        TypeHelper: Codeunit "Type Helper";


        Client_ID: Text;
        Client_Secret: Text;
        grant_type: Text;
        refresh_token: Text[10000];
        ResponseText: Text;


    begin



        Client_ID := 'xxxxxxxxxxxxxxxx';
        Client_Secret := 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
        grant_type := 'refresh_token';
        refresh_token := 'xxxxxxxxxxxxxxxxxxxxxxxxxxxx';


        tmpString := 'client_id=' + TypeHelper.UrlEncode(Client_ID) +
        '&client_secret=' + TypeHelper.UrlEncode(Client_Secret) +
        '&refresh_token=' + TypeHelper.UrlEncode(refresh_token) +
        '&grant_type=' + TypeHelper.UrlEncode(grant_type);



        cont.WriteFrom(tmpString);
        cont.ReadAs(tmpString);

        cont.GetHeaders(header);
        header.Add('charset', 'UTF-8');
        header.Remove('Content-Type');
        header.Add('Content-Type', 'application/x-www-form-urlencoded');

        client.Post('https://api.amazon.com/auth/o2/token', cont, response);
        response.Content.ReadAs(ResponseText);
        if (response.IsSuccessStatusCode) then begin
            Message(ResponseText);
        end
        else
            Message(ResponseText);


    end;

}