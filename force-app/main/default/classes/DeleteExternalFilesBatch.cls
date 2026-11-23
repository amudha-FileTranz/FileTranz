/*
 * Purpose : This batch class is used to delete external files and its versions from both salesforce and AWS.
 * Author  : Anandhakumar Thangasamy
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class DeleteExternalFilesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    String strWhere = '';
    String strAPIFailedRecordIds = '';
    String strExpRecordIds = '';
    Integer intNumOfErrors = 0;
    Set<Id> setEFIdsToReprocess = new Set<Id>();
    Set<String> setExternalFileIds = new Set<String>();
    global DeleteExternalFilesBatch(string strWhere) {
        this.strWhere = strWhere != null ? strWhere : '30';
    }
    global DeleteExternalFilesBatch(string strWhere, Set<Id> setEFIdsToReprocess) {
        this.strWhere = strWhere != null ? strWhere : '30';
        this.setEFIdsToReprocess = setEFIdsToReprocess;
        this.strWhere = this.strWhere + ' AND Id IN :setEFIdsToReprocess';
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, (SELECT Id, File_Location_URL__c FROM External_File_Versions__r) FROM External_Files__c WHERE Is_Deleted__c = true AND LastModifiedDate >= LAST_N_DAYS:' + strWhere;
        return Database.getQueryLocator(strQuery);
    }
    global void execute(Database.BatchableContext bc, List<External_Files__c> lstExternalFiles) {

        if(!Schema.SObjectType.External_Files__c.isAccessible() && !Schema.SObjectType.External_File_Version__c.isAccessible()){
            return;
        }

        External_Files__c objExternalFile = lstExternalFiles[0];
        List<External_File_Version__c> lstEFV = objExternalFile.External_File_Versions__r;
        List<External_File_Version__c> lstEFVtoDelete = new List<External_File_Version__c>();
        Integer intIteratorLimit;
        Boolean bolCalloutFailed = false;
        try {

            if (!Schema.sObjectType.External_Storage_Settings__c.isAccessible()) {
                return;
            }
            List<External_Storage_Settings__c> lstESSettings = [
				SELECT Name, Access_Key__c, Secret_Key__c, Region__c, Bucket__c, File_Retrieve_URL__c, Expiration_Time__c, Maximum_File_Size__c, Success_Codes__c
				FROM External_Storage_Settings__c WITH USER_MODE LIMIT 200 
			];
            List<String> lstSuccessCodes = lstESSettings[0].Success_Codes__c.split('; ');
            intIteratorLimit = lstEFV.size();
            if (lstEFV.size() > 90) {
                setEFIdsToReprocess.add(objExternalFile.id);
                intIteratorLimit = 90;
            } else {
                setEFIdsToReprocess.remove(objExternalFile.id);
            }
            for (Integer i = 0; i < intIteratorLimit; i++) {
                External_File_Version__c objEFV = lstEFV[i];
                PresignedURLGenerator.GetSignedURLWrapper objGetSignedURLWrapper = new PresignedURLGenerator.GetSignedURLWrapper();
                objGetSignedURLWrapper.strMethod = 'DELETE';
                objGetSignedURLWrapper.strAccKy = lstESSettings[0].Access_Key__c;
                objGetSignedURLWrapper.strStKy = lstESSettings[0].Secret_Key__c;
                objGetSignedURLWrapper.strBucketName = lstESSettings[0].Bucket__c;
                objGetSignedURLWrapper.strBucketRegion = lstESSettings[0].Region__c;
                objGetSignedURLWrapper.strLocation = objEFV.File_Location_URL__c.substring(0, 51) + PresignedURLGenerator.uriEncode(objEFV.File_Location_URL__c.substringAfter(lstESSettings[0].File_Retrieve_URL__c + '/'),true);
                objGetSignedURLWrapper.strFile = objEFV.File_Location_URL__c.substringAfter(lstESSettings[0].File_Retrieve_URL__c + '/');
                objGetSignedURLWrapper.intExpires = Integer.valueOf(lstESSettings[0].Expiration_Time__c);
                objGetSignedURLWrapper.strFileName = '';
                String strPreSignedURL = PresignedURLGenerator.getSignedURL(objGetSignedURLWrapper);
                HttpResponse response = new HttpResponse();
                response = APIUtility.deleteFileFromExternalStorage(strPreSignedURL, 'DELETE');
                if (lstSuccessCodes.contains(String.valueOf(response.getstatuscode()))) {
                    lstEFVtoDelete.add(objEFV);
                } else {
                    bolCalloutFailed = true;
                    intNumOfErrors++;
                    strAPIFailedRecordIds += '\'' + objEFV.Id + '\', ';
                }
            }
            if (lstEFVtoDelete.size() > 0 && !bolCalloutFailed) {
                deleteEFandEFV(lstEFVtoDelete, !bolCalloutFailed, objExternalFile);
            }
        } catch (Exception exp) {
            intNumOfErrors += setExternalFileIds.size();
            strExpRecordIds += '\'' + setExternalFileIds + '\', ';
            ErrorLogger.logBatchException(bc.getJobId(), 'DeleteExternalFilesBatch Execution', exp);
        }
    }
    global void finish(Database.BatchableContext bc) {
        if (setEFIdsToReprocess.size() > 0) {
            Database.executeBatch(new DeleteExternalFilesBatch(strWhere, setEFIdsToReprocess), 1);
        }
        // To log error details and sending the batch details to the user email who ran the batch.
        String strFailedRecordIds = '';
        if (strAPIFailedRecordIds != '') {
            strFailedRecordIds += 'Record Ids that are failed during the API request:  <br/>' + strAPIFailedRecordIds.removeEnd(', ') + '<br/>';
        }
        if (strExpRecordIds != '') {
            strFailedRecordIds += ' Record Ids that are captured while throwing exception:  <br/>' + strExpRecordIds.removeEnd(', ');
        }
        Set<Id> setRecipientIds = new Set<Id>{ UserInfo.getUserId() };
        if(Schema.SObjectType.Exception_Error__c.isAccessible() && Schema.SObjectType.Exception_Error__c.fields.Related_To__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.StackTraceString__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Exception_Message__c.isCreateable()
        && Schema.SObjectType.Exception_Error__c.fields.BatchJobId__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Record_Id__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Status_Code__c.isCreateable()){
            ErrorLogger.LogBatchErrorsWrapper objLogBatchErrorsWrapper = new ErrorLogger.LogBatchErrorsWrapper();
            objLogBatchErrorsWrapper.apexJobId = bc.getJobId();
            objLogBatchErrorsWrapper.strBatchClassName = 'DeleteExternalFilesBatch';
            objLogBatchErrorsWrapper.setUserIds = setRecipientIds;
            objLogBatchErrorsWrapper.strFailures = strFailedRecordIds;
            objLogBatchErrorsWrapper.intNumOfErrors = intNumOfErrors;
            ErrorLogger.logBatchErrors(objLogBatchErrorsWrapper);
        }
    }
    
    private void deleteEFandEFV(List<External_File_Version__c> lstEFVtoDelete, Boolean bolCalloutFailed, External_Files__c objExternalFile) {
        if (lstEFVtoDelete.size() > 0) {
            List<Database.DeleteResult> lstDeleteResults = Database.delete(lstEFVtoDelete, false);
            for (Integer intIndex = 0; intIndex < lstDeleteResults.size(); intIndex++) {
                if (!lstDeleteResults[intIndex].isSuccess()) {
                    setExternalFileIds.add(lstEFVtoDelete[intIndex].Id);
                }
            }
        }
        if (!bolCalloutFailed && !setEFIdsToReprocess.contains(objExternalFile.Id) && Schema.sObjectType.External_Files__c.isDeletable()) {
            Database.DeleteResult objDeleteResults = Database.delete(objExternalFile, false, AccessLevel.USER_MODE);
        }
    }
}