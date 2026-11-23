/*
 * Purpose : Test class for PostInstallClass class
 * Author  : Anandh
 */
@isTest
public class PostInstallClassTest {
    @isTest
    static void testInstallScript() {
        PostInstallClass objPostInstallClass = new PostInstallClass();
        Test.testInstall(objPostInstallClass, null);
        List<Configuration__c> lstConfigurations = [SELECT Id FROM Configuration__c];
        System.assertEquals(13, lstConfigurations.size(), 'Configurations not found');
    }

    @isTest
    static void testInstallScriptIsIdempotentOnReinstall() {
        // Simulates an uninstall/reinstall cycle, where Salesforce re-invokes onInstall with
        // previousVersion() == null again. Must not duplicate the seeded Configuration__c rows.
        PostInstallClass objPostInstallClass = new PostInstallClass();
        Test.testInstall(objPostInstallClass, null);
        Test.testInstall(objPostInstallClass, null);
        List<Configuration__c> lstConfigurations = [SELECT Id, Configuration_Name__c FROM Configuration__c];
        System.assertEquals(13, lstConfigurations.size(), 'Reinstall must not duplicate default configuration rows');
    }
}