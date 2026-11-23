/*
 *
 * Purpose : This class is used to handle the configuration limits based on the custom metadata type records.
 * Author  : John Prabhu
 *
*/
public with sharing class ConfigurationLimits {
    
    // This method is used to check the feature availability based on the org edition.
    public static Boolean isFeatureAvailable(String strFeatureName) {
        FileTranz_Configurations__mdt objLimits = FileTranz_Configurations__mdt.getInstance(strFeatureName);
        if (objLimits != null && objLimits.Enabled__c) {
            return false;
        }
        return true;
    }
    
    // This method is used to handle the file limits based configuration.
    public static Boolean getFileSizeLimits(String strFeatureName) {
        FileTranz_Configurations__mdt objLimits = FileTranz_Configurations__mdt.getInstance(strFeatureName);
       if (objLimits != null && objLimits.Enabled__c) {
            return true;
        }
        return false;
    }
}