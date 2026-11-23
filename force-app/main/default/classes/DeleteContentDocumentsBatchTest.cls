@isTest
public class DeleteContentDocumentsBatchTest {
    @testSetup
    static void createTestData() {
        // Account test data
        Account objAcc = new Account(Name = 'Test Account'+datetime.now());
        if (Schema.SObjectType.Account.isCreateable()) {
            insert objAcc;
        }
        // ContentVersion test data
        List<ContentVersion> lstContentVersion = new List<ContentVersion>();
        ContentVersion objCV = new ContentVersion();
        objCV.Title = 'Test Document';
        objCV.PathOnClient = 'TestDocument.pdf';
        objCV.VersionData = Blob.valueOf('Test Content');
        objCV.IsMajorVersion = true;
        lstContentVersion.add(objCV);
        ContentVersion objCV1 = new ContentVersion();
        objCV1.Title = 'Test Document1';
        objCV1.PathOnClient = 'TestDocument1.pdf';
        objCV1.VersionData = Blob.valueOf('Test Content1');
        objCV1.IsMajorVersion = true;
        lstContentVersion.add(objCV1);
        if (Schema.SObjectType.ContentVersion.isCreateable()) {
            insert lstContentVersion;
        }
    }
    
    @isTest
    static void testBatchExecution() {
        Set<Id> setContentDocId = new Set<Id>();
        for (ContentDocument doc : [SELECT Id FROM ContentDocument]) {
            setContentDocId.add(doc.Id);
        }
        Test.startTest();
        Database.executeBatch(new DeleteContentDocumentsBatch(setContentDocId));
        // Verify ContentDocument deletion
        Integer intContentDocCount = [SELECT COUNT() FROM ContentDocument WHERE Id IN :setContentDocId];
        System.assertEquals(2, intContentDocCount, 'Asset ContentDocuments should not be deleted.');
        // Verify ContentDocumentLinks deletion
        Integer intContentDocLinkCount = [SELECT COUNT() FROM ContentDocumentLink WHERE ContentDocumentId IN :setContentDocId];
        System.assertEquals(2, intContentDocLinkCount, 'Asset ContentDocumentLinks should not be deleted.');
        Test.stopTest();
    }
}