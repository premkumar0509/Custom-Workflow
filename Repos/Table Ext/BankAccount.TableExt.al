tableextension 50100 "Bank Account" extends "Bank Account"
{
    fields
    {
        field(50100; Status; Enum "Bank Account Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the current approval status of the record.';
            Editable = false;
            DataClassification = ToBeClassified;
        }
    }

    procedure GetStatusStyleExpr(): Text
    begin
        case Rec.Status of
            Rec.Status::Open:
                exit('Favorable'); // Green
            Rec.Status::Released:
                exit('Strong'); // Bold Black
            Rec.Status::"Pending Approval":
                exit('Ambiguous'); // Yellow
            Rec.Status::Rejected:
                exit('Unfavorable'); // Red
        end;
    end;
}