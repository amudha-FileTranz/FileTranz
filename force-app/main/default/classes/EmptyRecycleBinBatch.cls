/*
 * Purpose : This batch class is used to empty the recycle bin(deleting only External File Links). Once this batch is completed DeleteExternalFilesBatch will be executed to delete the External Files.
 * Author  : Anandhakumar Thangasamy
 */

/**
 * Batch class to clear recycle bin records.
 *
 * NOTE:
 * This class is declared as 'global' because it is invoked from another namespace
 * and exposed as part of a managed package API. Reducing visibility to 'public'
 * would break cross-namespace access.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class EmptyRecycleBinBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    String strWhere;
    String strAPIFailedRecordIds = '';
    
    String strExpRecordIds = '';
    Integer intNumOfErrors = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        List<Configuration__c> lstConfiguration = [SELECT id,Name,Configuration_Type__c ,Configuration_Name__c, Long_Value__c FROM Configuration__c WHERE Configuration_Name__c = 'Clear_Recycle_Bin_In' WITH USER_MODE];
        strWhere = lstConfiguration != null && lstConfiguration.size()>0 ? lstConfiguration[0].Long_Value__c : '30';
        String strQuery = 'SELECT Id FROM External_File_Link__c WHERE Is_Deleted__c = true AND LastModifiedDate >= LAST_N_DAYS:' + strWhere + ' WITH SECURITY_ENFORCED';
        return Database.getQueryLocator(strQuery);
    }
    global void execute(Database.BatchableContext bc, List<External_File_Link__c> lstExternalFileLinks) {
        set<String> setExternalFileIds = new set<String>();
        try {
            List<Database.DeleteResult> lstDeleteResults = Database.delete(lstExternalFileLinks, false);
            for(Integer intIndex = 0; intIndex < lstDeleteResults.size(); intIndex++){
                if(!lstDeleteResults[intIndex].isSuccess()){
                    setExternalFileIds.add(lstExternalFileLinks[intIndex].Id);
                }
            }
        } catch (Exception exp) {
            intNumOfErrors+= setExternalFileIds.size();
            strExpRecordIds +=  '\'' + setExternalFileIds + '\', ';
            ErrorLogger.logBatchException(bc.getJobId(), 'EmptyRecycleBinBatch Execution', exp);
        }
    }
    global void finish(Database.BatchableContext bc) {
        Database.executeBatch(new DeleteExternalFilesBatch(strWhere), 1);
        // To log error details and sending the batch details to the user email who ran the batch.
        String strFailedRecordIds = '';
        if(strExpRecordIds != ''){
            strFailedRecordIds += ' Record Ids that are captured while throwing exception:  <br/>' + strExpRecordIds.removeEnd(', ');
        }
        Set<Id> setRecipientIds = new Set<Id>{ UserInfo.getUserId() };
        if(Schema.SObjectType.Exception_Error__c.isAccessible() && Schema.SObjectType.Exception_Error__c.fields.Related_To__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.StackTraceString__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Exception_Message__c.isCreateable()
        && Schema.SObjectType.Exception_Error__c.fields.BatchJobId__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Record_Id__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Status_Code__c.isCreateable()){
            ErrorLogger.LogBatchErrorsWrapper objLogBatchErrorsWrapper = new ErrorLogger.LogBatchErrorsWrapper();
            objLogBatchErrorsWrapper.apexJobId = bc.getJobId();
            objLogBatchErrorsWrapper.strBatchClassName = 'EmptyRecycleBinBatch';
            objLogBatchErrorsWrapper.setUserIds = setRecipientIds;
            objLogBatchErrorsWrapper.strFailures = strFailedRecordIds;
            objLogBatchErrorsWrapper.intNumOfErrors = intNumOfErrors;
            ErrorLogger.logBatchErrors(objLogBatchErrorsWrapper); // CC-23639
        }
    }
}