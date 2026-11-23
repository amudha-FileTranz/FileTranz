/*
 * Purpose : To upload content documents by based on the content document links from the salesforce to aws S3 server.
 * Author  : Giri
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class MigrateCDLFilesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    String strWhere = '';
    String strAPIFailedRecordIds ='';
    String strMaxSizeExceededIds = '';
    String strFailedIds = '';
    Boolean bolIncludeUserRecords = false;
    Boolean bolDeleteUploadedRecords = false;
    map<String, String> mapOfileTypes = new Map<String, String>();
    Integer intNumOfErrors = 0;
    Set<Id> setEligibleDocumentIds = new Set<Id>();
    Set<Id> setContentDocumentIds = new Set<Id>();
    List<External_Files__c> lstExternalFiles = new List<External_Files__c>();
    
    
    global MigrateCDLFilesBatch(String strWhere, boolean bolIncludeUserRecords, boolean bolDeleteUploadedRecords){
        this.strWhere = strWhere;
        this.bolIncludeUserRecords = bolIncludeUserRecords;
        this.bolDeleteUploadedRecords = bolDeleteUploadedRecords;
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        for (AWS_File_Type_Mapping__mdt objMdtIterator : [SELECT DeveloperName, File_Type_Application_Name__c FROM AWS_File_Type_Mapping__mdt WHERE File_Type_Application_Name__c != NULL WITH USER_MODE]) {
            mapOfileTypes.put(objMdtIterator.DeveloperName, objMdtIterator.File_Type_Application_Name__c);
        }
        CommonUtilities.ExternalStorageSettingWrapper objESSettings = CommonUtilities.getActiveStorageSetting();
        Integer strMaximumFileSize = Integer.valueOf(objESSettings.strMaximumFileSize);
        strWhere = (strWhere != '' && strWhere != null) ? (strWhere + ' AND ') : ' WHERE ';
        strWhere = strWhere + ' ContentDocument.LatestPublishedVersion.contentsize < ' + strMaximumFileSize + ' AND ContentDocument.LatestPublishedVersion.Is_Migrated__c = false';
        String strQuery = 'SELECT Id, LinkedEntityId, LinkedEntity.Type, ContentDocumentId, ContentDocument.LatestPublishedVersion.FileExtension, ContentDocument.LatestPublishedVersion.Title FROM ContentDocumentLink ' + strWhere;
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext bc, List<ContentDocumentLink> lsContDoclink){
        try{
            Set<Id> setTempEligibleDocumentIds = new Set<Id>();
            for (ContentDocumentLink objDocumentLink : lsContDoclink) {
                if(!setEligibleDocumentIds.contains(objDocumentLink.ContentDocumentId)) {
                    setContentDocumentIds.add(objDocumentLink.ContentDocumentId);
                }
            }
            List<ContentDocumentLink> lstDocumentLink = [ SELECT Id, LinkedEntityId, LinkedEntity.Type,	ContentDocumentId, ContentDocument.LatestPublishedVersion.FileExtension, ContentDocument.LatestPublishedVersion.Title, ContentDocument.ContentAssetId FROM ContentDocumentLink WHERE ContentDocumentId IN:setContentDocumentIds WITH USER_MODE ORDER BY LinkedEntity.Type ASC];
            for (ContentDocumentLink objCDL : lstDocumentLink) {
                if ((objCDL.LinkedEntity.type == 'User' && bolIncludeUserRecords == true) || (objCDL.LinkedEntity.type != 'User' && ContentDocument.ContentAssetId != null)) {
                    setTempEligibleDocumentIds.add(objCDL.ContentDocumentId);
                    setEligibleDocumentIds.add(objCDL.ContentDocumentId);
                }
            }
            Boolean bolValid = createCD(setTempEligibleDocumentIds);
            if(!lstExternalFiles.isEmpty() && bolValid && Schema.SobjectType.External_Files__c.isCreateable()){
                
                SObjectAccessDecision objAccessDecision = Security.stripInaccessible(AccessType.CREATABLE, lstExternalFiles);
                List<External_Files__c> lstExternalFilesCreatable = (List<External_Files__c>)objAccessDecision.getRecords();
                if(!lstExternalFilesCreatable.isEmpty() && External_Files__c.SobjectType.getDescribe().isCreateable()){
                    insert lstExternalFilesCreatable;
                }
            }
        }catch (Exception exp) {
            intNumOfErrors++;
            strFailedIds +=  '\'' + lsContDoclink[0].ContentDocumentId + '\', ';
            ErrorLogger.logBatchException(bc.getJobId(), 'MigrateCDLFilesBatch Execution', exp);
        }
    }
    
    global void finish(Database.BatchableContext bc){
        if (setEligibleDocumentIds.size() > 0) {
            Database.executeBatch(new MigrateFileVersionsBatch(setEligibleDocumentIds, bolDeleteUploadedRecords), 1);
        }
        String strFailedRecordIds = '';
        if(strAPIFailedRecordIds != ''){
            strFailedRecordIds += ' Record Ids that failed during the API request:  <br/>' + strAPIFailedRecordIds.removeEnd(', ') + ' <br/>';
        }
        if(strMaxSizeExceededIds != ''){
            strFailedRecordIds += ' Record Ids that exceed the maximum size allowed for upload:  <br/>' + strMaxSizeExceededIds.removeEnd(', ') + ' <br/>';
        }
        if(strFailedIds != ''){
            strFailedRecordIds += '  Record Ids that are captured while throwing an exception:   <br/>' + strFailedIds.removeEnd(', ');
        }
        Set<Id> setRecipientIds = new Set<Id>{ UserInfo.getUserId() };
        if(Schema.SObjectType.Exception_Error__c.isAccessible() && Schema.SObjectType.Exception_Error__c.fields.Related_To__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.StackTraceString__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Exception_Message__c.isCreateable()
        && Schema.SObjectType.Exception_Error__c.fields.BatchJobId__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Record_Id__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Status_Code__c.isCreateable()){
            ErrorLogger.LogBatchErrorsWrapper objLogBatchErrorsWrapper = new ErrorLogger.LogBatchErrorsWrapper();
            objLogBatchErrorsWrapper.apexJobId = bc.getJobId();
            objLogBatchErrorsWrapper.strBatchClassName = 'MigrateCDLFilesBatch';
            objLogBatchErrorsWrapper.setUserIds = setRecipientIds;
            objLogBatchErrorsWrapper.strFailures = strFailedRecordIds;
            objLogBatchErrorsWrapper.intNumOfErrors = intNumOfErrors;
            ErrorLogger.logBatchErrors(objLogBatchErrorsWrapper);
        }
    }
    
    
    private Boolean createCD(Set<Id> setTempEligibleDocumentIds){
        
        Boolean bolReturn = false;
        Map<Id, ContentDocument> mapContentDocById = new Map<Id, ContentDocument>([SELECT Id, FileExtension, Title, ContentSize, CreatedDate, LastModifiedDate FROM ContentDocument WHERE Id =:setContentDocumentIds WITH USER_MODE]);
        
        if (setTempEligibleDocumentIds.size() > 0) {
            for (Id idContentDocument : setTempEligibleDocumentIds) {
                ContentDocument objContentDocument = mapContentDocById.get(idContentDocument);
                String strFileType = (objContentDocument.FileExtension);
                if(External_Files__c.SobjectType.getDescribe().isCreateable() && Schema.SObjectType.External_Files__c.fields.Uploaded_From__c.isCreateable()){
                External_Files__c objEF = new External_Files__c();
                objEF.File_Id__c = objContentDocument.Id;
                objEF.File_Name__c = objContentDocument.Title;
                objEF.File_Type__c = strFileType;
                objEF.Record_Type__c = objContentDocument.FileExtension != null ? objContentDocument.FileExtension.toLowerCase() == 'snote' ? 'Notes' : 'Files' : 'Files';
                objEF.File_Original_Created_Date__c = objContentDocument.CreatedDate;
                objEF.File_Original_LastModified_Date__c = objContentDocument.LastModifiedDate;
                objEF.Uploaded_From__c = 'Salesforce';
                lstExternalFiles.add(objEF);
                }
            }
            bolReturn = true;
        }
        return bolReturn;
    }
    
    private String getFileType(String strFileExtension){
        return strFileExtension != null ? strFileExtension.toLowerCase() == 'snote' ? 'pdf' : strFileExtension.toLowerCase() : 'txt';
    }
    
}