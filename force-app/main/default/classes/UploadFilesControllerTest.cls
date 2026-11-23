/*
 * Purpose : Test class for UploadFilesController class.
 * Author  : Anandhakumar Thangasamy
 */
@IsTest
public class UploadFilesControllerTest {
    @TestSetup
    static void createTestData() {
        //Account test data
        Account objAccount = new Account(Name = 'Test Account');
        if(Schema.SobjectType.Account.isCreateable()){
            insert ObjAccount;
        }
        // Configuration__c test data
        Configuration__c objConfig = new Configuration__c();
        objConfig.Configuration_Name__c = 'Log_Activity';
        objConfig.Configuration_Type__c = 'File Configuration';
        objConfig.Long_Value__c = 'Upload,Download,Delete';
        if(Schema.SobjectType.Configuration__c.isCreateable()){
            insert objConfig;
        }
        // External_Storage_Settings__c test data
        External_Storage_Settings__c objESS = new External_Storage_Settings__c();
        objESS.Access_Key__c = '123456789';
        objESS.Secret_Key__c = '123456789';
        objESS.Bucket__c = 'fileTranz';
        objESS.Region__c = 'uswest';
        objESS.File_Retrieve_URL__c = 'fileTranz/uswest/sample.png';
        objESS.Name = 'Sample';
        objESS.Expiration_Time__c = 12000;
        objESS.Storage__c = 's3';
        objESS.Active__c = true;
        if(Schema.SobjectType.External_Storage_Settings__c.isCreateable()){
            insert objESS;
        }
        
        //External_Files__c Test data
        List<External_Files__c> lstEF = new List<External_Files__c>();
        External_Files__c objEF1 = new External_Files__c();
        objEF1.File_Type__c = 'txt';
        objEF1.File_Name__c = 'Test File 1';
        objEF1.File_Id__c = '123456789012345678';
        objEF1.UID__c = '123456789012345678';
        objEF1.Record_Type__c = 'Files';
        objEF1.Uploaded_From__c = 'FileTranz';
        lstEF.add(objEF1);
        
        // External_Files__c Test data
        External_Files__c objEF2 = new External_Files__c();
        objEF2.File_Type__c = 'txt';
        objEF2.File_Name__c = 'Test File 2';
        objEF2.File_Id__c = '123456789012345679';
        objEF2.UID__c = '123456789012345679';
        objEF2.Record_Type__c = 'Files';
        objEF2.Uploaded_From__c = 'FileTranz';
        lstEF.add(objEF2);
        if(Schema.SobjectType.External_Files__c.isCreateable()){
            insert lstEF;
        }
        
        // External_File_Version__c Test data
        External_File_Version__c objEFV = new External_File_Version__c();
        objEFV.External_Files__c = lstEF[0].Id;
        objEFV.Is_Latest__c = true;
        objEFV.Version_Number__c = 1;
        objEFV.Size__c = '1 KB';
        objEFV.Size_Bytes__c = 30000;
        objEFV.File_Location_URL__c = 'https://sfdc-filetranz.s3.eu-north-1.amazonaws.com/0015i00000o2KjGAAU/test.txt';
        if(Schema.SobjectType.External_File_Version__c.isCreateable()){
            insert objEFV;
        }
        
        // External_File_Link__c Test data
        External_File_Link__c objEFL = new External_File_Link__c();
        objEFL.Object_Type__c = 'Account';
        objEFL.External_Files__c = lstEF[0].Id;
        objEFL.Related_To__c = ObjAccount.Id;
        if(Schema.SobjectType.External_File_Link__c.isCreateable()){
            insert objEFL;
        }
    }

    // Test Method to cover the UploadFilesController class
    @isTest
    static void uploadFilesControllerTestMethod() {
        List<Account> lstAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'  WITH USER_MODE LIMIT 1];
        Test.startTest();
        // To cover the createExternalFileLinks method
        UploadFilesController.ExternalFilesWrapper objWrapper = new UploadFilesController.ExternalFilesWrapper();
        objWrapper.Id = [SELECT Id FROM External_Files__c WITH USER_MODE][0].Id;
        objWrapper.length = '2343';
        objWrapper.size = '34';
        objWrapper.type = 'txt';
        objWrapper.bolExistingFile = 'true';
        objWrapper.name = 'text';
        String strMessage = UploadFilesController.createExternalFiles('Test', lstAccount[0].Id, '123456');
        System.assertEquals('Success', strMessage, 'The method should return Success');
        Boolean bolResultEF = UploadFilesController.createExternalFileLinks(new List<UploadFilesController.ExternalFilesWrapper>{objWrapper}, String.valueOf(lstAccount[0].Id));
        System.assertEquals(true, bolResultEF, 'The method should return true');
        Boolean bolResultEF1 = UploadFilesController.createExternalFileLinks(null, String.valueOf(lstAccount[0].Id));
        List<CommonUtilities.ExternalFilesWrapper> lstExternalFilesWrapper = UploadFilesController.retrieveRelatedExternalFiles(lstAccount[0].Id);
        Assert.isNotNull(lstExternalFilesWrapper, 'Error in retrieveRelatedExternalFiles method.');
        Test.stopTest();
    }
    
