page 81001 "EE Fleetrock Setup API"
{
    PageType = API;
    APIPublisher = 'bryanaBcDev';
    APIGroup = 'fleetrockAudit';
    APIVersion = 'v1.0';
    EntityName = 'fleetrockSetup';
    EntitySetName = 'fleetrockSetup';
    SourceTable = "EE Fleetrock Setup";
    DelayedInsert = true;
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
                field(systemId; Rec.SystemId) { Caption = 'systemId'; Editable = false; }
                field(integrationUrl; Rec."Integration URL") { Caption = 'integrationUrl'; }
                field(username; Rec."Username") { Caption = 'username'; }
                field(apiKey; Rec."API Key") { Caption = 'apiKey'; }
                field(vendorUsername; Rec."Vendor Username") { Caption = 'vendorUsername'; }
                field(vendorApiKey; Rec."Vendor API Key") { Caption = 'vendorApiKey'; }
                field(earliestImportDateTime; Rec."Earliest Import DateTime") { Caption = 'earliestImportDateTime'; }
            }
        }
    }
}
