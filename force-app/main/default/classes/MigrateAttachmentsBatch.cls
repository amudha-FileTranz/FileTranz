/*
 * Purpose : To upload attachments to aws s3
 * Author  : Anandhakumar Thangasamy
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class MigrateAttachmentsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    String strWhere = '';
    String strAPIFailedDocumentIds = '';
    String strMaxSizeDocumentIds = '';
    String strFailedIds = '';
    String strNoContentTypeRecordIds = '';
    Boolean bolDeleteUploadedRecords = false;
    Integer intNumOfErrors = 0;
    
    global MigrateAttachmentsBatch(string strWhere, Boolean bolDeleteUploadedRecords) {
        this.strWhere = (strWhere != null && strWhere != '') ? 'WHERE ' + strWhere : '';
        this.bolDeleteUploadedRecords = bolDeleteUploadedRecords;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Name, BodyLength, Body, ParentId, ContentType,CreatedDate, LastModifiedDate,Parent.type FROM Attachment ' + strWhere;
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext bc, List<Attachment> lstAttachment) {
        if(!Schema.sObjectType.Attachment.isAccessible()) {
            return;
        }
        Attachment objAttach = lstAttachment[0];
        try {
            List<Attachment> lstUploadedAttachments = new List<Attachment>();
            List<External_Storage_Settings__c> lstESSettings = [
				SELECT Name, Access_Key__c, Secret_Key__c, Region__c, Bucket__c, File_Retrieve_URL__c, Expiration_Time__c, Maximum_File_Size__c, Success_Codes__c
				FROM External_Storage_Settings__c WITH USER_MODE LIMIT 200
			];
            String strRetrieveEndpointURL = lstESSettings[0].File_Retrieve_URL__c + '/';
            List<String> lstSuccessCodes = lstESSettings[0].Success_Codes__c.split('; ');
            
            if (!Schema.sObjectType.External_Files__c.isCreateable() || !Schema.sObjectType.External_File_Version__c.isCreateable() || !Schema.sObjectType.External_File_Link__c.isCreateable()) {
                return;
            }
            // If the attachment size is less than the allowed size
            if (objAttach.BodyLength < Integer.valueOf(lstESSettings[0].Maximum_File_Size__c)) {
                // Maximum attachment size allowed for migration is 11 MB
                string strAttachmentBody = EncodingUtil.base64Encode(objAttach.Body);
                String strContentType = String.valueOf(objAttach.ContentType) != null ? String.valueOf(objAttach.ContentType).toLowerCase() : '';
                if (strContentType != '') {
                    // To get content type for the respective file type
                    List<AWS_File_Type_Mapping__mdt> lstFileTypeMappings = [SELECT MasterLabel FROM AWS_File_Type_Mapping__mdt WHERE File_Type_Application_Name__c = :strContentType WITH USER_MODE];
                    String strFileType = String.valueOf(objAttach.Name).substringAfterLast('.');
                    strRetrieveEndpointURL += objAttach.ParentId + '/' + PresignedURLGenerator.uriEncode(String.valueOf(objAttach.Name).substringBeforeLast('.'), true) + '_' + objAttach.Id + '_v1.' + strFileType;
                    PresignedURLGenerator.GetSignedURLWrapper objGetSignedURLWrapper = new PresignedURLGenerator.GetSignedURLWrapper();
                    objGetSignedURLWrapper.strMethod = 'PUT';
                    objGetSignedURLWrapper.strAccKy = lstESSettings[0].Access_Key__c;
                    objGetSignedURLWrapper.strStKy = lstESSettings[0].Secret_Key__c;
                    objGetSignedURLWrapper.strBucketName = lstESSettings[0].Bucket__c;
                    objGetSignedURLWrapper.strBucketRegion = lstESSettings[0].Region__c;
                    objGetSignedURLWrapper.strLocation = strRetrieveEndpointURL;
                    objGetSignedURLWrapper.strFile = objAttach.ParentId + '/' + String.valueOf(objAttach.Name).substringBeforeLast('.') + '_' + objAttach.Id + '_v1.' + strFileType;
                    objGetSignedURLWrapper.intExpires = Integer.valueOf(lstESSettings[0].Expiration_Time__c);
                    objGetSignedURLWrapper.strFileName = String.valueOf(objAttach.Name);
                    // To get presigned URL for uploading the attachment
                    String strPreSignedURL = PresignedURLGenerator.getSignedURL(objGetSignedURLWrapper);
                    APIUtility.UploadFileWrapper objUploadFileWrapper = new APIUtility.UploadFileWrapper();
                    objUploadFileWrapper.strFileContent = strAttachmentBody;
                    objUploadFileWrapper.strName = String.valueOf(objAttach.Name).substringBeforeLast('.');
                    objUploadFileWrapper.strType = strContentType;
                    objUploadFileWrapper.strPresignedURL = strPreSignedURL;
                    // To initiate upload process
                    HttpResponse objGetresponse = APIUtility.uploadFile(objUploadFileWrapper);
                    
                    // If API request gets succeeded
                    if (lstSuccessCodes.contains(String.valueOf(objGetresponse.getstatuscode()))) {
                        // Create External_Files__c record
                        External_Files__c objEF = new External_Files__c();
                        objEF.File_Id__c = objAttach.Id;
                        objEF.File_Name__c = objAttach.Name;
                        objEF.File_Type__c = strFileType;
                        objEF.UID__c = objAttach.Id;
                        objEF.Record_Type__c = 'Attachment';
                        objEF.Uploaded_From__c = 'Salesforce';
                        objEF.File_Original_Created_Date__c = objAttach.CreatedDate;
                        objEF.File_Original_LastModified_Date__c = objAttach.LastModifiedDate;
                        
                        List<External_Files__c> lstEFs = new List<External_Files__c>{objEF};
                        SObjectAccessDecision objAccessDecision = Security.stripInaccessible(AccessType.CREATABLE, lstEFs);
                        List<External_Files__c> lstEFsToInsert = (List<External_Files__c>)objAccessDecision.getRecords();
                        if(!lstEFsToInsert.isEmpty() && Schema.sObjectType.External_Files__c.isCreateable()) {
                            insert as User lstEFsToInsert;
                        }
                        // Create External_File_Version__c record
                        if(Schema.sObjectType.External_File_Version__c.isAccessible() && Schema.sObjectType.External_File_Version__c.fields.External_Files__c.isCreateable() && Schema.sObjectType.External_File_Version__c.fields.File_Location_URL__c.isCreateable() && Schema.sObjectType.External_File_Version__c.fields.Is_Latest__c.isCreateable()
                        && Schema.sObjectType.External_File_Version__c.fields.Version_Number__c.isCreateable() && Schema.sObjectType.External_File_Version__c.fields.Size__c.isCreateable() && Schema.sObjectType.External_File_Version__c.fields.Size_Bytes__c.isCreateable()) {
                            External_File_Version__c objEFV = new External_File_Version__c();
                            objEFV.External_Files__c = objEF.Id;
                            objEFV.File_Location_URL__c = strRetrieveEndpointURL;
                            objEFV.Is_Latest__c = true;
                            objEFV.Version_Number__c = 1;
                            objEFV.Size__c = CommonUtilities.FormatFileSize(Decimal.valueOf(objAttach.BodyLength));
                            objEFV.Size_Bytes__c = objAttach.BodyLength;
                            
                            List<External_File_Version__c> lstEFVsToInsert = new List<External_File_Version__c>{objEFV};
                            SObjectAccessDecision objEFVAccessDecision = Security.stripInaccessible(AccessType.CREATABLE, lstEFVsToInsert);
                            List<External_File_Version__c> lstEFVsToInsertSafe = (List<External_File_Version__c>)objEFVAccessDecision.getRecords();
                            if(Schema.sObjectType.External_File_Version__c.isCreateable()) {
                                insert as User lstEFVsToInsertSafe;
                            }
                            
                            // Create External_File_Link__c record
                            External_File_Link__c objEFL = new External_File_Link__c();
                            if(Schema.SObjectType.External_File_Link__c.fields.Related_To__c.isCreateable() && Schema.SObjectType.External_File_Link__c.fields.Object_Type__c.isCreateable()
                            && Schema.SObjectType.External_File_Link__c.fields.External_Files__c.isCreateable()){
                                objEFL.Related_To__c = objAttach.ParentId;
                                objEFL.Object_Type__c = CommonUtilities.getObjectLabelFromId(objAttach.ParentId);
                                objEFL.External_Files__c = objEF.Id;
                            }
                            List<External_File_Link__c> lstEFLs = new List<External_File_Link__c>{objEFL};
                            SObjectAccessDecision objEFLAccessDecision = Security.stripInaccessible(AccessType.CREATABLE, lstEFLs);
                            List<External_File_Link__c> lstEFLsToInsert = (List<External_File_Link__c>)objEFLAccessDecision.getRecords();
                            if(!lstEFLsToInsert.isEmpty() && Schema.sObjectType.External_File_Link__c.isCreateable()) {
                                insert as User lstEFLsToInsert;
                            }
                            //insert as User lstEFLs;
                            
                            // Update External_File_Link__c record
                            objEF.Latest_External_File_Version__c = objEFV.Id;
                            List<External_Files__c> lstEFsToUpdate = new List<External_Files__c>{objEF};
                            SObjectAccessDecision objEFUpdateAccessDecision = Security.stripInaccessible(AccessType.UPDATABLE, lstEFsToUpdate);
                            List<External_Files__c> lstEFsToUpdateSafe = (List<External_Files__c>)objEFUpdateAccessDecision.getRecords();
                            if(!lstEFsToUpdateSafe.isEmpty() && Schema.sObjectType.External_Files__c.isUpdateable()) {
                                update as User lstEFsToUpdateSafe;
                            }
                            // if(Schema.SObjectType.External_Files__c.fields.Latest_External_File_Version__c.isUpdateable()) {
                                //     //return;
                                //     objEF.Latest_External_File_Version__c = objEFV.Id;
                                //     update as User objEF;
                            // }
                            lstUploadedAttachments.add(objAttach);
                        }
                    } else {
                        // If API request gets failed
                        strAPIFailedDocumentIds += '\'' + objAttach.Id + '\', ';
                        intNumOfErrors++;
                    }
                } else {
                    strNoContentTypeRecordIds += '\'' + objAttach.Id + '\', ';
                    intNumOfErrors++;
                }
            } else {
                // If the attachment size is more than allowed size
                strMaxSizeDocumentIds += '\'' + objAttach.Id + '\', ';
                intNumOfErrors++;
            }
            if (lstUploadedAttachments.size() > 0 && bolDeleteUploadedRecords && Schema.sObjectType.Attachment.isDeletable() && Attachment.SObjectType.getDescribe().isDeletable()) {
                delete as User lstUploadedAttachments;
            }
        } catch (Exception exp) {
            intNumOfErrors++;
            strFailedIds += '\'' + objAttach.Id + '\', ';
            ErrorLogger.logBatchException(bc.getJobId(), 'MigrateAttachmentsBatch Execution', exp);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // To log error details and sending the batch details to the user email who ran the batch.
        String strFailedRecordIds = '';
        if (strAPIFailedDocumentIds != '') {
            strFailedRecordIds += 'Record Ids that failed during the API request:  <br/>' + strAPIFailedDocumentIds.removeEnd(', ') + '<br/>';
        }
        if (strMaxSizeDocumentIds != '') {
            strFailedRecordIds += ' Record Ids that exceed the maximum size allowed for upload:  <br/>' + strMaxSizeDocumentIds.removeEnd(', ') + ' <br/>';
        }
        if (strNoContentTypeRecordIds != '') {
            strFailedRecordIds += ' Record Ids that are not has the Content type:  <br/>' + strNoContentTypeRecordIds.removeEnd(', ') + ' <br/>';
        }
        if (strFailedIds != '') {
            strFailedRecordIds += ' Record Ids that are captured while throwing an exception:  <br/>' + strFailedIds.removeEnd(', ');
        }
        Set<Id> setRecipientIds = new Set<Id>{ UserInfo.getUserId() };
        // Catch the Error From ErrorLogger
        if(!Schema.sObjectType.Exception_Error__c.isCreateable()) {
            return;
        }
        if(Schema.SObjectType.Exception_Error__c.isAccessible() && Schema.SObjectType.Exception_Error__c.fields.Related_To__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.StackTraceString__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Exception_Message__c.isCreateable()
        && Schema.SObjectType.Exception_Error__c.fields.BatchJobId__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Record_Id__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Status_Code__c.isCreateable()){
            ErrorLogger.LogBatchErrorsWrapper objLogBatchErrorsWrapper = new ErrorLogger.LogBatchErrorsWrapper();
            objLogBatchErrorsWrapper.apexJobId = bc.getJobId();
            objLogBatchErrorsWrapper.strBatchClassName = 'MigrateAttachmentsBatch';
            objLogBatchErrorsWrapper.setUserIds = setRecipientIds;
            objLogBatchErrorsWrapper.strFailures = strFailedRecordIds;
            objLogBatchErrorsWrapper.intNumOfErrors = intNumOfErrors;
            if(!Schema.SObjectType.Exception_Error__c.isCreateable() || !Schema.SObjectType.Exception_Error__c.fields.Related_To__c.isCreateable()){
                return;
            }
            ErrorLogger.logBatchErrors(objLogBatchErrorsWrapper);
        }
    }
}