    @isTest
    static void uploadFilesControllerTestgenerateAuthHeaderForMultipart() {
        List<Account> lstAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' WITH USER_MODE LIMIT 1];
        Test.startTest();
        String strAmzDate = DateTime.now().formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
        UploadFilesController.GenerateAuthHeaderForAWSWrapper objgenerateAuthHeaderForAWS=new  UploadFilesController.GenerateAuthHeaderForAWSWrapper();
        objgenerateAuthHeaderForAWS.strMethod='POST';
        objgenerateAuthHeaderForAWS.strRecordId=lstAccount[0].Id;
        objgenerateAuthHeaderForAWS.strFileName='Test';
        objgenerateAuthHeaderForAWS.strContentType='application/pdf';
        objgenerateAuthHeaderForAWS.strAmzDate=strAmzDate;
        objgenerateAuthHeaderForAWS.strUploadId=null;
        objgenerateAuthHeaderForAWS.intTotalParts=null;
        objgenerateAuthHeaderForAWS.intPartNumber=null;
        
        // Initiate request
        String strAuthHeaderInitiate = UploadFilesController.generateAuthHeaderForAWS(JSON.serialize(objgenerateAuthHeaderForAWS));
        Assert.isNotNull(strAuthHeaderInitiate, 'Error in AuthHeader creation in generateAuthHeaderForMultipart method.');
        // Upload part request
        UploadFilesController.GenerateAuthHeaderForAWSWrapper objgenerateAuthHeaderForAWSPut=new  UploadFilesController.GenerateAuthHeaderForAWSWrapper();
        objgenerateAuthHeaderForAWSPut.strMethod='PUT';
        objgenerateAuthHeaderForAWSPut.strRecordId=lstAccount[0].Id;
        objgenerateAuthHeaderForAWSPut.strFileName='Test';
        objgenerateAuthHeaderForAWSPut.strContentType='application/pdf';
        objgenerateAuthHeaderForAWSPut.strAmzDate=strAmzDate;
        objgenerateAuthHeaderForAWSPut.strUploadId='1234_Test_Upload_Id';
        objgenerateAuthHeaderForAWSPut.intTotalParts=1;
        objgenerateAuthHeaderForAWSPut.intPartNumber=5;
        String strAuthHeaderPartUpload = UploadFilesController.generateAuthHeaderForAWS(JSON.serialize(objgenerateAuthHeaderForAWSPut));
        Assert.isNotNull(strAuthHeaderPartUpload, 'Error in AuthHeader creation in generateAuthHeaderForMultipart method.');
        // Complete part request
        UploadFilesController.GenerateAuthHeaderForAWSWrapper objgenerateAuthHeaderForAWSPOST=new  UploadFilesController.GenerateAuthHeaderForAWSWrapper();
        objgenerateAuthHeaderForAWSPOST.strMethod='POST';
        objgenerateAuthHeaderForAWSPOST.strRecordId=lstAccount[0].Id;
        objgenerateAuthHeaderForAWSPOST.strFileName='Test';
        objgenerateAuthHeaderForAWSPOST.strContentType='application/pdf';
        objgenerateAuthHeaderForAWSPOST.strAmzDate=strAmzDate;
        objgenerateAuthHeaderForAWSPOST.strUploadId='1234_Test_Upload_Id';
        objgenerateAuthHeaderForAWSPOST.intTotalParts=null;
        objgenerateAuthHeaderForAWSPOST.intPartNumber=5;
        String strAuthHeaderComplete = UploadFilesController.generateAuthHeaderForAWS(JSON.serialize(objgenerateAuthHeaderForAWSPOST));
        Assert.isNotNull(strAuthHeaderComplete, 'Error in AuthHeader creation in generateAuthHeaderForMultipart method.');
        // Create external files
        String strMessage = UploadFilesController.createExternalFiles('Test', lstAccount[0].Id, '10241024');
        String strMessage1 = UploadFilesController.createExternalFiles('Test', null, null);
        System.assertEquals('Success', strMessage, 'The method should return Success');
        // Abort request
        UploadFilesController.GenerateAuthHeaderForAWSWrapper objgenerateAuthHeaderForAWSDELETE=new  UploadFilesController.GenerateAuthHeaderForAWSWrapper();
        objgenerateAuthHeaderForAWSDELETE.strMethod='DELETE';
        objgenerateAuthHeaderForAWSDELETE.strRecordId=lstAccount[0].Id;
        objgenerateAuthHeaderForAWSDELETE.strFileName='Test';
        objgenerateAuthHeaderForAWSDELETE.strContentType='application/pdf';
        objgenerateAuthHeaderForAWSDELETE.strAmzDate=strAmzDate;
        objgenerateAuthHeaderForAWSDELETE.strUploadId='1234_Test_Upload_Id';
        objgenerateAuthHeaderForAWSDELETE.intTotalParts=null;
        objgenerateAuthHeaderForAWSDELETE.intPartNumber=null;
        String strAuthHeaderAbort = UploadFilesController.generateAuthHeaderForAWS(JSON.serialize(objgenerateAuthHeaderForAWSDELETE));
        Assert.isNotNull(strAuthHeaderAbort, 'Error in AuthHeader creation in generateAuthHeaderForMultipart method.');
        UploadFilesController.GenerateAuthHeaderForAWSWrapper objgenerateAuthHeaderForAWSnull=new  UploadFilesController.GenerateAuthHeaderForAWSWrapper();
        objgenerateAuthHeaderForAWSnull.strMethod=null;
        objgenerateAuthHeaderForAWSnull.strRecordId=null;
        objgenerateAuthHeaderForAWSnull.strFileName=null;
        objgenerateAuthHeaderForAWSnull.strContentType='application/pdf';
        objgenerateAuthHeaderForAWSnull.strAmzDate=null;
        objgenerateAuthHeaderForAWSnull.strUploadId='Exception';
        objgenerateAuthHeaderForAWSnull.intTotalParts=null;
        objgenerateAuthHeaderForAWSnull.intPartNumber=null;
        String strAuthHeaderException = UploadFilesController.generateAuthHeaderForAWS(JSON.serialize(objgenerateAuthHeaderForAWSnull));
        Test.stopTest();
    }
}