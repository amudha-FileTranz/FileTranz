/*
 * Purpose : To schedule the MigrateAttachmentsBatch class
 * Author  : Giri
 */
global with sharing class MigrateAttachmentsBatchScheduler implements Schedulable{
    global String strWhere = '';
    global Boolean bolDeleteUploadedRecords = false;
    global Interface MigrateAttachmentsBatchSchedulerInterface{
        void execute(SchedulableContext sc);
    }
    global MigrateAttachmentsBatchScheduler(String strWhere, Boolean bolDeleteUploadedRecords){
        this.strWhere = strWhere;
        this.bolDeleteUploadedRecords = bolDeleteUploadedRecords;
    }
    global void execute(SchedulableContext sc) {
        Database.executebatch(new MigrateAttachmentsBatch(strWhere, bolDeleteUploadedRecords), 1);
    }
}