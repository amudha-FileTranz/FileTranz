/*
 * Purpose : To control the behaviour of uploadFiles LWC
 * Author  : Anandhakumar Thangasamy
 */
public with sharing class UploadFilesController {
	public static String strETags = '';
	/**
	 * To retrieve files from external files object.
	 * @param strRecordId from uploadViewFiles LWC
	 * @return List<CommonUtilities.ExternalFilesWrapper>
	 */
	@AuraEnabled(cacheable=true)
	public static List<CommonUtilities.ExternalFilesWrapper> retrieveRelatedExternalFiles(String strRecordId) {
		List<CommonUtilities.ExternalFilesWrapper> lstEFWrapper = new List<CommonUtilities.ExternalFilesWrapper>();
		try {
			List<External_File_Link__c> lstEFL = [
				SELECT
					Id,
					Name,
					External_Files__c,
					External_Files__r.File_Name__c,
					External_Files__r.Latest_Version_Size__c,
					External_Files__r.Latest_External_File_Version__r.File_Location_URL__c,
					Object_Type__c,
					Related_To__c,
					External_Files__r.File_Type__c,
					External_Files__r.UID__c,
					External_Files__r.LastModifiedDate
				FROM External_File_Link__c
				WHERE Related_To__c = :String.escapeSingleQuotes(strRecordId) WITH USER_MODE
				ORDER BY LastModifiedDate DESC
			];
			Integer intSno = 0;
			for (External_File_Link__c objEFL : lstEFL) {
				CommonUtilities.ExternalFilesWrapper objEFWrapper = new CommonUtilities.ExternalFilesWrapper();
				objEFWrapper.strName = objEFL.Name;
				objEFWrapper.strId = objEFL.id;
				objEFWrapper.strFileName = objEFL.External_Files__r.File_Name__c;
				objEFWrapper.strSize = objEFL.External_Files__r.Latest_Version_Size__c;
				objEFWrapper.strFileURL = objEFL.External_Files__r.Latest_External_File_Version__r.File_Location_URL__c;
				objEFWrapper.strObjectType = objEFL.Object_Type__c;
				objEFWrapper.lastModifiedDate = String.valueOf(objEFL.External_Files__r.LastModifiedDate);
				objEFWrapper.strRelatedTo = objEFL.Related_To__c;
				objEFWrapper.strFileType = objEFL.External_Files__r.File_Type__c;
				objEFWrapper.bolShowEdit = false;
				objEFWrapper.bolSelected = false;
				objEFWrapper.strUID = objEFL.External_Files__r.UID__c;
				objEFWrapper.sNo = ++intSno;
				objEFWrapper.dblSize = CommonUtilities.getFileSizeInKB(objEFL.External_Files__r.Latest_Version_Size__c);
				objEFWrapper.strExternalFileId = objEFL.External_Files__c;
				lstEFWrapper.add(objEFWrapper);
			}
		} catch (Exception exp) {
			ErrorLogger.logException('ViewFilesController.retrieveExternalFiles', exp);
		}
		return lstEFWrapper;
	}
	
	/**
	 * To create external files
	 * @param lstEFWrapper,strRecordId from uploadFiles LWC
	 * @return boolean
	 */
	@AuraEnabled(cacheable=false)
	public static Boolean createExternalFileLinks(List<ExternalFilesWrapper> lstEFWrapper, String strRecordId) {
		List<External_File_Link__c> lstEFLtoCreate = new List<External_File_Link__c>();
		String strObjectLabel = CommonUtilities.getObjectLabelFromId(strRecordId);
		try {
			for (ExternalFilesWrapper objEFWrapper : lstEFWrapper) {
				External_File_Link__c objEFL = new External_File_Link__c();
				objEFL.External_Files__c = objEFWrapper.Id;
				objEFL.Related_To__c = strRecordId;
				objEFL.Object_Type__c = strObjectLabel;
				lstEFLtoCreate.add(objEFL);
			}
			if(!lstEFLtoCreate.isEmpty() && Schema.SObjectType.External_File_Link__c.isCreateable()) {
				insertEFL(lstEFLtoCreate);
			}
			return true;
		} catch (Exception exp) {
			ErrorLogger.logException('UploadFilesController.createExternalFileLinks', exp);
			return false;
		}
	}

	@AuraEnabled(cacheable=false)
	public static String generateAuthHeaderForAWS(String strGenerateAuthHeaderForAWSWrapper) {
		String strErrorMessage = 'Failed : ';
		String strAuthHeader;
		try {
			GenerateAuthHeaderForAWSWrapper objGenerateAuthHeaderForAWSWrapper = (GenerateAuthHeaderForAWSWrapper) JSON.deserialize(strGenerateAuthHeaderForAWSWrapper, GenerateAuthHeaderForAWSWrapper.class);
			CommonUtilities.ExternalStorageSettingWrapper objExtStorageWrapper = CommonUtilities.getActiveStorageSetting();
			String strDateOnly = objGenerateAuthHeaderForAWSWrapper.strAmzDate.substring(0, 8);
			String strHost = objExtStorageWrapper.strBucket + '.s3.' + objExtStorageWrapper.strRegion + '.amazonaws.com';
			String strQueryParam = '';
			String strSign;
			if (objGenerateAuthHeaderForAWSWrapper.strUploadId == null && objGenerateAuthHeaderForAWSWrapper.strMethod != 'PUT') {
				strQueryParam = PresignedURLGenerator.uriEncode('uploads', false) + '=' + '\n';
			} else if (objGenerateAuthHeaderForAWSWrapper.intPartNumber != null) {
				strQueryParam = PresignedURLGenerator.uriEncode('partNumber', false) + '=' + String.valueOf(objGenerateAuthHeaderForAWSWrapper.intPartNumber) + '&' + PresignedURLGenerator.uriEncode('uploadId', false) + '=' + objGenerateAuthHeaderForAWSWrapper.strUploadId + '\n';
			} else if(objGenerateAuthHeaderForAWSWrapper.strMethod != 'PUT') {
				strQueryParam = PresignedURLGenerator.uriEncode('uploadId', false) + '=' + PresignedURLGenerator.uriEncode(objGenerateAuthHeaderForAWSWrapper.strUploadId, false) + '\n';
			}
			PresignedURLGenerator.GetSignatureWrapper objGetSignatureWrapper = new PresignedURLGenerator.GetSignatureWrapper();
			objGetSignatureWrapper.strMethod = objGenerateAuthHeaderForAWSWrapper.strMethod;
			objGetSignatureWrapper.strFileKey = objGenerateAuthHeaderForAWSWrapper.strRecordId + '/' + objGenerateAuthHeaderForAWSWrapper.strFileName;
			objGetSignatureWrapper.strXAmzContentSha256 = null;
			objGetSignatureWrapper.strAmzDate = objGenerateAuthHeaderForAWSWrapper.strAmzDate;
			objGetSignatureWrapper.strDateOnly = strDateOnly;
			objGetSignatureWrapper.strHost = strHost;
			objGetSignatureWrapper.strContentType = objGenerateAuthHeaderForAWSWrapper.strContentType;
			objGetSignatureWrapper.strQueryParam = strQueryParam;
			objGetSignatureWrapper.strUploadId = objGenerateAuthHeaderForAWSWrapper.strUploadId;
			objGetSignatureWrapper.strFileTitle = null;
			strSign = PresignedURLGenerator.getSignature(objGetSignatureWrapper);
			strAuthHeader =
				'AWS4-HMAC-SHA256 Credential=' +
				objExtStorageWrapper.strAccKy +
				'/' +
				strDateOnly +
				'/' +
				objExtStorageWrapper.strRegion +
				'/s3/aws4_request, SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date, Signature=' +
				strSign;
		} catch (Exception exp) {
			strErrorMessage += exp.getMessage();
			ErrorLogger.logException('UploadFilesController.generateAuthHeaderForMultipart', exp);
		}
		return strAuthHeader;
	}

	@AuraEnabled(cacheable=false)
	public static String createExternalFiles(String strFileName, String strRecordId, String strSize) {
		String strErrorMessage = 'Failed : ';
		String strChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
		String strRandom = String.valueOf(Datetime.now().millisecond());
		while (strRandom.length() < 13) {
			Integer intIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), strChars.length());
			strRandom += strChars.substring(intIndex, intIndex + 1);
		}
		String strUID = strRecordId + '_' + strRandom + '_1';
		try {
			if (String.isBlank(strRecordId) || String.isBlank(strFileName) || String.isBlank(strSize)) {
                throw new AuraHandledException('Invalid Record Id');
            }
			CommonUtilities.ExternalStorageSettingWrapper objExtStorageWrapper = CommonUtilities.getActiveStorageSetting();
			String strObjectLabel = CommonUtilities.getObjectLabelFromId(strRecordId);
			External_Files__c objEF = new External_Files__c();
			objEF.File_Name__c = strFileName;
			objEF.File_Type__c = strFileName.substringAfterLast('.');
			objEF.UID__c = strUID;
			objEF.Record_Type__c = 'Files';
			objEF.Uploaded_From__c = 'FileTranz';
			if (!Schema.SObjectType.External_Files__c.isCreateable()
				|| !Schema.SObjectType.External_Files__c.fields.File_Name__c.isCreateable()
				|| !Schema.SObjectType.External_Files__c.fields.File_Type__c.isCreateable()
				|| !Schema.SObjectType.External_Files__c.fields.UID__c.isCreateable()
				|| !Schema.SObjectType.External_Files__c.fields.Record_Type__c.isCreateable()
				|| !Schema.SObjectType.External_Files__c.fields.Uploaded_From__c.isCreateable()) {
				return strErrorMessage;
			}
			Database.insert(objEF, AccessLevel.USER_MODE);

			External_File_Version__c objEFV = new External_File_Version__c();
			objEFV.External_Files__c = objEF.Id;
			objEFV.File_Location_URL__c = objExtStorageWrapper.strEndPoint + '/' + strRecordId + '/' + strFileName.substringBeforeLast('.') + '_v1.' + strFileName.substringAfterLast('.');
			objEFV.Is_Latest__c = true;
			objEFV.Version_Number__c = 1;
			objEFV.Size__c = CommonUtilities.FormatFileSize(Decimal.valueOf(strSize));
			objEFV.Size_Bytes__c = Integer.valueOf(strSize);

			if (!Schema.SObjectType.External_File_Version__c.isCreateable()
				|| !Schema.SObjectType.External_File_Version__c.fields.External_Files__c.isCreateable()
				|| !Schema.SObjectType.External_File_Version__c.fields.File_Location_URL__c.isCreateable()
				|| !Schema.SObjectType.External_File_Version__c.fields.Is_Latest__c.isCreateable()
				|| !Schema.SObjectType.External_File_Version__c.fields.Version_Number__c.isCreateable()
				|| !Schema.SObjectType.External_File_Version__c.fields.Size__c.isCreateable()
				|| !Schema.SObjectType.External_File_Version__c.fields.Size_Bytes__c.isCreateable()) {
				return strErrorMessage;
			}
			Database.insert(objEFV, AccessLevel.USER_MODE);

			External_File_Link__c objEFL = new External_File_Link__c();
			objEFL.External_Files__c = objEF.Id;
			objEFL.Related_To__c = strRecordId;
			objEFL.Object_Type__c = strObjectLabel;

			if (!Schema.SObjectType.External_File_Link__c.isCreateable()
				|| !Schema.SObjectType.External_File_Link__c.fields.External_Files__c.isCreateable()
				|| !Schema.SObjectType.External_File_Link__c.fields.Related_To__c.isCreateable()
				|| !Schema.SObjectType.External_File_Link__c.fields.Object_Type__c.isCreateable()) {
				return strErrorMessage;
			}
			Database.insert(objEFL, AccessLevel.USER_MODE);

			
			if (!Schema.SObjectType.External_Files__c.isUpdateable()
				|| !Schema.SObjectType.External_Files__c.fields.Latest_External_File_Version__c.isUpdateable()) {
				return strErrorMessage;
			}
			objEF.Latest_External_File_Version__c = objEFV.Id;
			Database.update(objEF, AccessLevel.USER_MODE);
			// To log activities
			String strActivities = CommonUtilities.getConfiguration(new List<String>{ 'File Configuration' }).get('Log_Activity');
			if (strActivities != null && strActivities.contains('Upload')) {
				User objUser = CommonUtilities.getCurrentUserDetails();
				Log_Activity__c objLogActivity = new Log_Activity__c();
				objLogActivity.File_Name__c = objEF.File_Name__c;
				objLogActivity.External_File_Id__c = objEF.Id;
				objLogActivity.Activity_Type__c = 'Upload';
				objLogActivity.Activity_Performed_By__c = objUser.Id;
				objLogActivity.Record_Id__c = strRecordId;
				if (Schema.SObjectType.Log_Activity__c.isCreateable()
					&& Schema.SObjectType.Log_Activity__c.fields.File_Name__c.isCreateable()
					&& Schema.SObjectType.Log_Activity__c.fields.External_File_Id__c.isCreateable()
					&& Schema.SObjectType.Log_Activity__c.fields.Activity_Type__c.isCreateable()
					&& Schema.SObjectType.Log_Activity__c.fields.Activity_Performed_By__c.isCreateable()
					&& Schema.SObjectType.Log_Activity__c.fields.Record_Id__c.isCreateable()) {
					Database.insert(objLogActivity, AccessLevel.USER_MODE);
				}
			}
			strErrorMessage = Label.Success;
		} catch (Exception exp) {
			strErrorMessage += exp.getMessage();
			ErrorLogger.logException('UploadFilesController.createExternalFiles', exp);
		}
		return strErrorMessage;
	}

	private static void insertEFL(List<External_File_Link__c> lstEFLtoCreate){
		Set<Id> setEFLIds = new Set<Id>();
		if (lstEFLtoCreate.size() > 0) {
			Database.insert(lstEFLtoCreate, AccessLevel.USER_MODE);
			// To log activities
			String strActivities = CommonUtilities.getConfiguration(new List<String>{ 'File Configuration' }).get('Log_Activity');
			List<Log_Activity__c> lstLogActivity = new List<Log_Activity__c>();
			if (strActivities != null && strActivities.contains('Upload')) {
				for (External_File_Link__c objEFL : lstEFLtoCreate) {
					setEFLIds.add(objEFL.id);
				}
				lstEFLtoCreate = [SELECT Id, External_Files__r.File_Name__c, External_Files__c, Related_To__c FROM External_File_Link__c WHERE Id IN :setEFLIds WITH USER_MODE];
				User objUser = CommonUtilities.getCurrentUserDetails();
				for (External_File_Link__c objEFL : lstEFLtoCreate) {
					Log_Activity__c objLogActivity = new Log_Activity__c();
					objLogActivity.File_Name__c = objEFL.External_Files__r.File_Name__c;
					objLogActivity.External_File_Id__c = objEFL.External_Files__c;
					objLogActivity.Activity_Type__c = 'Upload';
					objLogActivity.Activity_Performed_By__c = objUser.Id;
					objLogActivity.Record_Id__c = objEFL.Related_To__c;
					lstLogActivity.add(objLogActivity);
				}
			}
			if (lstLogActivity.size() > 0 && Log_Activity__c.SobjectType.getDescribe().iscreateable()) {
				Database.insert(lstLogActivity, AccessLevel.USER_MODE);
			}
		}
	}

	public class ExternalFilesWrapper {
		@AuraEnabled
		public String length { get; set; }
		@AuraEnabled
		public String name { get; set; }
		@AuraEnabled
		public String id { get; set; }
		@AuraEnabled
		public String bolExistingFile { get; set; }
		@AuraEnabled
		public String type { get; set; }
		@AuraEnabled
		public String size { get; set; }
	}

	public class GenerateAuthHeaderForAWSWrapper {
		@AuraEnabled
		public String strMethod { get; set; }
		@AuraEnabled
		public String strRecordId { get; set; }
		@AuraEnabled
		public String strFileName { get; set; }
		@AuraEnabled
		public String strContentType { get; set; }
		@AuraEnabled
		public String strAmzDate { get; set; }
		@AuraEnabled
		public String strUploadId { get; set; }
		@AuraEnabled
		public Integer intPartNumber { get; set; }
		@AuraEnabled
		public Integer intTotalParts { get; set; }		
	}
}