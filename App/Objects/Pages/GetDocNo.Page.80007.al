page 80007 "EE Get Doc. No."
{
    Caption = 'Enter Document No.';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(DocNo; DocNo)
            {
                ApplicationArea = all;
            }
        }
    }

    var
        DocNo: Text;


    procedure GetDocNo(): Text
    begin
        exit(DocNo);
    end;
}