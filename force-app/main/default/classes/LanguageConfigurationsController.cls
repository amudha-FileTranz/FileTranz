/*
 * Purpose : To control the installLanguage LWC.
 * Author  : Giri
 */
public with sharing class LanguageConfigurationsController {
    /**
     * This method is used to get translations for all custom labels for specific language.
     * @param strLanguage  from languageConfigurations LWC
     * @return String
     */
    @Auraenabled
    public static List<Filetranz_Languages__c> getTranslation(String strLanguage) {
        return [
			SELECT Id, Language__c, Label_Value__c, Label_Name__c,Label_API_Name__c,Language_Code__c
			FROM Filetranz_Languages__c
			WHERE Language_Code__c = :String.escapeSingleQuotes(strLanguage) 
			WITH USER_MODE ORDER BY Id
		];
    }
    
    /**
     * This method is used to import translations for all custom labels for specific language.
     * @param strLanguage  from languageConfigurations LWC
     * @return String
     */
    @Auraenabled
    public static String createTranslation(String strLanguage, List<Filetranz_Languages__c> lstLabelTranslations, Boolean bolFinal) {
        // This deploys org metadata (Custom Label translations) via the Metadata API, authenticated
        // using a session Id captured through SessionIdController/SessionId.page - a pattern AppExchange
        // Security Review scrutinizes closely. It only ever targets this same org's own Metadata API
        // endpoint (never an external host), and is now further restricted to FileTranz admins so an
        // ordinary authenticated user can't trigger a metadata deploy.
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to update language translations.');
        }
        String strUpdateMessage = '';
        try {

            MetadataServiceController.MetadataPort service = MetadataServiceController.createService();
            List<MetadataServiceController.Metadata> lstMetadata = new List<MetadataServiceController.Metadata>();
            String strMessage = '';
            list<string>lststr = new list<string>();
            if(lstLabelTranslations != null && lstLabelTranslations.size() > 0){
                for(Filetranz_Languages__c objLabel : lstLabelTranslations) {
                    MetadataServiceController.CustomLabelTranslation customLabelTranslation = new MetadataServiceController.CustomLabelTranslation();
                    customLabelTranslation.label = objLabel.Label_Value__c;
                    //customLabelTranslation.name = objLabel.Label_API_Name__c;
                    String strLabelName = objLabel.Label_API_Name__c;
                    string strNameSpace = null;
                    String strObjectNameSpace = Filetranz_Languages__c.SObjectType.getDescribe().getName();
                    List<String> lstParts = strObjectNameSpace.split('__');
                    if(lstParts.size() > 2) {
                        strNameSpace = lstParts[0];
                    }
                    if(!String.isBlank(strNameSpace)) {
                        strLabelName = strNameSpace + '__' + strLabelName;
                    }
                    customLabelTranslation.name = strLabelName;
                    lststr.add(strLabelName);
                    
                    MetadataServiceController.Translations objTrans = new MetadataServiceController.Translations();
                    objTrans.customLabels = new MetadataServiceController.CustomLabelTranslation[] { customLabelTranslation };
                    objTrans.fullName = strLanguage;
                    objTrans.type= 'Translations';
                    lstMetadata.add(objTrans);

					System.debug('Translation Object : '+objTrans);
                    List<MetadataServiceController.SaveResult> lstResults = new List<MetadataServiceController.SaveResult>();
                    
                    Integer j = lstLabelTranslations.indexOf(objLabel);
                    lstResults = service.createMetadata(new List<MetadataServiceController.Metadata>{objTrans});
                    if(lstResults!=null && lstResults.size()>0) {
                        strMessage = HandleResultsController.handleSaveResults(lstResults[0]);
                    }
                }
            }
            if (strMessage != Label.Success && strMessage != '' ) {
                strUpdateMessage = Label.Multilangugae_not_updated_please_contact_your_administrator;
                dmlException('HandleResultsController.handleSaveResults', strMessage, null);
            }
        } catch (Exception exp) {
            strUpdateMessage = Label.Multilangugae_not_updated_please_contact_your_administrator;
            dmlException('LanguageConfigurationsController.createTranslation', exp.getMessage(), exp.getStackTraceString());
        }
        return strUpdateMessage;
    }

    
    /**
     * This method is used to import translations for all custom labels in all languages.
     * @param - from languageConfigurations LWC
     * @return List<WrapperLanguage>
     */
    @Auraenabled
    public static List<WrapperLanguage> getAvailableLanguages() {

        List<WrapperLanguage> lstWrapper = new List<WrapperLanguage>();
        List<Multi_Language_Settings__mdt> lstMLMetaData = Multi_Language_Settings__mdt.getAll().values();
        Map<String, Multi_Language_Settings__mdt> mapMetadata = new Map<String, Multi_Language_Settings__mdt>();
        for(Multi_Language_Settings__mdt objMLMetadata : lstMLMetaData) {
            mapMetadata.put(objMLMetadata.Language_Code__c, objMLMetadata);
        }
        Set<String> setInstalledLanguages = new Set<String>();
        for(Configuration__c objConfig : [SELECT Id, Language_Code__c FROM Configuration__c WHERE Is_Installed__c = true WITH USER_MODE]) {
            setInstalledLanguages.add(objConfig.Language_Code__c);
        }
        Set<String> setActiveLanguages = new Set<String>();
        for(Translation objTranslation : [SELECT Id, Language, IsActive FROM Translation WHERE IsActive = TRUE WITH USER_MODE ORDER BY Language]) {
            setActiveLanguages.add(objTranslation.Language);
        }
        // Building the wrapper list
        for(String strLanguageCode : mapMetadata.keySet()) {
            WrapperLanguage objwrapper = new WrapperLanguage();
            objwrapper.strLanguageCode = mapMetadata.get(strLanguageCode).Language_Code__c;
            objwrapper.strLanguageLabel = mapMetadata.get(strLanguageCode).Label;
            objwrapper.isInstalled = setInstalledLanguages.contains(strLanguageCode);
            objwrapper.isActive = setActiveLanguages.contains(strLanguageCode);
            lstWrapper.add(objwrapper);
        }
        return lstWrapper;
        /*
        List<WrapperLanguage> lstWrapper = new List<WrapperLanguage>();
        List<Multi_Language_Settings__mdt> lstMLMetaData = Multi_Language_Settings__mdt.getAll().values();
        Map<String, Multi_Language_Settings__mdt> mapMetadata = new Map<String, Multi_Language_Settings__mdt>();
        for (Multi_Language_Settings__mdt objMLMetadata : lstMLMetaData) {
            mapMetadata.put(objMLMetadata.Language_Code__c, objMLMetadata);
        }
        Set<String> setActiveLanguages = new Set<String>();
        for (Translation objTranslation : [SELECT Id, Language, IsActive FROM Translation WHERE IsActive = TRUE WITH USER_MODE ORDER BY language]) {
            setActiveLanguages.add(objTranslation.Language);
        }
        for (String strLanguageCode : mapMetadata.keySet()) {
            WrapperLanguage objwrapper = new WrapperLanguage();
            objwrapper.strLanguageCode = mapMetadata.get(strLanguageCode).Language_Code__c;
            objwrapper.strLanguageLabel = mapMetadata.get(strLanguageCode).Label;
            objwrapper.isInstalled = mapMetadata.get(strLanguageCode).Is_Installed__c;
            objwrapper.isActive = setActiveLanguages.contains(strLanguageCode) ? true : false;
            lstWrapper.add(objwrapper);
        }
        return lstWrapper;
        */
    }

    
    
    /**
     * This method is used to the Multi_Language_Settings__mdt record of the installed language.
     * @param - from strLanguage LWC
     * @return no
    */
    @Auraenabled
    public static void afterInstallUpdateMdt(String strLanguage){
        try{

            Configuration__c objConfiguration = new Configuration__c();
            objConfiguration.Language_Code__c = strLanguage;
            objConfiguration.Is_Installed__c = true;

            if(!Schema.SObjectType.Configuration__c.isCreateable() || !Schema.SObjectType.Configuration__c.isUpdateable()){
                throw new AuraHandledException('You do not have permission to create or update Configuration records.');
            }
            SObjectAccessDecision objAccessDecision = Security.stripInaccessible(AccessType.UPDATABLE, new List<Configuration__c>{objConfiguration});
            List<Configuration__c> lstConfigurations = (List<Configuration__c>)objAccessDecision.getRecords();

            if(!lstConfigurations.isEmpty() && Schema.SObjectType.Configuration__c.isCreateable() && Schema.SObjectType.Configuration__c.isUpdateable()){
                upsert as User lstConfigurations;
            }
            /*
            Multi_Language_Settings__mdt objMetaData = [
			SELECT Id, Is_Installed__c, Label, DeveloperName,Language_Code__c
			FROM Multi_Language_Settings__mdt
			WHERE Language_Code__c =: String.escapeSingleQuotes(strLanguage)
			WITH USER_MODE
		];
        
        MetadataServiceController.MetadataPort updateMetadataServiceController = MetadataServiceController.createService();
        MetadataServiceController.CustomMetadata objMeta = new MetadataServiceController.CustomMetadata();
        MetadataServiceController.CustomMetadataValue objField = new MetadataServiceController.CustomMetadataValue();
        String strObjNameSpace = Multi_Language_Settings__mdt.SObjectType.getDescribe().getName();
        String strNameSpace;
        List<String> lstParts = strObjNameSpace.split('__');
        if(lstParts.size() > 2) {
            strNameSpace = lstParts[0];
        }
        if(!String.isBlank(strNameSpace)) {
            objMeta.fullName = strNameSpace + '__Multi_Language_Settings__mdt.' + objMetaData.DeveloperName;
            objField.field = strNameSpace + '__Is_Installed__c';
        } else {
            objMeta.fullName = 'Multi_Language_Settings__mdt.' + objMetaData.DeveloperName;
            objField.field = 'Is_Installed__c';
        }
        objMeta.label = objMetaData.Label;
        objField.value = 'true';
        objMeta.values = new List<MetadataServiceController.CustomMetadataValue>();
        
        objMeta.values.add(objField);
        List<MetadataServiceController.SaveResult> lstUpdtaeResult = updateMetadataServiceController.updateMetadata(new List<MetadataServiceController.Metadata>{ objMeta });
        HandleResultsController.handleSaveResults(lstUpdtaeResult[0]);
        */
        }
        Catch(Exception exp){
            dmlException('LanguageConfigurationsController.afterInstallUpdateMdt', exp.getMessage(), exp.getStackTraceString());
        }

    }
    
    
    /**
     * This method is used to create an expection/error records.
     * @param - from strRelatedTo,  exceptionMessage, exceptionStackTrace
     * @return no
     */
    @future
    public static void dmlException(String strRelatedTo, String exceptionMessage,  String exceptionStackTrace){
        Exception_Error__c objError = new Exception_Error__c();
        objError.Related_To__c = strRelatedTo;
        objError.StackTraceString__c = exceptionStackTrace;
        objError.Exception_Message__c = exceptionMessage;
        if(Schema.sObjectType.Exception_Error__c.isCreateable()){
            Database.insert(objError, false);
        }
    }
    
    // Wrapper object to send the session details to clients
    public class wrapperLanguage {
        @AuraEnabled
        public String strLanguageLabel { get; set; }
        @AuraEnabled
        public String strLanguageCode { get; set; }
        @AuraEnabled
        public Boolean isInstalled { get; set; }
        @AuraEnabled
        public Boolean isActive { get; set; }
    }
    
}