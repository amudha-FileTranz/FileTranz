/*
 * Purpose : To control the behaviour of uploadFiles LWC
 * Author  : Anandh
 */
public with sharing class OrgWideConfigurationsController {
    /**
     * To get configuration details.
     * @param from configurationSettings, uploadViewFiles, jobConfigurations LWC
     * @return Map<String, String>
     */
    @AuraEnabled
    public static Map<String, String> getConfigurations(){
        Map<String, String> mapConfiguration = new Map<String, String>();
        for(Configuration__c objConfig: [SELECT Configuration_Name__c, Long_Value__c FROM Configuration__c WHERE Configuration_Name__c != null WITH USER_MODE]){
            String strLongValue = objConfig.Long_Value__c == null ? '' : objConfig.Long_Value__c;
            mapConfiguration.put(objConfig.Configuration_Name__c, strLongValue);
        }
        return mapConfiguration;
    }
    
    /**
     * To update configuration details.
     * @param from configurationSettings LWC
     * @return String
     */
    @AuraEnabled
    public static String updateConfigurations(List<Object> lstConfiguration){
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to update org wide configurations.');
        }
        String strResult = '';
        try{
            Map<String, Configuration__c> mapConfiguration = new Map<String, Configuration__c>();
            List<Configuration__c> lstConfigUpdate = new List<Configuration__c>();
            Configuration__c objRecycleConfig = new  Configuration__c ();
            for(Configuration__c objConfigSetting : [SELECT Configuration_Name__c, Long_Value__c FROM Configuration__c WHERE Configuration_Name__c != null WITH USER_MODE]){
                mapConfiguration.put(objConfigSetting.Configuration_Name__c, objConfigSetting);
            }
            for(Object obj : lstConfiguration){
                Map<Object, Object> mapObj = (Map<Object, Object>) obj;
                Configuration__c objConfigs = mapConfiguration.get(String.valueof(mapObj.get('key')));
                objConfigs.Long_Value__c = String.valueof(mapObj.get('value'));
                if(objConfigs.Configuration_Name__c == 'Recycle_Bin'){
                    objRecycleConfig = objConfigs;
                }
                lstConfigUpdate.add(objConfigs);  
            }

            if(!Schema.SObjectType.Configuration__c.isUpdateable()){
                throw new AuraHandledException('You do not have permission to update Configuration records.');
            }
            SObjectAccessDecision objAccessDecision = Security.stripInaccessible(AccessType.UPDATABLE, lstConfigUpdate);
            List<Configuration__c> lstConfigUpdateable = (List<Configuration__c>)objAccessDecision.getRecords(); 

            if(!lstConfigUpdateable.isEmpty()){
                update as User lstConfigUpdateable;
            }
            handleRecycleBinConfiguration(objRecycleConfig, lstConfigUpdateable);
            strResult = Label.Success;
        } catch (Exception exp) {
            ErrorLogger.logException('OrgWideConfigurationsController.updateConfigurations', exp);
            strResult = 'Error';
        }
        return strResult;
    }

    // This method is added to check the edition based permission for Recycle Bin feature.    
    @AuraEnabled(cacheable=true)
    public static Boolean isRecycleBinAllowed() {
        return ConfigurationLimits.isFeatureAvailable('Block_Recycle_Bin');
    }

    // This method is added in order to get the file size limits based on org edition.
    @AuraEnabled(cacheable=true)
    public static Boolean setFileSizeLimits() {
        return ConfigurationLimits.getFileSizeLimits('Set_Maximum_File_Size');
    }

    // This method is used to set the maximum file upload limits based on org edition.
    @AuraEnabled(cacheable=true)
    public static Boolean setFileUploadLimits() {
        return ConfigurationLimits.getFileSizeLimits('Set_Maximum_Upload_Count');
    }

    
    private static void handleRecycleBinConfiguration(Configuration__c objRecycleConfig, List<Configuration__c> lstConfigUpdateable){
        List<CronTrigger> lstCronTrigger = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = 'FT_ClearRecycleBin' WITH USER_MODE];
        if(objRecycleConfig != null && objRecycleConfig.Configuration_Name__c == 'Recycle_Bin' && objRecycleConfig.Long_Value__c == 'true' && lstCronTrigger.size()==0){
            if(lstConfigUpdateable.size() > 0  && Schema.SobjectType.Configuration__c.isupdateable()){
                update as User lstConfigUpdateable;
                System.schedule('FT_ClearRecycleBin', ' 0 0 0 ? * * *', new EmptyRecycleBinBatchScheduler());
            }
        } else if(objRecycleConfig != null && objRecycleConfig.Configuration_Name__c == 'Recycle_Bin' && objRecycleConfig.Long_Value__c == 'false' && lstCronTrigger.size()>0){
            if(lstConfigUpdateable.Size() > 0 && Schema.SobjectType.Configuration__c.isupdateable()){
                update as User lstConfigUpdateable;
            }
            Id batchJobId = Database.executeBatch(new EmptyRecycleBinBatch(), 200);
            System.abortJob(lstCronTrigger[0].Id);
        }
    }
}