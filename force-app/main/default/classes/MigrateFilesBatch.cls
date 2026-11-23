/*
 * Purpose : To upload content documents from the salesforce to aws S3 server.
 * Author  : Anandhakumar Thangasamy
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class MigrateFilesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    String strWhere = '';
    String strFailedIds = '';
    Boolean bolIncludeUserRecords = false;
    Boolean bolDeleteUploadedRecords = false;
    Map<String, String> mapOfileTypes = new Map<String, String>();
    Integer intNumOfErrors = 0;
    Set<Id> setEligibleDocumentIds = new Set<Id>();
    List<External_Files__c> lstExternalFiles = new List<External_Files__c>();
    Map<Id, ContentDocument> mapContentDocById = new Map<Id, ContentDocument>();
    
    
    global MigrateFilesBatch(String strWhere, Boolean bolIncludeUserRecords, Boolean bolDeleteUploadedRecords) {
        
        CommonUtilities.ExternalStorageSettingWrapper objESSettings = CommonUtilities.getActiveStorageSetting();
        Integer strMaximumFileSize = Integer.valueOf(objESSettings.strMaximumFileSize);
        this.strWhere = (strWhere != '' && strWhere != null) ? (strWhere + ' AND') : ' WHERE ';
        this.strWhere = this.strWhere + ' LatestPublishedVersion.contentsize <' + strMaximumFileSize + ' AND LatestPublishedVersion.Is_Migrated__c = false';
        this.bolIncludeUserRecords = bolIncludeUserRecords;
        this.bolDeleteUploadedRecords = bolDeleteUploadedRecords;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        for (AWS_File_Type_Mapping__mdt objMdtIterator : [SELECT DeveloperName, File_Type_Application_Name__c FROM AWS_File_Type_Mapping__mdt WHERE File_Type_Application_Name__c != NULL WITH USER_MODE]) {
            mapOfileTypes.put(objMdtIterator.DeveloperName, objMdtIterator.File_Type_Application_Name__c);
        }
        String strQuery = 'SELECT Id, FileExtension, Title, ContentSize, CreatedDate, LastModifiedDate FROM ContentDocument ' + strWhere;
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext bc, List<ContentDocument> lstContDocuments) {
        try {
            Set<Id> setTempEligibleDocumentIds = new Set<Id>();
            Set<Id> setContentDocumentIds = new Set<Id>();
            for (ContentDocument objDocument : lstContDocuments) {
                setContentDocumentIds.add(objDocument.Id);
                mapContentDocById.put(objDocument.Id, objDocument);
            }
            List<ContentDocumentLink> lstDocumentLink = [
				SELECT
					Id,
					LinkedEntityId,
					LinkedEntity.Type,
					ContentDocumentId,
					ContentDocument.LatestPublishedVersion.FileExtension,
					ContentDocument.LatestPublishedVersion.Title,
					ContentDocument.ContentAssetId
				FROM ContentDocumentLink
				WHERE ContentDocumentId IN :setContentDocumentIds WITH USER_MODE
				ORDER BY LinkedEntity.Type ASC
			];
            for (ContentDocumentLink objCDL : lstDocumentLink) {
                if ((objCDL.LinkedEntity.type == 'User' && bolIncludeUserRecords == true) || (objCDL.LinkedEntity.type != 'User' && ContentDocument.ContentAssetId != null)) {
                    setTempEligibleDocumentIds.add(objCDL.ContentDocumentId);
                    setEligibleDocumentIds.add(objCDL.ContentDocumentId);
                }
            }
            
            Boolean bolValid = createCDL(setTempEligibleDocumentIds);
            
            if(!lstExternalFiles.isEmpty() && External_Files__c.SobjectType.getDescribe().isCreateable()){
                
                SObjectAccessDecision objAccessDecision = Security.stripInaccessible(AccessType.CREATABLE, lstExternalFiles);
                List<External_Files__c> lstExternalFilesCreatable = (List<External_Files__c>)objAccessDecision.getRecords();
                if(!lstExternalFilesCreatable.isEmpty() && Schema.SObjectType.External_Files__c.isCreateable()){
                    insert lstExternalFilesCreatable;
                }
            }
        } catch (Exception exp) {
            intNumOfErrors++;
            strFailedIds += '\'' + lstContDocuments[0].Id + '\', ';
            ErrorLogger.logBatchException(bc.getJobId(), 'MigrateFilesBatch Execution', exp);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        if (setEligibleDocumentIds.size() > 0) {
            Database.executeBatch(new MigrateFileVersionsBatch(setEligibleDocumentIds, bolDeleteUploadedRecords), 1);
        }
        String strFailedRecordIds = '';
        if (strFailedIds != '') {
            strFailedRecordIds += '  Record Ids that are captured while throwing an exception:   <br/>' + strFailedIds.removeEnd(', ');
        }
        Set<Id> setRecipientIds = new Set<Id>{ UserInfo.getUserId() };
        if(Schema.SObjectType.Exception_Error__c.isAccessible() && Schema.SObjectType.Exception_Error__c.fields.Related_To__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.StackTraceString__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Exception_Message__c.isCreateable()
        && Schema.SObjectType.Exception_Error__c.fields.BatchJobId__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Record_Id__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Status_Code__c.isCreateable()){
            ErrorLogger.LogBatchErrorsWrapper objLogBatchErrorsWrapper = new ErrorLogger.LogBatchErrorsWrapper();
            objLogBatchErrorsWrapper.apexJobId = bc.getJobId();
            objLogBatchErrorsWrapper.strBatchClassName = 'MigrateFilesBatch';
            objLogBatchErrorsWrapper.setUserIds = setRecipientIds;
            objLogBatchErrorsWrapper.strFailures = strFailedRecordIds;
            objLogBatchErrorsWrapper.intNumOfErrors = intNumOfErrors;
            ErrorLogger.logBatchErrors(objLogBatchErrorsWrapper);
        }
    }
    
    private Boolean createCDL(Set<Id> setTempEligibleDocumentIds){
        Boolean bolReturn = false;
        if (setTempEligibleDocumentIds.size() > 0) {
            for (Id idContentDocument : setTempEligibleDocumentIds) {
                if(Schema.SObjectType.ContentDocument.isAccessible() && Schema.SObjectType.External_Files__c.fields.File_Original_Created_Date__c.isCreateable() && Schema.SObjectType.External_Files__c.fields.File_Original_LastModified_Date__c.isCreateable() && Schema.SObjectType.External_Files__c.fields.Uploaded_From__c.isCreateable() && Schema.SObjectType.External_Files__c.isCreateable()
                && Schema.SObjectType.External_Files__c.fields.File_Id__c.isCreateable() && Schema.SObjectType.External_Files__c.fields.File_Name__c.isCreateable() && Schema.SObjectType.External_Files__c.fields.Record_Type__c.isCreateable() && Schema.SObjectType.External_Files__c.fields.File_Type__c.isCreateable()){
                    ContentDocument objContentDocument = mapContentDocById.get(idContentDocument);
                    String strFileType = getFileType(objContentDocument.FileExtension);
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