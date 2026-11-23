/*
 * Purpose : This class act as a utility class for utilizing the common methods.
 * Author  : Anandhakumar Thangasamy, Giri, Nishanth S
 */
public with sharing class CommonUtilities {

	private static User currentUser;

    /**
     * Whether the running user is assigned the FileTranz_Admin permission set. Storage-credential
     * read/write endpoints must gate on this explicitly, since Apex class access and custom-setting
     * access are otherwise identical between the FileTranz_Admin and FileTranz_User permission sets.
     * @return Boolean
     */
    public static Boolean isFileTranzAdmin() {
        List<PermissionSetAssignment> lstAssignments = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'FileTranz_Admin'
            WITH USER_MODE
            LIMIT 1
        ];
        return !lstAssignments.isEmpty();
    }

    /**
     * Verifies the running user has access to the given record, respecting OWD/sharing rules/role
     * hierarchy - the row-level check that External_File_Link__c.Related_To__c cannot provide
     * natively, since it is a plain text field rather than a real Salesforce lookup relationship.
     * Used by every file read/sign/delete entry point that resolves a file back to the record it's
     * attached to, before acting on it.
     * @param strRelatedToId the stored Related_To__c value (a record Id as text)
     * @return Boolean
     */
    // PMD's ApexSOQLInjection rule flags the dynamic FROM clause below on sight, but strObjectApiName
    // is never attacker-controlled: Id.valueOf enforces Salesforce's own Id-format validation first,
    // and getSObjectType().getDescribe().getName() only ever returns one of the org's real, existing
    // object API names for that Id's key prefix. There is no code path by which arbitrary text can
    // reach the query string here.
    @SuppressWarnings('PMD.ApexSOQLInjection')
    public static Boolean hasAccessToParentRecord(String strRelatedToId) {
        if (String.isBlank(strRelatedToId)) {
            return false;
        }
        try {
            Id idRelatedTo = Id.valueOf(strRelatedToId);
            String strObjectApiName = idRelatedTo.getSObjectType().getDescribe().getName();
            List<SObject> lstRecords = Database.query(
                'SELECT Id FROM ' + strObjectApiName + ' WHERE Id = :idRelatedTo'
            );
            return !lstRecords.isEmpty();
        } catch (Exception exp) {
            return false;
        }
    }

    /**
     * To convert file size to KB for sorting
     * @param strFileSize from ViewFilesController class.
     * @return Double
     */
    public static Double getFileSizeInKB(String strFileSize) {
        if (strFileSize.endsWith('KB')) {
            return Double.valueOf(strFileSize.substring(0, strFileSize.length() - 3)) * 1024;
        } else if (strFileSize.endsWith('MB')) {
            return Double.valueOf(strFileSize.substring(0, strFileSize.length() - 3)) * 1024 * 1024;
        } else if (strFileSize.endsWith('GB')) {
            return Double.valueOf(strFileSize.substring(0, strFileSize.length() - 3)) * 1024 * 1024 * 1024;
        } else {
            return Double.valueOf(strFileSize.substring(0, strFileSize.length() - 2));
        }
    }
    
    /**
     * To get all the object name
     * @param - from orgWideConfigurations, jobConfigurations LWC.
     * @return List<EntityDefinitionWrapper>
     */
    @AuraEnabled(cacheable=true)
    public static List<EntityDefinitionWrapper> getAllObjectName() {
        List<EntityDefinitionWrapper> lstEntDefWrap = new List<EntityDefinitionWrapper>();
        for (EntityDefinition objEntDef : [SELECT Label, QualifiedApiName, IsCustomizable, IsCustomSetting, IsApexTriggerable FROM EntityDefinition WHERE IsCustomizable = TRUE AND IsCustomSetting = FALSE AND IsApexTriggerable = TRUE WITH USER_MODE]) {
            EntityDefinitionWrapper objEntDefWrap = new EntityDefinitionWrapper();
            objEntDefWrap.label = objEntDef.QualifiedApiName;
            objEntDefWrap.value = objEntDef.QualifiedApiName;
            lstEntDefWrap.add(objEntDefWrap);
        }
        return lstEntDefWrap;
    }
    
    /**
     * To get all the object name
     * @param - from uploadViewFiles LWC & ViewFilesController, UploadFilesController classes.
     * @return Map<String, Configuration__c>
     */
    @AuraEnabled
    public static Map<String, String> getConfiguration(List<String> lstConfigurationType) {
        Map<String, String> mapConfigByKey = new Map<String, String>();
        for(Configuration__c objConfiguration: [SELECT Id, Configuration_Name__c, Long_Value__c, Configuration_Type__c FROM Configuration__c WHERE Configuration_Type__c IN :lstConfigurationType WITH USER_MODE]){
            String strLongValue = objConfiguration.Long_Value__c == null ? '' : objConfiguration.Long_Value__c;
            mapConfigByKey.put(objConfiguration.Configuration_Name__c, strLongValue);
        }
        return mapConfigByKey;
    }
    
    /**
     * To get current user details
     * @param - from ViewFilesController, UploadFilesController classes.
     * @return User
     */
    public static User getCurrentUserDetails() {
        if (currentUser == null) {
            currentUser = [SELECT Id, Name, UserName, Phone, UserType, ProfileId, Profile.Name, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE];
        }
        return currentUser;
    }
    
    /**
     * To get file size with correct format
     * @param - from UploadFilesController, ViewFilesController classes.
     * @return String
     */
    public static String formatFileSize(Decimal decFileSize) {
        Integer intKiloBytes = 1024;
        Integer intMegaBytes = intKiloBytes * 1024;
        Integer intGigaBytes = intMegaBytes * 1024;
        String strSize = '';
        if (decFileSize < intKiloBytes) {
            strSize = decFileSize + ' B';
        } else if (decFileSize < intMegaBytes) {
            strSize = (decFileSize / intKiloBytes).round() + ' KB';
        } else if (decFileSize < intGigaBytes) {
            strSize = (decFileSize / intMegaBytes).setscale(2) + ' MB';
        } else {
            strSize = (decFileSize / intGigaBytes).setscale(2) + ' GB';
        }
        return strSize;
    }
    
    /**
     * To get active storage setting, INCLUDING the raw access/secret key. This must never be
     * @AuraEnabled - it is for internal Apex-to-Apex use only (UploadFilesController,
     * PresignedURLGenerator, ViewFilesController), which never needs remote invocability.
     * LWC code must use getActiveStorageSettingForLWC() instead, which excludes the secret.
     * @return ExternalStorageSettingWrapper
     */
    public static ExternalStorageSettingWrapper getActiveStorageSetting(){
        ExternalStorageSettingWrapper objExtStorSetWrap = new ExternalStorageSettingWrapper();
        try {
            External_Storage_Settings__c objExtStorageSet = [SELECT Id, Name, Access_Key__c, Secret_Key__c, Region__c, Bucket__c, File_Retrieve_URL__c, Endpoint_Url__c, Storage__c, Expiration_Time__c, Maximum_File_Size__c, Success_Codes__c FROM External_Storage_Settings__c WITH USER_MODE LIMIT 1];
            if(objExtStorageSet != null){
                objExtStorSetWrap.strAccKy = objExtStorageSet.Access_Key__c;
                objExtStorSetWrap.strStKy = objExtStorageSet.Secret_Key__c;
                objExtStorSetWrap.strBucket = objExtStorageSet.Bucket__c;
                objExtStorSetWrap.strRegion = objExtStorageSet.Region__c;
                objExtStorSetWrap.strEndPoint = objExtStorageSet.File_Retrieve_URL__c;
                objExtStorSetWrap.strName = objExtStorageSet.Name;
                objExtStorSetWrap.intExpirationTime = objExtStorageSet.Expiration_Time__c;
                objExtStorSetWrap.strSuccessCodes = objExtStorageSet.Success_Codes__c;
                objExtStorSetWrap.strMaximumFileSize = String.valueOf(objExtStorageSet.Maximum_File_Size__c);
                objExtStorSetWrap.strStorageType = objExtStorageSet.Storage__c;
            }
        } catch (Exception exp) {
            ErrorLogger.logException('CommonUtilities.getActiveStorageSetting', exp);
        }
        return objExtStorSetWrap;
    }
    
    /**
     * To get active storage setting from LWC (without access key and secret key)
     * @param - from uploadViewFiles LWC.
     * @return String
     */
    @AuraEnabled
    public static ExternalStorageSettingWrapper getActiveStorageSettingForLWC(){
        ExternalStorageSettingWrapper objExtStorSetWrap = new ExternalStorageSettingWrapper();
        try {
            External_Storage_Settings__c objExtStorageSet = [SELECT Id,Name,Access_Key__c,Secret_Key__c,Region__c,Bucket__c,File_Retrieve_URL__c,Endpoint_Url__c,Storage__c,Expiration_Time__c, Maximum_File_Size__c, Success_Codes__c FROM External_Storage_Settings__c WITH USER_MODE LIMIT 1 ];
            if(objExtStorageSet != null){
                objExtStorSetWrap.strBucket = objExtStorageSet.Bucket__c;
                objExtStorSetWrap.strRegion = objExtStorageSet.Region__c;
                objExtStorSetWrap.strEndPoint = objExtStorageSet.File_Retrieve_URL__c;
                objExtStorSetWrap.strName = objExtStorageSet.Name;
                objExtStorSetWrap.intExpirationTime = objExtStorageSet.Expiration_Time__c;
                objExtStorSetWrap.strSuccessCodes = objExtStorageSet.Success_Codes__c;
                objExtStorSetWrap.strMaximumFileSize = String.valueOf(objExtStorageSet.Maximum_File_Size__c);
                objExtStorSetWrap.strStorageType = objExtStorageSet.Storage__c;
            }
        } catch (Exception exp) {
            ErrorLogger.logException('CommonUtilities.getActiveStorageSetting', exp);
        }
        return objExtStorSetWrap;
    }
    
    /**
     * To get user access level on file
     * @param - from uploadViewFiles LWC
     * @return List<String>
     */
    @AuraEnabled
    public static List<String> getCurrentUserPermissions() {
        List<PermissionSetAssignment> lstPermissionSetAssignment = [SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE AssigneeId =: UserInfo.getUserId() WITH USER_MODE];
        Set<Id> setPermissionSetId = new Set<Id>();
        Set<String> setPermissions = new Set<String>();
        for(PermissionSetAssignment objPermissionSetAssignment: lstPermissionSetAssignment) {
            setPermissionSetId.add(objPermissionSetAssignment.PermissionSetId);
        }
        List<Configuration__c> lstConfiguration = [SELECT Id, Configuration_Name__c, Long_Value__c, Configuration_Type__c FROM Configuration__c WHERE (Configuration_Name__c IN :setPermissionSetId) AND Configuration_Type__c = 'Permission Configuration' WITH USER_MODE];
        for(Configuration__c objConfiguration : lstConfiguration) {
            if(objConfiguration.Long_Value__c != null) {
                setPermissions.addAll(new Set<String>(objConfiguration.Long_Value__c.split('; ')));
            }
        }
        return new List<String>(setPermissions);
    }
    
    /**
     * To get delted external file details
     * @param - from recycleBin LWC
     * @return List<External_files__c>
     */
    @AuraEnabled(cacheable=true)
    public static List<External_File_Link__c> getDeletedExternalFiles(){
        return [SELECT Id, Name, External_Files__r.File_Name__c, External_Files__r.File_Type__c, Object_Type__c, Related_To__c, Is_Deleted__c 
        FROM External_File_Link__c WHERE Is_Deleted__c = true WITH USER_MODE ORDER BY Name DESC];
    }

    /**
     * To restore external files
     * @param lstEFLids from recycleBin LWC
     * @return String
     */
    @AuraEnabled
    public static String restoreExternalfile(List<String> lstEFLids) {
        try {
            Set<Id> setEFIds = new Set<Id>();
            List<External_File_Link__c> lstExtFileLinks = [SELECT Id, Is_Deleted__c, External_Files__c FROM External_File_Link__c WHERE Id IN :lstEFLids AND Is_Deleted__c = true WITH USER_MODE];
            for(External_File_Link__c objEFL : lstExtFileLinks){
                objEFL.Is_Deleted__c = false;
                setEFIds.add(objEFL.External_Files__c);
            }
            List<External_Files__c> lstEFs = [SELECT Id, Is_Deleted__c FROM External_Files__c WHERE Id IN :setEFIds WITH USER_MODE];
            for(External_Files__c objEF : lstEFs) {
                objEF.Is_Deleted__c = false;
            }
            if(Schema.SObjectType.External_File_Link__c.isUpdateable() && Schema.sObjectType.External_File_Link__c.fields.Is_Deleted__c.isUpdateable() && lstExtFileLinks.size() > 0){
                update lstExtFileLinks;
            } else {
                throw new AuraHandledException('You do not have permission to update External File Link records.');
            }
            
            if(Schema.sObjectType.External_Files__c.isUpdateable() && Schema.sObjectType.External_Files__c.fields.Is_Deleted__c.isUpdateable() && lstEFs.size() > 0){
                update lstEFs;
            } else {
                throw new AuraHandledException('You do not have permission to update External Files records.');
            }
            return Label.Success;
        } catch(Exception exp){
            ErrorLogger.logException('CommonUtilities.restoreExternalfile', exp);
            return exp.getMessage();
        }
    }

    /**
     * To get profile user level configuration details
     * @param strObjectName from jobConfigurations LWC
     * @return List<EntityDefinitionWrapper>
     */
    @AuraEnabled
    public static List<EntityDefinitionWrapper> getSObjectFields(String strObjectName) {
        List<EntityDefinitionWrapper> lstEntDefWrap = new List<EntityDefinitionWrapper>();
        try {
            Schema.DescribeSObjectResult objDescribeObjectResult = Schema.getGlobalDescribe().get(strObjectName).getDescribe();
            Map<String, Schema.SObjectField> mapFieldDetails = objDescribeObjectResult.fields.getMap();
            for(String strFieldName : mapFieldDetails.keySet()){
                Schema.DescribeFieldResult objDescribeFieldResult = mapFieldDetails.get(strFieldName).getDescribe();
                EntityDefinitionWrapper objEntDefWrap = new EntityDefinitionWrapper();
                objEntDefWrap.label = objDescribeFieldResult.getName();
                objEntDefWrap.value = objDescribeFieldResult.getName();
                objEntDefWrap.type = String.valueOf(objDescribeFieldResult.getType());
                lstEntDefWrap.add(objEntDefWrap);
            }
        } catch(Exception exp) {
            ErrorLogger.logException('CommonUtilities.restoreExternalfile', exp);
        }
        return lstEntDefWrap;
    }
    
    public static String getObjectLabelFromId(String strRecordId) {
        Id idRecord = strRecordId;
        SObjectType strObjectType = idRecord.getSObjectType();
        DescribeSObjectResult objDescribeResult = strObjectType.getDescribe();
        return objDescribeResult.getLabel();
    }
    
    /**
     * To check record is there or not
     * @param externalKeyWithFileMap from recycleBin LWC
     * @return Boolean
     */
    
    @AuraEnabled
    public static Boolean checkRelatedRecords(Map<String, List<String>> externalKeyWithFileMap) {
        Boolean returnStatus = true;
        
        Map<String, Schema.SObjectType> mapGlobalDescribe = Schema.getGlobalDescribe();
        for (String sObjectName : externalKeyWithFileMap.keySet()) {
            // Only allow object names that actually exist in this org's schema - a raw string
            // concatenated into the FROM clause would otherwise let a caller probe/query any
            // object by name regardless of whether it should be reachable from this entry point.
            if (!mapGlobalDescribe.containsKey(sObjectName)) {
                returnStatus = false;
                break;
            }

            Set<String> sObjectIds = new Set<String>();
            for (String id : externalKeyWithFileMap.get(sObjectName)) {
                sObjectIds.add(String.escapeSingleQuotes(id));
            }

            // Build the query dynamically (sObjectName is now validated against the schema above)
            String strQuery = 'SELECT Id, Name FROM ' + sObjectName + ' WHERE Id IN :sObjectIds WITH USER_MODE';

            // Perform the query
            List<SObject> listData = Database.query(strQuery);
            
            // Compare sizes to determine if all IDs exist
            if (sObjectIds.size() != listData.size()) {
                returnStatus = false;
                break;
            }
        }
        
        return returnStatus;
    }
    
    // Common External Files Wrapper.
    public class ExternalFilesWrapper {
        @AuraEnabled
        public Id strId { get; set; }
        @AuraEnabled
        public String strName { get; set; }
        @AuraEnabled
        public String strFileName { get; set; }
        @AuraEnabled
        public String strSize { get; set; }
        @AuraEnabled
        public String strFileURL { get; set; }
        @AuraEnabled
        public String strObjectType { get; set; }
        @AuraEnabled
        public String lastModifiedDate { get; set; }
        @AuraEnabled
        public String strDisplayText { get; set; }
        @AuraEnabled
        public String strRelatedTo { get; set; }
        @AuraEnabled
        public String strFileType { get; set; }
        @AuraEnabled
        public Boolean bolShowEdit { get; set; }
        @AuraEnabled
        public Boolean bolSelected { get; set; }
        @AuraEnabled
        public Integer sNo { get; set; }
        @AuraEnabled
        public Double dblSize { get; set; }
        @AuraEnabled
        public Boolean bolDisable { get; set; }
        @AuraEnabled
        public String strUID { get; set; }
        @AuraEnabled
        public string strExternalFileId { get; set; }
    }

    public class EntityDefinitionWrapper {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String type { get; set; }
    }

    public class ExternalStorageSettingWrapper{
        @AuraEnabled public String strAccKy{get;set;}
        @AuraEnabled public String strStKy{get;set;}
        @AuraEnabled public String strBucket{get;set;}
        @AuraEnabled public String strRegion{get;set;}
        @AuraEnabled public String strEndPoint{get;set;}
        @AuraEnabled public Boolean strActive{get;set;}
        @AuraEnabled public String strId{get;set;}
        @AuraEnabled public String strName {get;set;}
        @AuraEnabled public String strObjects{get;set;}
        @AuraEnabled public decimal intExpirationTime{get;set;}
        @AuraEnabled public String strSuccessCodes{get;set;}
        @AuraEnabled public String strMaximumFileSize{get;set;}
        @AuraEnabled public String strStorageType{get;set;}
    }
}