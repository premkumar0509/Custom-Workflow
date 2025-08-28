codeunit 50100 "Custom Workflow Mgmt"
{
    procedure CheckApprovalsWorkflowEnabled(var RecRef: RecordRef): Boolean
    begin
        if not WorkflowMgt.CanExecuteWorkflow(RecRef, GetWorkflowCode(RUNWORKFLOWONSENDFORAPPROVALCODELbl, RecRef)) then
            Error(NoWorkflowEnabledErr);
        exit(true);
    end;

    procedure GetWorkflowCode(WorkflowCode: code[128]; RecRef: RecordRef): Code[128]
    begin
        exit(DelChr(StrSubstNo(WorkflowCode, RecRef.Name), '=', ' '));
    end;


    [IntegrationEvent(false, false)]
    procedure OnSendWorkflowForApproval(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelWorkflowForApproval(var RecRef: RecordRef)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    local procedure OnAddWorkflowEventsToLibrary()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Account");

        WorkflowEventHandling.AddEventToLibrary(GetWorkflowCode(RUNWORKFLOWONSENDFORAPPROVALCODELbl, RecRef), Database::"Bank Account",
          GetWorkflowEventDesc(RequestApprovalEventDescTxt, RecRef), 0, false);

        WorkflowEventHandling.AddEventToLibrary(GetWorkflowCode(RUNWORKFLOWONCANCELFORAPPROVALCODELbl, RecRef), DATABASE::"Bank Account",
          GetWorkflowEventDesc(CancelApprovalEventDescTxt, RecRef), 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Workflow Mgmt", 'OnSendWorkflowForApproval', '', false, false)]
    local procedure RunWorkflowOnSendWorkflowForApproval(var RecRef: RecordRef)
    begin
        WorkflowMgt.HandleEvent(GetWorkflowCode(RUNWORKFLOWONSENDFORAPPROVALCODELbl, RecRef), RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Workflow Mgmt", 'OnCancelWorkflowForApproval', '', false, false)]
    local procedure RunWorkflowOnCancelWorkflowForApproval(var RecRef: RecordRef)
    begin
        WorkflowMgt.HandleEvent(GetWorkflowCode(RUNWORKFLOWONCANCELFORAPPROVALCODELbl, RecRef), RecRef);
    end;

    procedure GetWorkflowEventDesc(WorkflowEventDesc: Text; RecRef: RecordRef): Text[250]
    begin
        exit(CopyStr(StrSubstNo(WorkflowEventDesc, RecRef.Name), 1, 250));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', false, false)]
    local procedure OnOpenDocument(RecRef: RecordRef; var Handled: Boolean)
    var
        CustomWorkflowHdr: Record "Bank Account";
    begin
        case RecRef.Number of
            Database::"Bank Account":
                begin
                    RecRef.SetTable(CustomWorkflowHdr);
                    CustomWorkflowHdr.Validate(Status, CustomWorkflowHdr.Status::Open);
                    CustomWorkflowHdr.Modify(true);
                    Handled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSetStatusToPendingApproval', '', false, false)]
    local procedure OnSetStatusToPendingApproval(RecRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    var
        CustomWorkflowHdr: Record "Bank Account";
    begin
        case RecRef.Number of
            Database::"Bank Account":
                begin
                    RecRef.SetTable(CustomWorkflowHdr);
                    CustomWorkflowHdr.Validate(Status, CustomWorkflowHdr.Status::"Pending Approval");
                    CustomWorkflowHdr.Modify(true);
                    Variant := CustomWorkflowHdr;
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', false, false)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        CustomWorkflowHdr: Record "Bank Account";
    begin
        case RecRef.Number of
            DataBase::"Bank Account":
                begin
                    RecRef.SetTable(CustomWorkflowHdr);
                    ApprovalEntryArgument."Document No." := CustomWorkflowHdr."No.";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', false, false)]
    local procedure OnReleaseDocument(RecRef: RecordRef; var Handled: Boolean)
    var
        CustomWorkflowHdr: Record "Bank Account";
    begin
        case RecRef.Number of
            DataBase::"Bank Account":
                begin
                    RecRef.SetTable(CustomWorkflowHdr);
                    CustomWorkflowHdr.Validate(Status, CustomWorkflowHdr.Status::Released);
                    CustomWorkflowHdr.Modify(true);
                    Handled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnApproveApprovalRequest', '', false, false)]
    local procedure OnApproveApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    var
        CustomWorkflowHdr: Record "Bank Account";
    begin
        case ApprovalEntry."Table ID" of
            Database::"Bank Account":
                if CustomWorkflowHdr.Get(ApprovalEntry."Document No.") then begin
                    CustomWorkflowHdr.Validate(Status, CustomWorkflowHdr.Status::Released);
                    CustomWorkflowHdr.Modify(true);
                end;
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnRejectApprovalRequest', '', false, false)]
    local procedure OnRejectApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    var
        CustomWorkflowHdr: Record "Bank Account";
    begin
        case ApprovalEntry."Table ID" of
            DataBase::"Bank Account":
                if CustomWorkflowHdr.Get(ApprovalEntry."Document No.") then begin
                    CustomWorkflowHdr.Validate(Status, CustomWorkflowHdr.Status::Rejected);
                    CustomWorkflowHdr.Modify(true);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowTableRelationsToLibrary', '', false, false)]
    local procedure AddWorkflowTableRelationsToLibrary()
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        WorkflowSetup.InsertTableRelation(Database::"Bank Account", 1, Database::"Approval Entry", 2);
    end;

    var

        WorkflowMgt: Codeunit "Workflow Management";
        RUNWORKFLOWONSENDFORAPPROVALCODELbl: Label 'RUNWORKFLOWONSEND%1FORAPPROVAL', Comment = '%1 = RecordRef';
        RUNWORKFLOWONCANCELFORAPPROVALCODELbl: Label 'RUNWORKFLOWONCANCEL%1FORAPPROVAL', Comment = '%1 = RecordRef';
        RequestApprovalEventDescTxt: Label 'Approval of a %1 is requested.', Comment = '%1 = RecordRef';
        CancelApprovalEventDescTxt: Label 'Approval of a %1 is canceled.', Comment = '%1 = RecordRef';

        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
}