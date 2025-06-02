pageextension 80302 "EEMCP Vendor Bank Account Card" extends "Vendor Bank Account Card"
{
    layout
    {
        addlast(General)
        {
            field("EEMCP Updated From MCP"; Rec."EEMCP Updated From MCP")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies if all the data in this record was updated from the MCP integration.';
            }
            field("EEMCP Last Non-MCP Update By"; Rec."EEMCP Last Non-MCP Update By")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the last user to edit this record.';
            }
            field("EEMCP Last Non-MCP Update At"; Rec."EEMCP Last Non-MCP Update At")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies when the last edit to this record was performed.';
            }
        }
    }
}