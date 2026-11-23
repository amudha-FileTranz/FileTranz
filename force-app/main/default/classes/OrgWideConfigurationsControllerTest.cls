/*
 * Purpose : Test class for OrgWideConfigurationsController class.
 * Author  : Giri
 */
@isTest
public class OrgWideConfigurationsControllerTest {
    @TestSetup
    static void createTestData(){
		// Configuration__c test data	
		List<Configuration__c> lstConfigurations = new List<Configuration__c>();
        Configuration__c objConfiguration = new Configuration__c();
        objConfiguration.Configuration_Name__c = 'Clear_Recycle_Bin';
        objConfiguration.Long_Value__c = '1';
        objConfiguration.Configuration_Type__c = 'File Configuration';
        lstConfigurations.add(objConfiguration);
        Configuration__c objConfiguration1 = new Configuration__c();
        objConfiguration1.Configuration_Name__c = 'Recycle_Bin';
        objConfiguration1.Long_Value__c = 'true';
        objConfiguration1.Configuration_Type__c = 'File Configuration';
        lstConfigurations.add(objConfiguration1);
        Configuration__c objConfiguration2 = new Configuration__c();
        objConfiguration2.Configuration_Name__c = 'Recycle_Bin';
        objConfiguration2.Long_Value__c = 'false';
        objConfiguration2.Configuration_Type__c = 'File Configuration';
        lstConfigurations.add(objConfiguration2);
        Configuration__c objConfiguration3 = new Configuration__c();
        objConfiguration3.Configuration_Name__c = 'Clear_Recycle_Bin_In';
        objConfiguration3.Long_Value__c = '1';
        objConfiguration3.Configuration_Type__c = 'File Configuration';
        lstConfigurations.add(objConfiguration3);
        if(Schema.SobjectType.Configuration__c.isCreateable()){
            insert lstConfigurations;
        }
        // Ensure the user running these tests is recognized as a FileTranz admin, since
        // OrgWideConfigurationsController.updateConfigurations now gates on CommonUtilities.isFileTranzAdmin().
        assignPermissionSetIfMissing(UserInfo.getUserId(), 'FileTranz_Admin');
    }

    private static void assignPermissionSetIfMissing(Id userId, String permissionSetName) {
        PermissionSet objPS = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1];
        List<PermissionSetAssignment> lstExisting = [
            SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSetId = :objPS.Id
        ];
        if (lstExisting.isEmpty() && Schema.sObjectType.PermissionSetAssignment.isCreateable()) {
            insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = objPS.Id);
        }
    }

    // Test: getConfigurations method
    @isTest
    public static void orgWideConfigurationsControllerTestMethod1(){
        Test.startTest();
        Map<String, String> mapConfiguration = OrgWideConfigurationsController.getConfigurations();
        Assert.isTrue(mapConfiguration.get('Clear_Recycle_Bin') == '1','True');
        Test.stopTest();
    }

    // Test: updateConfigurations method
    @isTest
    public static void orgWideConfigurationsControllerTestMethod2(){
        List<Object> lstObject = new List<Object>();
        Map<Object, Object> mapObj = new Map<Object, Object>();
        mapObj.put((Object)'key', 'Recycle_Bin');
        mapObj.put((Object)'value', 'true');
        lstObject.add(mapObj);
        List<Object> lstObject1 = new List<Object>();
        Map<Object, Object> mapObj1 = new Map<Object, Object>();
        mapObj1.put((Object)'key', 'Recycle_Bin');
        mapObj1.put((Object)'value', 'false');
        lstObject1.add(mapObj1);
        Test.startTest();
        // To cover updateConfigurations method
        String strResult = OrgWideConfigurationsController.updateConfigurations(lstObject);
        Assert.isTrue(strResult == 'Success', 'True');
        String strResult1 = OrgWideConfigurationsController.updateConfigurations(lstObject1);
        Assert.isTrue(strResult1 == 'Success', 'True');
        String strResult2 = OrgWideConfigurationsController.updateConfigurations(null);
        Assert.isTrue(strResult == 'Success', 'True');
        Test.stopTest();
    }
}