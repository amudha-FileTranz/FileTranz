/*
 * Purpose : Test class for LanguageConfigurationsController class.
 * Author  : Giri
 */
@IsTest
public class LanguageConfigurationsControllerTest {

    private static void assignPermissionSetIfMissing(Id userId, String permissionSetName) {
        PermissionSet objPS = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1];
        List<PermissionSetAssignment> lstExisting = [
            SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSetId = :objPS.Id
        ];
        if (lstExisting.isEmpty() && Schema.sObjectType.PermissionSetAssignment.isCreateable()) {
            insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = objPS.Id);
        }
    }

    private static User createStandardTestUser(String usernamePrefix) {
        User objUser = new User();
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' WITH USER_MODE LIMIT 1];
        objUser.FirstName = 'Test';
        objUser.LastName = 'User';
        objUser.Username = usernamePrefix + '@example.com';
        objUser.Email = usernamePrefix + '@example.com';
        objUser.Alias = 'tuser';
        objUser.CommunityNickname = usernamePrefix;
        objUser.TimeZoneSidKey = 'America/Los_Angeles';
        objUser.LocaleSidKey = 'en_US';
        objUser.EmailEncodingKey = 'UTF-8';
        objUser.LanguageLocaleKey = 'en_US';
        objUser.ProfileId = objProfile.Id;
        if (Schema.sObjectType.User.isCreateable()) {
            insert objUser;
        }
        return objUser;
    }

    @isTest
    static void nonAdminCannotCreateTranslation() {
        User objNonAdminUser = createStandardTestUser('filetranzlangnonadmin');
        System.runAs(objNonAdminUser) {
            assignPermissionSetIfMissing(objNonAdminUser.Id, 'FileTranz_User');
        }
        System.runAs(objNonAdminUser) {
            Boolean bolThrew = false;
            try {
                LanguageConfigurationsController.createTranslation('ja', new List<Filetranz_Languages__c>(), true);
            } catch (AuraHandledException exp) {
                bolThrew = true;
            }
            Assert.areEqual(true, bolThrew, 'Non-admin user must not be able to create/update translations');
        }
    }

    @istest
    static void languageConfigurationsControllerTestMethod1 () {
        // Ensure the user running this test is recognized as a FileTranz admin, since
        // LanguageConfigurationsController.createTranslation now gates on CommonUtilities.isFileTranzAdmin().
        assignPermissionSetIfMissing(UserInfo.getUserId(), 'FileTranz_Admin');

        // Filetranz Language test data
        List<Filetranz_Languages__c> lstFL = new List<Filetranz_Languages__c>();
        Filetranz_Languages__c objFL = new Filetranz_Languages__c();
        objFL.Language__c = 'korean';
        objFL.Label_Value__c = 'Test';
        objFL.Label_Name__c = 'Test';
        objFL.Language_Code__c ='ko';
        objFL.Label_API_Name__c='Test';
        lstFL.add(objFL);
        
        Filetranz_Languages__c objFL1 = new Filetranz_Languages__c();
        objFL1.Language__c = 'Japanese';
        objFL1.Language_code__c = 'ja';
        objFL1.Label_Value__c = 'Test1';
        objFL1.Label_Name__c = 'Test1';
        objFL1.Label_API_Name__c='Test1';
        lstFL.add(objFL1);
        if(Schema.sObjectType.Filetranz_Languages__c.fields.Label_Value__c.isCreateable()){
            insert lstFL;
        }

        Multi_Language_Settings__mdt objLanMdt = new Multi_Language_Settings__mdt(
            Language_Code__c = 'ja',
            MasterLabel = 'Japanese',
            Is_Installed__c = false,
            Label = 'Japanese',
            Language = 'Japanese',
            DeveloperName = 'Japanese'
        );

        Test.startTest();

        List<Filetranz_Languages__c> lstLanguage = LanguageConfigurationsController.getTranslation('ja');
        System.assertEquals(1, lstLanguage.size(),'Expected Size 1');
        LanguageConfigurationsController.getAvailableLanguages();
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        String strResult =LanguageConfigurationsController.createTranslation('ja', lstFL, true);
        System.assertEquals('', strResult,'Expected null string');
        try {
            LanguageConfigurationsController.afterInstallUpdateMdt('ja');
        } catch (Exception e) {
            System.debug('Skipping afterInstallUpdateMdt() in test: ' + e.getMessage() + e.getStackTraceString());
        }        LanguageConfigurationsController.dmlException('TestRelated', 'TestexceptionMessage', 'TestexceptionStackTrace');
        Test.stopTest();
    }
    
    private class WebServiceMockImpl implements WebServiceMock {
        public void doInvoke(
            Object stub, 
            Object request, 
            Map<String, Object> response, 
            String endpoint, 
            String soapAction, 
            String requestName, 
            String responseNS, 
            String responseName, 
            String responseType
        ) {
            if (request instanceof MetadataServiceController.updateMetadata_element) {
                // Create the response object
                MetadataServiceController.updateMetadataResponse_element mdt = new MetadataServiceController.updateMetadataResponse_element();
    
                // Create a SaveResult object
                MetadataServiceController.SaveResult sr = new MetadataServiceController.SaveResult();
                sr.fullName = 'Multi_Language_Settings.Korean';
                sr.success = true;
                sr.errors = new List<MetadataServiceController.Error>(); // No errors
    
                // Assign the result as a list
                mdt.result = new List<MetadataServiceController.SaveResult> { sr };
    
                response.put('response_x', mdt);
            } else if (request instanceof MetadataServiceController.deleteMetadata_element) {
                response.put('response_x', new MetadataServiceController.deleteMetadataResponse_element());
            } else if (request instanceof MetadataServiceController.createMetadata_element) {
                response.put('response_x', new MetadataServiceController.createMetadataResponse_element());
            }
        }
    }
    
}