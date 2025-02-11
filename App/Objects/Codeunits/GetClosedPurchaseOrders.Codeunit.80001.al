codeunit 80001 "EE Get Closed Purch. Order"
{
    trigger OnRun()
    var
        PurchaseHeader: Record "Purchase Header";
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        JsonArry, Lines : JsonArray;
        T: JsonToken;
        OrderJsonObj: JsonObject;
        JsonVal: JsonValue;
        s: Text;
    begin
        JsonArry := FleetRockMgt.GetPurchaseOrders(Enum::"EE Purch. Order Status"::Closed);

        PurchaseHeader.SetCurrentKey("EE Fleetrock ID");

        foreach T in JsonArry do begin
            OrderJsonObj := T.AsObject();
            OrderJsonObj.Get('id', T);
            JsonVal := T.AsValue();
            s := JsonVal.AsText();
            PurchaseHeader.SetRange("EE Fleetrock ID", s);
            if PurchaseHeader.IsEmpty() then
                FleetRockMgt.CreatePurchaseOrder(OrderJsonObj);
        end;
    end;
}