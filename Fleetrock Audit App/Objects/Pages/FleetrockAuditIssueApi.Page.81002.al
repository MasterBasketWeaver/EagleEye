page 81002 "EE Fleetrock Audit Issue API"
{
    PageType = API;
    APIPublisher = 'bryanaBcDev';
    APIGroup = 'fleetrockAudit';
    APIVersion = 'v1.0';
    EntityName = 'fleetrockAuditIssue';
    EntitySetName = 'fleetrockAuditIssues';
    SourceTable = "EE Fleetrock Audit Issue";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(systemId; Rec.SystemId) { Editable = false; }
                field(entryNo; Rec."Entry No.") { }
                field(orderKind; Rec."Order Kind") { }
                field(orderId; Rec."Order ID") { }
                field(issueCode; Rec."Issue Code") { }
                field(credential; Rec.Credential) { }
                field(lineRef; Rec."Line Ref") { }
                field(partNumber; Rec."Part Number") { }
                field(partDescription; Rec."Part Description") { }
                field(quantity; Rec.Quantity) { }
                field(unitPrice; Rec."Unit Price") { }
                field(expectedAmount; Rec."Expected Amount") { }
                field(actualAmount; Rec."Actual Amount") { }
                field(difference; Rec.Difference) { }
                field(message; Rec.Message) { }
                field(refreshedAt; Rec."Refreshed At") { }
            }
        }
    }
}
