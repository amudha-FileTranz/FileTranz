public with sharing class ViewFilesControllerHelper {
    /**
     * To delete external file from org
     * @param lstExternalFileIds,strMoveToBin,strPreSignedURL from uploadViewFiles LWC
     * @return String
     */
    @AuraEnabled
    public static String deleteExternalFileLinks(List<String> lstExternalFileLinkIds, String strMoveToBin, String strPreSignedURL) {
        List<String> lstFileNames = new List<String>();
        for(String str: lstExternalFileLinkIds){
            lstFileNames.add(String.escapeSingleQuotes(str));
        }
        List<External_File_Link__c> lstQueriedFileLinks = [
			SELECT Id, External_Files__c, External_Files__r.File_Name__c, Is_Deleted__c, Related_To__c
			FROM External_File_Link__c
			WHERE Id = :lstFileNames AND Is_Deleted__c = FALSE WITH USER_MODE
		];
        // Related_To__c is a plain text field, not a real Salesforce lookup, so object/field-level
        // access (WITH USER_MODE above) does not by itself guarantee the running user can actually
        // see the record this file is attached to. Drop any link the user isn't allowed to see before
        // acting on it, exactly the same as an unauthorized/not-found file.
        List<External_File_Link__c> lstExternalFileLinks = new List<External_File_Link__c>();
        for (External_File_Link__c objEFL : lstQueriedFileLinks) {
            if (CommonUtilities.hasAccessToParentRecord(objEFL.Related_To__c)) {
                lstExternalFileLinks.add(objEFL);
            }
        }
        Set<Id> setEFId = new Set<Id>();
        for (External_File_Link__c objEFL : lstExternalFileLinks) {
            setEFId.add(objEFL.External_Files__c);
        }
        String strMessage = 'success';
        if(strMoveToBin == 'true' && !lstExternalFileLinks.isEmpty() && !setEFId.isEmpty() && strPreSignedURL != ''){
            strMessage = moveToBinTrue(lstExternalFileLinks , setEFId, strPreSignedURL);
        }else if(strMoveToBin == 'false' && !lstExternalFileLinks.isEmpty() && !setEFId.isEmpty() && strPreSignedURL != ''){
            strMessage = moveToBinFalse(lstExternalFileLinks , setEFId, strPreSignedURL);
        }else{
            strMessage = 'File Not Found';
        }
        return strMessage;
    }
    
    private static String moveToBinTrue(List<External_File_Link__c> lstExternalFileLinks , Set<Id> setEFId, String strPreSignedURL) {
        
        String strMessage = 'error';
        try {
            String strActivities = CommonUtilities.getConfiguration(new List<String>{ 'File Configuration' }).get('Log_Activity');
            User objUser = CommonUtilities.getCurrentUserDetails();
            List<Log_Activity__c> lstLogActivity = new List<Log_Activity__c>();
            if(!Schema.SObjectType.External_Files__c.isAccessible() && !Schema.SObjectType.External_Files__c.isUpdateable()
            && !Schema.SObjectType.External_File_Link__c.isAccessible() && !Schema.SObjectType.External_File_Link__c.isUpdateable() && !Schema.SObjectType.External_File_Link__c.fields.Is_Deleted__c.isAccessible()){
                return 'Failure';
            }
            External_Files__c objEF = [SELECT Id, (SELECT Id FROM External_File_Links__r WHERE Object_Type__c != 'User' AND Is_Deleted__c = false) FROM External_Files__c WHERE Id IN :setEFId WITH USER_MODE LIMIT 1 ];
            for (External_File_Link__c objExtFileLink : lstExternalFileLinks) {
                objExtFileLink.Is_Deleted__c = true;
                if (strActivities != null && strActivities.contains('Delete') && Schema.SObjectType.Log_Activity__c.isCreateable() && Schema.SObjectType.Log_Activity__c.fields.Activity_Type__c.isAccessible() && Schema.SObjectType.Log_Activity__c.fields.Activity_Performed_By__c.isAccessible() && Schema.SObjectType.Log_Activity__c.fields.Record_Id__c.isAccessible() && Schema.SObjectType.Log_Activity__c.fields.Activity_Value__c.isAccessible()
                && Schema.SObjectType.Log_Activity__c.fields.File_Name__c.isAccessible() && Schema.SObjectType.Log_Activity__c.fields.External_File_Id__c.isAccessible() && Schema.SObjectType.Log_Activity__c.fields.Activity_Field__c.isAccessible()) {
                    Log_Activity__c objLogActivity = new Log_Activity__c();
                    objLogActivity.File_Name__c = objExtFileLink.External_Files__r.File_Name__c;
                    objLogActivity.External_File_Id__c = objExtFileLink.External_Files__c;
                    objLogActivity.Activity_Type__c = 'Delete';
                    objLogActivity.Activity_Performed_By__c = objUser.Id;
                    objLogActivity.Activity_Field__c = 'Is_Deleted__c';
                    objLogActivity.Activity_Value__c = String.valueof(objExtFileLink.Is_Deleted__c);
                    objLogActivity.Record_Id__c = objExtFileLink.Related_To__c;
                    lstLogActivity.add(objLogActivity);
                }
            }
            if(!lstExternalFileLinks.isEmpty()){
                SObjectAccessDecision objAccessDecision = Security.stripInaccessible(AccessType.UPDATABLE, lstExternalFileLinks);
                List<External_File_Link__c> lstExternalFileLinksUpdateable = (List<External_File_Link__c>)objAccessDecision.getRecords();
                if(!lstExternalFileLinksUpdateable.isEmpty() && External_File_Link__c.SObjectType.getDescribe().isUpdateable()){ {
                        update lstExternalFileLinksUpdateable;
                    }
                    
                }
                if (objEF.External_File_Links__r.size() <= 1 && Schema.SObjectType.External_Files__c.isUpdateable()) {
                    objEF.Is_Deleted__c = true;
                    if(External_Files__c.SobjectType.getDescribe().isUpdateable()){
                        update objEF;
                    }
                }
                
                // To insert log activity records
                if (!lstLogActivity.isEmpty() && Log_Activity__c.SobjectType.getDescribe().isCreateable()) {
                    
                    SObjectAccessDecision objAccessDecision1 = Security.stripInaccessible(AccessType.CREATABLE, lstLogActivity);
                    List<Log_Activity__c> lstLogActivityCreatable = (List<Log_Activity__c>)objAccessDecision1.getRecords();
                    if(!lstLogActivityCreatable.isEmpty() && Schema.SObjectType.Log_Activity__c.isCreateable()){
                        insert lstLogActivityCreatable;
                    }
                }
                strMessage = 'success';
            }
        } catch (Exception exp) {
            ErrorLogger.logException('ViewFilesControllerHelper.moveToBinTrue', exp);
            strMessage = 'Failure';
        }
        return strMessage;
    }
    
    private static String moveToBinFalse(List<External_File_Link__c> lstExternalFileLinks , Set<Id> setEFId, String strPreSignedURL) {
        String strMessage = 'Error';
        try {
            String strActivities = CommonUtilities.getConfiguration(new List<String>{ 'File Configuration' }).get('Log_Activity');
            User objUser = CommonUtilities.getCurrentUserDetails();
            List<Log_Activity__c> lstLogActivity = new List<Log_Activity__c>();
            External_Files__c objEF = [SELECT Id, (SELECT Id FROM External_File_Links__r WHERE Object_Type__c != 'User' AND Is_Deleted__c = false) FROM External_Files__c WHERE Id IN :setEFId WITH USER_MODE LIMIT 1 ];
            if (objEF.External_File_Links__r.size() <= 1) {
                HttpResponse response = APIUtility.deleteFileFromExternalStorage(strPreSignedURL, 'DELETE');
                if (response.getStatusCode() == 204) {
                    strMessage = deleteExternalFiles(objEF);
                    if (strActivities != null && strActivities.contains('Delete')) {
                        for (External_File_Link__c objExtFileLink : lstExternalFileLinks) {
                            if(Schema.SObjectType.Log_Activity__c.isCreateable() && Schema.SObjectType.Log_Activity__c.fields.Record_Id__c.isAccessible() && Schema.SObjectType.Log_Activity__c.fields.Activity_Type__c.isAccessible()){
                                Log_Activity__c objLogActivity = new Log_Activity__c();
                                objLogActivity.File_Name__c = objExtFileLink.External_Files__r.File_Name__c;
                                objLogActivity.External_File_Id__c = objExtFileLink.External_Files__c;
                                objLogActivity.Activity_Type__c = 'Delete';
                                objLogActivity.Activity_Performed_By__c = objUser.Id;
                                objLogActivity.Record_Id__c = objExtFileLink.Related_To__c;
                                lstLogActivity.add(objLogActivity);
                            }
                        }
                    }
                }
                
                if(Schema.SObjectType.Log_Activity__c.isCreateable() && Schema.SObjectType.Log_Activity__c.fields.Record_Id__c.isAccessible()){
                    SObjectAccessDecision objAccessDecision2 = Security.stripInaccessible(AccessType.CREATABLE, lstLogActivity);
                    List<Log_Activity__c> lstLogActivityValid = (List<Log_Activity__c>)objAccessDecision2.getRecords();
                    // To insert log activity records
                    if(!lstLogActivityValid.isEmpty() && Schema.SObjectType.Log_Activity__c.isCreateable()){ {
                            insert lstLogActivityValid;
                        }
                    }
                    
                } else {
                    // Call the deleteExternalFilesLink
                    strMessage = deleteExternalFilesLink(lstExternalFileLinks);
                }
            }
            // To insert log activity records
        } catch (Exception exp) {
            ErrorLogger.logException('ViewFilesControllerHelper.moveToBinFalse', exp);
            strMessage = 'Failure';
        }
        return strMessage;
    }
    // Deletes a External_Files__c records
    private static String deleteExternalFiles(External_Files__c objEF){
        String strMessage = 'success';
        try {
            if(External_Files__c.SobjectType.getDescribe().isDeletable()){
                delete objEF;
            }
        } catch (Exception exp) {
            ErrorLogger.logException('ViewFilesController.deleteExternalFiles', exp);
            strMessage = 'Failure';
        }
        return strMessage;
    }
    // Deletes a list of External_File_Link__c records
    private static String deleteExternalFilesLink(List<External_File_Link__c> lstExternalFileLinks){
        String strMessage = 'success';
        try {
            if(External_File_Link__c.SobjectType.getDescribe().isdeletable()){
                delete lstExternalFileLinks;
            }
        } catch (Exception exp) {
            ErrorLogger.logException('ViewFilesController.deleteExternalFiles', exp);
            strMessage = 'Failure';
        }
        return strMessage;
    }
    
}