/*
 * Purpose : To controll the behaviour of addFiles LWC.
 * Author  : Anandh
 */

public with sharing class AddFilesController {
	/*
	 * To get External file details by using the current page record id.
	 * @param strRecordId,strSearchKey from addFiles LWC
	 * @return List<CommonUtilities.ExternalFilesWrapper>
	 */
	@AuraEnabled
	public static List<CommonUtilities.ExternalFilesWrapper> getExternalFiles(String strRecordId, String strSearchKey) {
		List<CommonUtilities.ExternalFilesWrapper> lstEFWrapper = new List<CommonUtilities.ExternalFilesWrapper>();		
		try{
			List<External_File_Link__c> lstExternalFileLinks = [SELECT Id, External_Files__c, CreatedById, Related_To__c, External_Files__r.Is_Deleted__c FROM External_File_Link__c WHERE CreatedById !=: UserInfo.getUserId() OR Related_To__c =: strRecordId OR External_Files__r.Is_Deleted__c = TRUE WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 5000 ];
			Set<Id> setEFIdsToIgnore = new Set<Id>();
			for(External_File_Link__c objEFL : lstExternalFileLinks){
				setEFIdsToIgnore.add(objEFL.External_Files__c);
			}
			String strSearch = '%' + strSearchKey + '%';
			strSearchKey = String.escapeSingleQuotes(strSearch);
			List<External_Files__c> lstExternalFiles = [SELECT Id, Name, File_Name__c, Latest_Version_Size__c, Latest_External_File_Version__r.File_Location_URL__c, LastModifiedDate, File_Type__c FROM External_Files__c WHERE Id NOT IN :setEFIdsToIgnore AND (File_Name__c LIKE :strSearchKey OR File_Type__c LIKE :strSearchKey) WITH USER_MODE  ORDER BY CreatedDate DESC];
			for (External_Files__c objEF : lstExternalFiles) {
				CommonUtilities.ExternalFilesWrapper objEFWrapper = new CommonUtilities.ExternalFilesWrapper();
				objEFWrapper.strId = objEF.Id;
				objEFWrapper.strName = objEF.Name;
				objEFWrapper.strFileName = objEF.File_Name__c;
				objEFWrapper.strSize = objEF.Latest_Version_Size__c;
			    objEFWrapper.strFileURL = objEF.Latest_External_File_Version__r.File_Location_URL__c;
				objEFWrapper.lastModifiedDate = String.valueOf(objEF.LastModifiedDate);
				objEFWrapper.strFileType = objEF.File_Type__c;
				objEFWrapper.bolDisable = false;
				objEFWrapper.bolSelected = false;
				objEFWrapper.strDisplayText = String.valueOf(Date.newInstance(objEF.LastModifiedDate.year(), objEF.LastModifiedDate.month(), objEF.LastModifiedDate.day())) + ' . ' + objEF.Latest_Version_Size__c + ' . ' + objEF.File_Type__c;
				lstEFWrapper.add(objEFWrapper);
			}
		}catch (Exception exp) {
			ErrorLogger.logException('AddFilesController.getExternalFiles', exp);
		}		
		return lstEFWrapper;
	}
}