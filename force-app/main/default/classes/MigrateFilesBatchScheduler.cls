/*
 * Purpose : To schedule the MigrateFilesBatch class
 * Author  : Giri
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class MigrateFilesBatchScheduler implements Schedulable{
    global String strWhere = '';
    global Boolean bolIncludeUserRecords = false;
    global Boolean bolDeleteUploadedRecord = false;
    global Boolean bolUploadFiles = false;
    global Interface MigrateFilesBatchSchedulerInterface{
       void execute(SchedulableContext sc);
    }   
    global MigrateFilesBatchScheduler(MigrateFilesBatchSchedulerWrapper objMigrateFilesBatchSchedulerWrapper){
       this.strWhere = (objMigrateFilesBatchSchedulerWrapper.strWhere != null && objMigrateFilesBatchSchedulerWrapper.strWhere != '') ? objMigrateFilesBatchSchedulerWrapper.strWhere : '';
       this.bolIncludeUserRecords = objMigrateFilesBatchSchedulerWrapper.bolIncludeUserRecords;
       this.bolDeleteUploadedRecord = objMigrateFilesBatchSchedulerWrapper.bolDeleteUploadedRecords;
       this.bolUploadFiles = objMigrateFilesBatchSchedulerWrapper.bolUploadFiles;
    }
    global void execute(SchedulableContext sc) {
       if(bolUploadFiles){ // Schedule if content document needs to be migrated to aws s3
          Database.executebatch(new MigrateFilesBatch(strWhere, bolIncludeUserRecords, bolDeleteUploadedRecord), 200);
       }else{ // Schedule if content document link needs to be migrated to aws s3
          Database.executebatch(new MigrateCDLFilesBatch(strWhere, bolIncludeUserRecords, bolDeleteUploadedRecord), 200);
       }
    }

   global class MigrateFilesBatchSchedulerWrapper {
      @AuraEnabled
      global String strWhere { get; set;}
      @AuraEnabled
      global Boolean bolIncludeUserRecords { get; set;}
      @AuraEnabled
      global Boolean bolDeleteUploadedRecords { get; set;}
      @AuraEnabled
      global Boolean bolUploadFiles { get; set;}
   }
   
}