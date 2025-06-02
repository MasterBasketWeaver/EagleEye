tableextension 80301 "EEMCP Vendor Bank Account" extends "Vendor Bank Account"
{
    fields
    {
        field(80300; "EEMCP Updated From MCP"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Updated From MCP';
        }
        field(80301; "EEMCP Last Non-MCP Update By"; Code[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Last Non-MCP Update By';
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(80302; "EEMCP Last Non-MCP Update At"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Last Non-MCP Update At';
        }
    }
}