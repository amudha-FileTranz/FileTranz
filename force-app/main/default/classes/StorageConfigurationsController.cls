/*
 * Purpose : To controll the behaviour of storageConfigurations LWC.
 * Author  : Nishanth
 */
public with sharing class StorageConfigurationsController {
    /**
     * To get all storage configuration details from the org.
     * @param  from storageConfigurations LWC
     * @return List<CommonUtilities.ExternalStorageSettingWrapper>
     */
    @AuraEnabled
    public static List<CommonUtilities.ExternalStorageSettingWrapper> getAllStorageConfig(){
        List<CommonUtilities.ExternalStorageSettingWrapper> lstWrapExtSet = new  List<CommonUtilities.ExternalStorageSettingWrapper>();
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to view storage configuration.');
        }
        try{
            Map<string,string> mapKeylongVal = new Map<string,string>();
            for( Configuration__c  objConfig :  [SELECT Id, Configuration_Name__c,Long_Value__c,Configuration_Type__c FROM Configuration__c WHERE Configuration_Type__c = 'Storage Configuration' WITH USER_MODE LIMIT 200]){
                mapKeylongVal.put(objConfig.Configuration_Name__c,objConfig.Long_Value__c);
            }
            for(External_Storage_Settings__c objExtSet : [SELECT Id,Access_Key__c, Active__c, Bucket__c, File_Retrieve_URL__c, Region__c, Secret_Key__c, Name from External_Storage_Settings__c WITH USER_MODE LIMIT 200]){
                CommonUtilities.ExternalStorageSettingWrapper objWrap = new CommonUtilities.ExternalStorageSettingWrapper();
                objWrap.strAccKy = objExtSet.Access_Key__c;
                objWrap.strStKy = objExtSet.Secret_Key__c;
                objWrap.strBucket = objExtSet.Bucket__c;
                objWrap.strRegion = objExtSet.Region__c;
                objWrap.strEndPoint = objExtSet.File_Retrieve_URL__c;
                objWrap.strActive = objExtSet.Active__c;
                objWrap.strId = objExtSet.Id;
                objWrap.strName = objExtSet.Name;
                objWrap.strObjects = mapKeylongVal.get(objExtSet.name) == null ?'':  mapKeylongVal.get(objExtSet.name);
                lstWrapExtSet.add(objWrap);
            }
        } catch (Exception exp) {
            ErrorLogger.logException('StorageConfigurationsController.getAllStorageConfig', exp);
        }
        return lstWrapExtSet;
    }
    /**
     * To cretae and update the storage connections
     * @param objExtStorageSet,strObjects from storageConfigurations LWC
     * @return String
     */
    @AuraEnabled
    public static String createUpdateExtStorageSetting(String strExtStorageSet, string strObjects){
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to create or update storage configuration.');
        }

        CommonUtilities.ExternalStorageSettingWrapper objExtStorageSet = (CommonUtilities.ExternalStorageSettingWrapper) JSON.deserialize(strExtStorageSet, CommonUtilities.ExternalStorageSettingWrapper.class);

        try{
            List<SObject> lstSObject = new List<SObject>();
            External_Storage_Settings__c objExtStrgSet = new External_Storage_Settings__c();
            objExtStrgSet.Name = objExtStorageSet.strName;
            objExtStrgSet.Access_Key__c= objExtStorageSet.strAccKy;
            objExtStrgSet.Secret_Key__c= objExtStorageSet.strStKy;
            objExtStrgSet.Region__c= objExtStorageSet.strRegion;
            objExtStrgSet.Bucket__c= objExtStorageSet.strBucket;
            objExtStrgSet.File_Retrieve_URL__c=objExtStorageSet.strEndPoint;
            objExtStrgSet.Storage__c = Label.Amazon_S3;
            objExtStrgSet.Success_Codes__c='200; 204';
            objExtStrgSet.Expiration_Time__c = 120000;
            objExtStrgSet.Maximum_File_Size__c = 12582912; // Able to uplaod max 12 mb size files
            objExtStrgSet.Active__c= (objExtStorageSet.strActive == null || objExtStorageSet.strActive == false ) ? false : true;
            objExtStrgSet.Id= objExtStorageSet.strId;
            lstSObject.add(objExtStrgSet);
            if(objExtStorageSet.strName != null && strObjects != null){
                List<Configuration__c> lstConfig = [SELECT Id, Configuration_Name__c FROM Configuration__c WHERE Configuration_Name__c =: objExtStorageSet.strName WITH USER_MODE];
                Configuration__c objConfig = new Configuration__c();
                objConfig.Id =lstConfig.size() > 0 ? lstConfig[0].Id: NULL ;
                objConfig.Configuration_Name__c = objExtStorageSet.strName ;
                objConfig.Configuration_Type__c = 'Storage Configuration';
                if(!Schema.SObjectType.Configuration__c.fields.Long_Value__c.isUpdateable() || !Schema.SObjectType.Configuration__c.fields.Long_Value__c.isCreateable()){
                    throw new AuraHandledException('You do not have permission to create or update Configuration records.');
                }
                objConfig.Long_Value__c	 = strObjects ;
                lstSObject.add(objConfig);
            }
            
            if(!Schema.SObjectType.External_Storage_Settings__c.isCreateable() || !Schema.SObjectType.External_Storage_Settings__c.isUpdateable()){
                throw new AuraHandledException('You do not have permission to create or update External Storage Settings or Configuration records.');
            }
            SObjectAccessDecision objAccessDecision = Security.stripInaccessible(AccessType.UPSERTABLE, lstSObject);
            List<SObject> lstSObjectUpsertable = (List<SObject>)objAccessDecision.getRecords();
            
            if(!lstSObjectUpsertable.isEmpty()){
                upsert as User lstSObjectUpsertable;
            }
        }catch(Exception exp){
            ErrorLogger.logException('StorageConfigurationsController.createUpdateExtStorageSetting', exp);
            return exp.getMessage();
        }
        return 'Successfully Created';
    }
    
    /**
     * To validate the storage connection at the time of creation
     * @param objExtStorageSet from storageConfigurations LWC
     * @return String
     */
    @AuraEnabled
    public static String validateConnection(String strExtStorageSet){
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to test storage configuration.');
        }

        CommonUtilities.ExternalStorageSettingWrapper objExtStorageSet = (CommonUtilities.ExternalStorageSettingWrapper) JSON.deserialize(strExtStorageSet, CommonUtilities.ExternalStorageSettingWrapper.class);
        HttpResponse response = new HttpResponse();
        try {
            PresignedURLGenerator.GetSignedURLWrapper objGetSignedURLWrapper = new PresignedURLGenerator.GetSignedURLWrapper();
            objGetSignedURLWrapper.strMethod = 'GET';
            objGetSignedURLWrapper.strAccKy = objExtStorageSet.strAccKy;
            objGetSignedURLWrapper.strStKy = objExtStorageSet.strStKy;
            objGetSignedURLWrapper.strBucketName = objExtStorageSet.strBucket;
            objGetSignedURLWrapper.strBucketRegion = objExtStorageSet.strRegion;
            objGetSignedURLWrapper.strLocation = objExtStorageSet.strEndPoint;
            objGetSignedURLWrapper.strFile = '';
            objGetSignedURLWrapper.intExpires = 120000;
            objGetSignedURLWrapper.strFileName = '';
            String strPreSignedURL = PresignedURLGenerator.getSignedURL(objGetSignedURLWrapper);
            response = APIUtility.externalStorageCallout(strPreSignedURL,'GET');
        } catch (Exception exp) {
            ErrorLogger.logException('StorageConfigurationsController.validateConnection', exp);
        }
        return string.valueOf(response.getstatuscode());
    }
}