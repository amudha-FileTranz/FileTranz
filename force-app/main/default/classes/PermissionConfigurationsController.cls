/*
 * Purpose : To controll the configuration of profile/user level settings
 * Author  : Giri
 */
public with sharing class PermissionConfigurationsController {
    /**
     * To get permission sets which are not have the permission assignments already
     * @param - from permissionConfigurations LWC
     * @return List<PermissionSet>
     */
    @AuraEnabled
    public static List<PermissionSet> getPermissionSets() {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to view permission configurations.');
        }
        try {
            List<Configuration__c> lstConfiguration = [SELECT Id, Configuration_Name__c FROM Configuration__c WHERE Configuration_Type__c = 'Permission Configuration' AND Configuration_Name__c != 'OWD' WITH USER_MODE];
            Set<String> setConfiguredPSids = new Set<String>();
            for (Configuration__c objConfiguration : lstConfiguration) {
                setConfiguredPSids.add(objConfiguration.Configuration_Name__c);
            }
            return [SELECT Id, Label FROM PermissionSet WHERE ProfileId = NULL AND Id NOT IN :setConfiguredPSids WITH USER_MODE];
        } catch (Exception exp) {
            ErrorLogger.logException('PermissionConfigurationsController.savePermissions', exp);
            return null;
        }
    }
    
    /**
     * To create new Configuration__c
     * @param lstPSids from permissionConfigurations LWC
     * @param strAccess from permissionConfigurations LWC
     * @return Boolean
     */
    @AuraEnabled
    public static Boolean savePermissions(List<String> lstPSids, String strAccess) {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to save permission configurations.');
        }
        Set<String> setPSids = new Set<String>(lstPSids);
        List<Configuration__c> lstConfiguration = new List<Configuration__c>();
        for (String strPSid : setPSids) {
            if(Configuration__c.SobjectType.getDescribe().isAccessible()){
                Configuration__c objConfiguration = new Configuration__c();
                objConfiguration.Configuration_Type__c = 'Permission Configuration';
                objConfiguration.Configuration_Name__c = strPSid;
                objConfiguration.Long_Value__c = strAccess;
                lstConfiguration.add(objConfiguration);
            }
        }
        try {
            if(lstConfiguration == null || lstConfiguration.isEmpty()){
                return false;
            } 
            if (!lstConfiguration.isEmpty() && Schema.SObjectType.Configuration__c.isCreateable()) {
                insert as User lstConfiguration;
            }
            return true;
        } catch (Exception exp) {
            ErrorLogger.logException('PermissionConfigurationsController.savePermissions', exp);
            return false;
        }
    }
    
    /**
     * To get Configuration__c details that already created
     * @return List<ConfigurationWrapper>
     */
    @AuraEnabled
    public static List<ConfigurationWrapper> getPermissionConfigurations() {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to view permission configurations.');
        }
        List<ConfigurationWrapper> lstConfigurationWrapper = new List<ConfigurationWrapper>();
        Map<Id, PermissionSet> mapPS = new Map<Id, PermissionSet>([SELECT Id, Label FROM PermissionSet WITH USER_MODE LIMIT 200]);
        try {
            for (Configuration__c objConfig : [SELECT Id, Configuration_Name__c, Long_Value__c FROM Configuration__c WHERE Configuration_Type__c = 'Permission Configuration' AND Configuration_Name__c != 'OWD' WITH USER_MODE]) {
                List<String> lstAccess = objConfig.Long_Value__c != null ? objConfig.Long_Value__c.split('; ') : new List<String>();
                ConfigurationWrapper objConfigWrapper = new ConfigurationWrapper();
                objConfigWrapper.idConfiguration = objConfig.Id;
                objConfigWrapper.strPSname = mapPS.get(objConfig.Configuration_Name__c) != null ? mapPS.get(objConfig.Configuration_Name__c).Label : '';
                objConfigWrapper.bolUpload = lstAccess.contains('Upload');
                objConfigWrapper.bolDownload = lstAccess.contains('Download');
                objConfigWrapper.bolEdit = lstAccess.contains('Edit');
                objConfigWrapper.bolDelete = lstAccess.contains('Delete');
                objConfigWrapper.bolPreview = lstAccess.contains('Preview');
                objConfigWrapper.bolView = lstAccess.contains('View');
                objConfigWrapper.bolSelect = false;
                objConfigWrapper.bolEditable = true;
                lstConfigurationWrapper.add(objConfigWrapper);
            }
        } catch (Exception exp) {
            ErrorLogger.logException('PermissionConfigurationsController.getPermissionConfigurations', exp);
        }
        return lstConfigurationWrapper;
    }
    
    /**
     * To delete Configuration__c record(s)
     * @param lstConfigurationIds from permissionConfigurations LWC
     * @return boolean
     */
    
    @AuraEnabled
    public static Boolean deleteConfigurations(List<String> lstConfigurationIds) {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to delete permission configurations.');
        }
        try {
            Set<String> setSelectedIds = new Set<String>(lstConfigurationIds);
            for(String objStrIds: setSelectedIds){
                setSelectedIds.add(String.escapeSingleQuotes(objStrIds));
            }
            List<Configuration__c> lstConfiguration = [SELECT Id FROM Configuration__c WHERE Id = :setSelectedIds WITH USER_MODE];
            
            if(!Schema.SObjectType.Configuration__c.isDeletable()){
                throw new AuraHandledException('You do not have permission to delete Configuration records.');
            }
            
            if (lstConfiguration != null && !lstConfiguration.isEmpty()) {
                delete as User lstConfiguration;
            }
            return true;
        } catch (Exception exp) {
            ErrorLogger.logException('PermissionConfigurationsController.deleteConfigurations', exp);
            return false;
        }
    }
    
    /**
     * To update Configuration__c record
     * @param objConfiguration from permissionConfigurations LWC
     * @return boolean
     */
    @AuraEnabled
    public static Boolean updateConfiguration(List<ConfigurationWrapper> lstConfigurationWrappers) {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to update permission configurations.');
        }
        List<Configuration__c> lstConfigurations = new List<Configuration__c>();
        try {
            for (ConfigurationWrapper objConfigWrapper : lstConfigurationWrappers) {
                String strAccess = getAccess(objConfigWrapper);
                Configuration__c objConfig = new Configuration__c();
                objConfig.id = objConfigWrapper.idConfiguration;
                objConfig.Long_Value__c = strAccess.substring(0, strAccess.length() - 2);
                lstConfigurations.add(objConfig);
            }
            
            if(!Schema.SObjectType.Configuration__c.isUpdateable()){
                throw new AuraHandledException('You do not have permission to update Configuration records.');
            }
            SObjectAccessDecision objAccessDecision = Security.stripInaccessible(AccessType.UPDATABLE, lstConfigurations);
            List<Configuration__c> lstConfigUpdateable = (List<Configuration__c>)objAccessDecision.getRecords();
            
            if (!lstConfigUpdateable.isEmpty()) {
                update as User lstConfigUpdateable;
            }
            return true;
        } catch (Exception exp) {
            ErrorLogger.logException('PermissionConfigurationsController.updateConfiguration', exp);
            return false;
        }
    }
    
    private static String getAccess(ConfigurationWrapper objConfigWrapper){
        return (objConfigWrapper.bolUpload ? 'Upload; ' : '') +
            (objConfigWrapper.bolView ? 'View; ' : '') +
            (objConfigWrapper.bolDownload ? 'Download; ' : '') +
            (objConfigWrapper.bolEdit ? 'Edit; ' : '') +
            (objConfigWrapper.bolDelete ? 'Delete; ' : '') +
            (objConfigWrapper.bolPreview ? 'Preview; ' : '');
    }
    
    public class ConfigurationWrapper {
        @AuraEnabled
        public Id idConfiguration { get; set; }
        @AuraEnabled
        public String strPSname { get; set; }
        @AuraEnabled
        public Boolean bolUpload { get; set; }
        @AuraEnabled
        public Boolean bolDownload { get; set; }
        @AuraEnabled
        public Boolean bolEdit { get; set; }
        @AuraEnabled
        public Boolean bolDelete { get; set; }
        @AuraEnabled
        public Boolean bolPreview { get; set; }
        @AuraEnabled
        public Boolean bolView { get; set; }
        @AuraEnabled
        public Boolean bolSelect { get; set; }
        @AuraEnabled
        public Boolean bolEditable { get; set; }
    }
}