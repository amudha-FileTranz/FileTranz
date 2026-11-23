/*
 * Purpose : To upload file versions to aws s3
 * Author  : Anandhakumar Thangasamy
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class MigrateFileVersionsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    Set<Id> setContentDocumentId = new Set<Id>();
    Integer intNumOfErrors = 0;
    String strAPIFailedRecordIds = '';
    String strFailedIds = '';
    Boolean bolDeleteUploadedRecords;
    
    global MigrateFileVersionsBatch(Set<Id> setContentDocumentId, Boolean bolDeleteUploadedRecords) {
        this.setContentDocumentId = setContentDocumentId;
        this.bolDeleteUploadedRecords = bolDeleteUploadedRecords;
    }
    
    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        String strQuery = 'SELECT Id, VersionData, VersionNumber, ContentDocumentId, FileExtension, IsLatest, Title, CreatedDate, LastModifiedDate, ContentSize FROM ContentVersion WHERE ContentDocumentId IN :setContentDocumentId AND FileExtension != \'snote\' WITH USER_MODE';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext bc, List<ContentVersion> lstVersions) {
        String strRetrieveEndpointURL = '';
        String strFileType = '';
        List<String> lisSuccessCodes = new List<String>();
        External_Files__c objEF = new External_Files__c();
        CreateEFLWrapper objCreateEFLWrapper = new CreateEFLWrapper();
        objCreateEFLWrapper.objVersion = lstVersions[0];
        try {
            if(setContentDocumentId.contains(objCreateEFLWrapper.objVersion.ContentDocumentId)) {
                CommonUtilities.ExternalStorageSettingWrapper objESSettings = CommonUtilities.getActiveStorageSetting();
                lisSuccessCodes = objESSettings.strSuccessCodes.split('; ');
                HttpResponse response = new HttpResponse();
                objCreateEFLWrapper.lstDocumentLink = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :objCreateEFLWrapper.objVersion.ContentDocumentId WITH USER_MODE ORDER BY LinkedEntity.Type ASC];
                strRetrieveEndpointURL = objESSettings.strEndPoint + '/';
                String strLinkedEntityId = objCreateEFLWrapper.lstDocumentLink[0].LinkedEntityId;
                if (strLinkedEntityId != null) {
                    strRetrieveEndpointURL += strLinkedEntityId + '/' + PresignedURLGenerator.uriEncode(objCreateEFLWrapper.objVersion.Title, true) + '_' + objCreateEFLWrapper.objVersion.ContentDocumentId + '_v' + objCreateEFLWrapper.objVersion.VersionNumber;
                }
                strFileType = objCreateEFLWrapper.objVersion.FileExtension != null ? objCreateEFLWrapper.objVersion.FileExtension.toLowerCase() == 'snote' ? 'pdf' : objCreateEFLWrapper.objVersion.FileExtension.toLowerCase() : 'txt';
                PresignedURLGenerator.GetSignedURLWrapper objGetSignedURLWrapper = new PresignedURLGenerator.GetSignedURLWrapper();
                objGetSignedURLWrapper.strMethod = 'PUT';
                objGetSignedURLWrapper.strAccKy = objESSettings.strAccKy;
                objGetSignedURLWrapper.strStKy = objESSettings.strStKy;
                objGetSignedURLWrapper.strBucketName = objESSettings.strBucket;
                objGetSignedURLWrapper.strBucketRegion = objESSettings.strRegion;
                objGetSignedURLWrapper.strLocation = strRetrieveEndpointURL + '.' + strFileType;
                objGetSignedURLWrapper.strFile = strLinkedEntityId + '/' + objCreateEFLWrapper.objVersion.Title + '_' + objCreateEFLWrapper.objVersion.ContentDocumentId + '_v' + objCreateEFLWrapper.objVersion.VersionNumber + '.' + strFileType;
                objGetSignedURLWrapper.intExpires = Integer.valueOf(objESSettings.intExpirationTime);
                objGetSignedURLWrapper.strFileName = null;
                
                String strPreSignedURL = PresignedURLGenerator.getSignedURL(objGetSignedURLWrapper);
                String strBody = EncodingUtil.base64Encode(objCreateEFLWrapper.objVersion.VersionData);
                APIUtility.UploadFileWrapper objUploadFileWrapper = new APIUtility.UploadFileWrapper();
                objUploadFileWrapper.strFileContent = strBody;
                objUploadFileWrapper.strName = String.valueOf(objCreateEFLWrapper.objVersion.Title);
                objUploadFileWrapper.strType = String.valueOf(objCreateEFLWrapper.objVersion.FileExtension);
                objUploadFileWrapper.strPresignedURL = strPreSignedURL;
                
                response = APIUtility.uploadFile(objUploadFileWrapper);
                objEF = [SELECT Id,File_Id__c FROM External_Files__c WHERE File_Id__c =: objCreateEFLWrapper.objVersion.ContentDocumentId WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 1];
                objCreateEFLWrapper.response = response;
                objCreateEFLWrapper.setSuccessCodes = lisSuccessCodes;
                objCreateEFLWrapper.objEF = objEF;
                objCreateEFLWrapper.strEndPoint = objESSettings.strEndPoint;
                
                createEFL(objCreateEFLWrapper, strLinkedEntityId, strFileType);
            }
        } catch (Exception exp) {
            intNumOfErrors++;
            strFailedIds += '\'' + objCreateEFLWrapper.objVersion.ContentDocumentId + '\', ';
            ErrorLogger.logBatchException(bc.getJobId(), 'MigrateFilesBatch Execution', exp);
        }
    }
    global void finish(Database.BatchableContext bc) {
        if (setContentDocumentId.size() > 0 && bolDeleteUploadedRecords) {
            Database.executeBatch(new DeleteContentDocumentsBatch(setContentDocumentId), 2000);
        }
        String strFailedRecordIds = '';
        if (strAPIFailedRecordIds != '') {
            strFailedRecordIds += ' Record Ids that failed during the API request:  <br/>' + strAPIFailedRecordIds.removeEnd(', ') + ' <br/>';
        }
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
    
    private void createEFL(CreateEFLWrapper objCreateEFLWrapper, String strLinkedEntityId, String strFileType){
        if (objCreateEFLWrapper.setSuccessCodes.contains(String.valueOf(objCreateEFLWrapper.response.getstatuscode()))) {
            External_File_Version__c objEFV = new External_File_Version__c();
            objEFV.External_Files__c = objCreateEFLWrapper.objEF.Id;
            objEFV.File_Location_URL__c = objCreateEFLWrapper.strEndPoint + '/' + strLinkedEntityId +  + '/' + objCreateEFLWrapper.objVersion.Title + '_' + objCreateEFLWrapper.objVersion.ContentDocumentId + '_v' + objCreateEFLWrapper.objVersion.VersionNumber + '.' + strFileType;
            objEFV.Is_Latest__c = objCreateEFLWrapper.objVersion.IsLatest;
            objEFV.Version_Number__c = Integer.valueOf(objCreateEFLWrapper.objVersion.VersionNumber);
            objEFV.Size__c = CommonUtilities.FormatFileSize(Decimal.valueOf(objCreateEFLWrapper.objVersion.ContentSize));
            objEFV.Size_Bytes__c = objCreateEFLWrapper.objVersion.ContentSize;
            if(Schema.SobjectType.External_File_Version__c.isCreateable()){
                insert objEFV;
            }
            if(objCreateEFLWrapper.objVersion.IsLatest) {
                List<External_File_Link__c> lstExternalFileLinks = new List<External_File_Link__c>();
                for (ContentDocumentLink objCDL : objCreateEFLWrapper.lstDocumentLink) {
                    String strObjectLabel = CommonUtilities.getObjectLabelFromId(objCDL.LinkedEntityId);
                    External_File_Link__c objExternalFileLink = new External_File_Link__c();
                    objExternalFileLink.External_Files__c = objCreateEFLWrapper.objEF.id;
                    objExternalFileLink.Related_To__c = objCDL.LinkedEntityId;
                    objExternalFileLink.Object_Type__c = strObjectLabel;
                    lstExternalFileLinks.add(objExternalFileLink);
                }
                dmlActions(lstExternalFileLinks);
                objCreateEFLWrapper.objEF.Latest_External_File_Version__c = objEFV.Id;
                if(!Schema.SobjectType.ContentVersion.isAccessible() && !Schema.SobjectType.ContentVersion.fields.Is_Migrated__c.isAccessible() && !Schema.SobjectType.ContentVersion.fields.Id.isAccessible()){
                    return;
                }
                ContentVersion objCV = [SELECT Id, Is_Migrated__c,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId =: objCreateEFLWrapper.objEF.File_Id__c WITH USER_MODE];
                ContentVersion objCVUP = new ContentVersion();
                objCVUP.Id = objCV.Id;
                objCVUP.Is_Migrated__c = true;
                if(Schema.SobjectType.External_Files__c.isupdateable() && Schema.SobjectType.ContentVersion.isupdateable()){
                    update (External_Files__c)objCreateEFLWrapper.objEF;
                    update objCVUP;
                }
            }
        } else {
            strAPIFailedRecordIds +=  '\'' + objCreateEFLWrapper.objVersion.ContentDocumentId + '\', ';
            setContentDocumentId.remove(objCreateEFLWrapper.objVersion.ContentDocumentId);
            
            if(Schema.SobjectType.External_Files__c.isdeletable()){
                delete (External_Files__c)objCreateEFLWrapper.objEF;
            }
        }
    }
    
    private void dmlActions(List<External_File_Link__c> lstExternalFileLinks){
        if(!lstExternalFileLinks.isEmpty() && Schema.SobjectType.External_File_Link__c.isCreateable()){
            insert lstExternalFileLinks;
        }
        
    }
    
    global class CreateEFLWrapper {
        @AuraEnabled
        global HttpResponse response { get; set; }
        @AuraEnabled
        global List<String> setSuccessCodes { get; set; }
        @AuraEnabled
        global External_Files__c objEF { get; set; }
        @AuraEnabled
        global ContentVersion objVersion { get; set; }
        @AuraEnabled
        global List<ContentDocumentLink> lstDocumentLink { get; set; }
        @AuraEnabled
        global String strEndPoint { get; set;}
    }
}