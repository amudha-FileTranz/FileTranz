/*
 * Purpose : To controll the view screen actions
 * Author  : Anandhakumar Thangasamy
 */
public with sharing class ViewFilesController {
    /**
     * To retrieve files from external files object.
     * @param strRecordId from uploadViewFiles LWC
     * @return List<CommonUtilities.ExternalFilesWrapper>
     */
    @AuraEnabled
    public static List<CommonUtilities.ExternalFilesWrapper> retrieveExternalFiles(String strRecordId) {
        List<CommonUtilities.ExternalFilesWrapper> lstEFWrapper = new List<CommonUtilities.ExternalFilesWrapper>();
        try {
            List<External_File_Link__c> lstEFL = [
				SELECT
					Id,
					Name,
					External_Files__c,
					External_Files__r.File_Name__c,
					External_Files__r.Latest_Version_Size__c,
					External_Files__r.Latest_External_File_Version__r.File_Location_URL__c,
					Object_Type__c,
					Related_To__c,
					External_Files__r.File_Type__c,
					External_Files__r.UID__c,
					External_Files__r.LastModifiedDate
				FROM External_File_Link__c
				WHERE Is_Deleted__c = FALSE AND Related_To__c = :String.escapeSingleQuotes(strRecordId) WITH USER_MODE
				ORDER BY LastModifiedDate DESC
			];
            Integer intSno = 0;
            for (External_File_Link__c objEFL : lstEFL) {
                CommonUtilities.ExternalFilesWrapper objEFWrapper = new CommonUtilities.ExternalFilesWrapper();
                objEFWrapper.strName = objEFL.Name;
                objEFWrapper.strId = objEFL.id;
                objEFWrapper.strFileName = objEFL.External_Files__r.File_Name__c.substringBeforeLast('.');
                objEFWrapper.strSize = objEFL.External_Files__r.Latest_Version_Size__c;
                objEFWrapper.strFileURL = objEFL.External_Files__r.Latest_External_File_Version__r.File_Location_URL__c;
                objEFWrapper.strObjectType = objEFL.Object_Type__c;
                objEFWrapper.lastModifiedDate = String.valueOf(objEFL.External_Files__r.LastModifiedDate);
                objEFWrapper.strRelatedTo = objEFL.Related_To__c;
                objEFWrapper.strFileType = objEFL.External_Files__r.File_Type__c;
                objEFWrapper.bolShowEdit = false;
                objEFWrapper.bolSelected = false;
                objEFWrapper.strUID = objEFL.External_Files__r.UID__c;
                objEFWrapper.sNo = ++intSno;
                objEFWrapper.dblSize = CommonUtilities.getFileSizeInKB(objEFL.External_Files__r.Latest_Version_Size__c);
                objEFWrapper.strExternalFileId = objEFL.External_Files__c;
                lstEFWrapper.add(objEFWrapper);
            }
        } catch (Exception exp) {
            ErrorLogger.logException('ViewFilesController.retrieveExternalFiles', exp);
        }
        return lstEFWrapper;
    }
    /**
     * To Update File Name.
     * @param lstEFWrapper from uploadViewFiles LWC
     * @return Boolean
     */
    @AuraEnabled
    public static Boolean updateFileNames(List<CommonUtilities.ExternalFilesWrapper> lstEFWrapper) {
        Map<String, String> mapNames = new Map<String, String>();
        List<External_Files__c> lstEFToUpdate = new List<External_Files__c>();
        List<External_File_Version__c> lstEFVToUpdate = new List<External_File_Version__c>();
        String strActivities = CommonUtilities.getConfiguration(new List<String>{ 'File Configuration' }).get('Log_Activity');
        User objUser = CommonUtilities.getCurrentUserDetails();
        String strRelatedToId = lstEFWrapper[0].strRelatedTo;
        List<Log_Activity__c> lstLogActivity = new List<Log_Activity__c>();
        Boolean bolSuccess = false;
        try {
            CommonUtilities.ExternalStorageSettingWrapper objExternalStorageSettingWrapper = CommonUtilities.getActiveStorageSetting();
            List<String> lstSuccessCodes = objExternalStorageSettingWrapper.strSuccessCodes.split('; ');
            String strEndpoint = objExternalStorageSettingWrapper.strEndPoint;
            for (CommonUtilities.ExternalFilesWrapper objExternalFilesWrapper : lstEFWrapper) {
                mapNames.put(objExternalFilesWrapper.strExternalFileId, objExternalFilesWrapper.strFileName + '.'+ objExternalFilesWrapper.strFileType);
            }
            List<External_Files__c> lstExternalFiles = [SELECT Id, File_Name__c, Name, Latest_External_File_Version__r.File_Location_URL__c FROM External_Files__c WHERE Id IN :mapNames.keySet() WITH USER_MODE];
            List<External_File_Version__c> lstVersions = [SELECT Id, File_Location_URL__c, External_Files__c FROM External_File_Version__c WHERE External_Files__c IN :mapNames.keySet() WITH USER_MODE];
            Map<Id, External_File_Version__c> mapExtFileWithLatestVersion = new Map<Id, External_File_Version__c>();
            for (External_File_Version__c objExternalFileVersion : lstVersions) {
                mapExtFileWithLatestVersion.put(objExternalFileVersion.External_Files__c, objExternalFileVersion);
            }
            for (External_Files__c objExternalFile : lstExternalFiles) {
                String strUpdatedFileName = mapNames.get(objExternalFile.Id);
                String strOldFileWithFolder = objExternalFile.Latest_External_File_Version__r.File_Location_URL__c.substringAfter(strEndpoint + '/');
                String strFolder = strOldFileWithFolder.substring(0, 18);
                PresignedURLGenerator.GetSignedURLForCopyFileWrapper objGetSignedURLForCopyFileWrapper = new PresignedURLGenerator.GetSignedURLForCopyFileWrapper();
                objGetSignedURLForCopyFileWrapper.strMethod = 'PUT';
                objGetSignedURLForCopyFileWrapper.strAccKy = objExternalStorageSettingWrapper.strAccKy;
                objGetSignedURLForCopyFileWrapper.strStKy = objExternalStorageSettingWrapper.strStKy;
                objGetSignedURLForCopyFileWrapper.strBucketName = objExternalStorageSettingWrapper.strBucket;
                objGetSignedURLForCopyFileWrapper.strBucketRegion = objExternalStorageSettingWrapper.strRegion;
                objGetSignedURLForCopyFileWrapper.strLocation = objExternalStorageSettingWrapper.strEndPoint + '/' + strFolder + '/' + PresignedURLGenerator.uriEncode(strUpdatedFileName, true);
                objGetSignedURLForCopyFileWrapper.strFile = strFolder + '/' + strUpdatedFileName;
                objGetSignedURLForCopyFileWrapper.intExpires = Integer.valueOf(objExternalStorageSettingWrapper.intExpirationTime);
                objGetSignedURLForCopyFileWrapper.strCopySource = objExternalStorageSettingWrapper.strBucket + '/' + strOldFileWithFolder;
                String strSignedURL = PresignedURLGenerator.getSignedURLForCopyFile(objGetSignedURLForCopyFileWrapper);
                HttpResponse copyCallResponse = APIUtility.copyFile(strSignedURL, objExternalStorageSettingWrapper.strBucket + '/' + strOldFileWithFolder);
                if (lstSuccessCodes.contains(String.valueof(copyCallResponse.getStatusCode()))) {
                    External_File_Version__c objEFV = mapExtFileWithLatestVersion.get(objExternalFile.Id);
                    PresignedURLGenerator.GetSignedURLWrapper objGetSignedURLWrapper = new PresignedURLGenerator.GetSignedURLWrapper();
                    objGetSignedURLWrapper.strMethod = 'DELETE';
                    objGetSignedURLWrapper.strAccKy = objExternalStorageSettingWrapper.strAccKy;
                    objGetSignedURLWrapper.strStKy = objExternalStorageSettingWrapper.strStKy;
                    objGetSignedURLWrapper.strBucketName = objExternalStorageSettingWrapper.strBucket;
                    objGetSignedURLWrapper.strBucketRegion = objExternalStorageSettingWrapper.strRegion;
                    objGetSignedURLWrapper.strLocation = objExternalStorageSettingWrapper.strEndPoint + '/' + PresignedURLGenerator.uriEncode(strOldFileWithFolder, true);
                    objGetSignedURLWrapper.strFile = objEFV.File_Location_URL__c.substringAfter(objExternalStorageSettingWrapper.strEndPoint + '/');
                    objGetSignedURLWrapper.intExpires = Integer.valueOf(objExternalStorageSettingWrapper.intExpirationTime);
                    objGetSignedURLWrapper.strFileName = '';
                    String strPreSignedURL = PresignedURLGenerator.getSignedURL(objGetSignedURLWrapper);
                    HttpResponse deleteCallResponse = APIUtility.deleteFileFromExternalStorage(strPreSignedURL, 'DELETE');
                    if (lstSuccessCodes.contains(String.valueof(deleteCallResponse.getStatusCode()))) {
                        objExternalFile.File_Name__c = mapNames.get(objExternalFile.Id);
                        lstEFToUpdate.add(objExternalFile);
                        objEFV.File_Location_URL__c = objExternalStorageSettingWrapper.strEndPoint + '/' + strFolder + '/' + strUpdatedFileName;
                        lstEFVToUpdate.add(objEFV);
                        if (strActivities != null && strActivities.contains('Edit')) {
                            Log_Activity__c objLogActivity = new Log_Activity__c();
                            objLogActivity.File_Name__c = objExternalFile.File_Name__c;
                            objLogActivity.External_File_Id__c = objExternalFile.Id;
                            objLogActivity.Activity_Type__c = 'Edit';
                            objLogActivity.Activity_Performed_By__c = objUser.Id;
                            objLogActivity.Activity_Field__c = 'File_Name__c';
                            objLogActivity.Activity_Value__c = objExternalFile.File_Name__c;
                            objLogActivity.Record_Id__c = strRelatedToId;
                            lstLogActivity.add(objLogActivity);
                        }
                        bolSuccess = true;
                    }
                    bolSuccess = true;
                }
            }
            updateFileNamesDML(lstEFToUpdate, lstEFVToUpdate, lstLogActivity);
            return bolSuccess;
        } catch (Exception exp) {
            ErrorLogger.logException('ViewFilesController.updateFileNames', exp);
            return false;
        }
    }
    
    /**
     * To get a presigned URL to make an API callout (preview/download/delete).
     * @param strKy the External_File_Link__c Id of the file being acted on. The server looks up
     * that record, verifies the running user actually has access to the record it's related to
     * (Related_To__c is a plain text field, not a real Salesforce lookup, so this check can't be
     * enforced by sharing rules alone - it has to be done explicitly here), and derives the S3 key
     * itself from the file's stored location. A raw, client-supplied S3 key is never trusted directly,
     * otherwise any authenticated user could get a signed GET/DELETE URL for any object in the bucket.
     * @param strReqMethod from uploadViewFiles LWC
     * @return String
     */
    @AuraEnabled
    public static String getPresignedURL(string strKy, string strReqMethod) {
        try {
            List<External_File_Link__c> lstEFL = [
                SELECT Id, Related_To__c, External_Files__r.Latest_External_File_Version__r.File_Location_URL__c
                FROM External_File_Link__c
                WHERE Id = :strKy
                WITH USER_MODE
                LIMIT 1
            ];
            if (lstEFL.isEmpty() || !CommonUtilities.hasAccessToParentRecord(lstEFL[0].Related_To__c)) {
                throw new AuraHandledException('You do not have access to this file.');
            }
            String strFileLocationURL = lstEFL[0].External_Files__r?.Latest_External_File_Version__r?.File_Location_URL__c;
            if (String.isBlank(strFileLocationURL)) {
                throw new AuraHandledException('File location could not be resolved.');
            }

            CommonUtilities.ExternalStorageSettingWrapper objExternalStorageSettingWrapper = CommonUtilities.getActiveStorageSetting();
            String strFileKey = strFileLocationURL.substringAfter(objExternalStorageSettingWrapper.strEndPoint + '/');

            PresignedURLGenerator.GetSignedURLWrapper objGetSignedURLWrapper = new PresignedURLGenerator.GetSignedURLWrapper();
            objGetSignedURLWrapper.strMethod = strReqMethod;
            objGetSignedURLWrapper.strAccKy = objExternalStorageSettingWrapper.strAccKy;
            objGetSignedURLWrapper.strStKy = objExternalStorageSettingWrapper.strStKy;
            objGetSignedURLWrapper.strBucketName = objExternalStorageSettingWrapper.strBucket;
            objGetSignedURLWrapper.strBucketRegion = objExternalStorageSettingWrapper.strRegion;
            objGetSignedURLWrapper.strLocation = objExternalStorageSettingWrapper.strEndPoint + '/' + PresignedURLGenerator.uriEncode(strFileKey, true);
            objGetSignedURLWrapper.strFile = strFileKey;
            objGetSignedURLWrapper.intExpires = Integer.valueOf(objExternalStorageSettingWrapper.intExpirationTime);
            objGetSignedURLWrapper.strFileName = '';

            return PresignedURLGenerator.getSignedURL(objGetSignedURLWrapper);
        } catch (AuraHandledException exp) {
            throw exp;
        } catch (Exception exp) {
            // Covers malformed strKy (not a valid Id) and any other unexpected lookup failure -
            // always fail closed with the same generic message, never leak internal error detail.
            ErrorLogger.logException('ViewFilesController.getPresignedURL', exp);
            throw new AuraHandledException('You do not have access to this file.');
        }
    }

    /**
     * To get file from amazon s3
     * @param strpresigned,strEFId,strRelatedTo from uploadViewFiles LWC
     * @return String
     */
    @AuraEnabled
    public static String getFileFromAmazonS3(String strpresigned, String strEFId, String strRelatedTo) {
        String strContent = '';
        try {
            HttpResponse response = APIUtility.externalStorageCallout(strpresigned, 'GET');
            if (response.getstatuscode() == 200) {
                strContent = EncodingUtil.base64Encode(response.getBodyAsBlob());
                // To log activities
                String strActivities = CommonUtilities.getConfiguration(new List<String>{ 'File Configuration' }).get('Log_Activity');
                
                User objUser = CommonUtilities.getCurrentUserDetails();
                if (strActivities != null && strActivities.contains('Download')) {
                    List<External_File_Link__c> lstEFL = [SELECT Id, External_Files__c, External_Files__r.File_Name__c FROM External_File_Link__c WHERE Id = :strEFId WITH USER_MODE];
                    if (lstEFL != null && lstEFL.size()>0 && Schema.sObjectType.Log_Activity__c.isCreateable()) {
                        Log_Activity__c objLogActivity = new Log_Activity__c();
                        objLogActivity.File_Name__c = lstEFL[0].External_Files__r.File_Name__c;
                        objLogActivity.External_File_Id__c = lstEFL[0].External_Files__c;
                        objLogActivity.Activity_Type__c = 'Download';
                        objLogActivity.Activity_Performed_By__c = objUser.Id;
                        objLogActivity.Record_Id__c = strRelatedTo;
                        
                        try {
                            if(!Schema.sObjectType.Log_Activity__c.isCreateable()){
                                throw new AuraHandledException('You do not have permission to create Log Activity records.');
                            }
                            insert as User objLogActivity;
                        } catch (DmlException e) {
                            throw new AuraHandledException('Unable to insert log activity: ' + e.getMessage());
                            
                        }
                    } else {
                        // Throw an error if the user does not have create permission
                        throw new AuraHandledException('You do not have permission to create Log Activity records.');
                    }
                    
                }
            }
        } catch (Exception exp) {
            ErrorLogger.logException('ViewFilesController.getFileFromAmazonS3', exp);
        }
        return strContent;
    }
    
    private static void updateFileNamesDML(List<External_Files__c> lstEFToUpdate, List<External_File_Version__c> lstEFVToUpdate, List<Log_Activity__c> lstLogActivity){
            if (lstEFToUpdate.size() > 0 && External_Files__c.SObjectType.getDescribe().isUpdateable()) {
                update lstEFToUpdate;
            }else{
            throw new AuraHandledException('You do not have permission to create External_Files__c records.');
        }
        if(External_File_Version__c.SobjectType.getDescribe().isupdateable()){
            if (lstEFVToUpdate.size() > 0) {
                update lstEFVToUpdate;
            }
        }else{
            throw new AuraHandledException('You do not have permission to create External_File_Version__c records.');
        }
        if(Log_Activity__c.sObjectType.getDescribe().isCreateable()){
            if (lstLogActivity.size() > 0 ) {
                insert lstLogActivity;
            }
        }else{
            throw new AuraHandledException('You do not have permission to create Log Activity records.');
        }
    }
}