table 80003 "EE Import/Export Entry"
{
    Caption = 'Fleetrock Import/Export Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "EE Fleetrock Entries";
    LookupPageId = "EE Fleetrock Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "Document Type"; Enum "EE Import Type")
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(3; "Success"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "Error Message"; Text[512])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5; "Import Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = if ("Document Type" = const("Purchase Order")) "EE Purch. Header Staging"."Entry No."
            else if ("Document Type" = const("Repair Order")) "EE Sales Header Staging"."Entry No.";
        }
        field(6; "Imported By"; Code[50])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field(SystemCreatedBy)));
            Editable = false;
        }
        field(7; "Event Type"; Enum "EE Event Type")
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(8; URL; Text[250])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(9; Method; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Request Body"; Text[1024])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; Direction; Enum "EE Direction")
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(15; "Error Stack"; Text[2048])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure DisplayErrorMessage()
    var
        Lines: List of [Text];
        Line: Text;
        ErrorStack: TextBuilder;
    begin
        if Rec."Error Stack" <> '' then begin
            ErrorStack.AppendLine(Rec."Error Message");
            ErrorStack.AppendLine('');
            ErrorStack.AppendLine('Error Stack:');
            if Rec."Error Stack".Contains('\') then begin
                Lines := Rec."Error Stack".Split('\');
                foreach Line in Lines do
                    if Line <> '' then
                        ErrorStack.AppendLine(Line);
            end else
                ErrorStack.AppendLine(Rec."Error Stack");
            Message(ErrorStack.ToText());
        end else
            Message(Rec."Error Message");
    end;
}