/*
 * Purpose : This is generic API utility that used to make api callouts to S3
 * Author  : Giri
 */
public with sharing class APIUtility {
	/**
	 * To make API callout to validate the details that provided by users
	 * @param strPresignedURL,strReqMethod from StorageConfigurationsController, ViewFilesController Classes.
	 * @return HttpResponse
	 */
	public static HttpResponse externalStorageCallout(String strPresignedURL, String strReqMethod) {
		HttpResponse response = new HttpResponse();
		try {
			Http http = new Http();
			HttpRequest request = new HttpRequest();
			request.setHeader('Content-Encoding', 'UTF-8');
			request.setHeader('Connection', 'keep-alive');
			request.setHeader('Date', Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z'));
			request.setHeader('ACL', 'public-read');
			request.setEndpoint(strPresignedURL);
			request.setMethod(strReqMethod);
			response = http.send(request);
		} catch (Exception exp) {
			ErrorLogger.logException('APIUtility.externalStorageCallout', exp);
		}
		return response;
	}

	/**
	 * To make API callout to delete the files from aws s3.
	 * @param strPresignedURL,strReqMethod from EmptyRecycleBinBatch, ViewFilesController Classes.
	 * @return HttpResponse
	 */
	public static HttpResponse copyFile(String strPresignedURL, String strCopySource) {
		HttpResponse response = new HttpResponse();
		try {
			HttpRequest request = new HttpRequest();
			request.setMethod('PUT');
			request.setEndpoint(strPresignedURL);
			request.setHeader('X-Amz-copy-source',strCopySource);
			Http http = new Http();
			response = http.send(request);
		} catch (Exception exp) {
			ErrorLogger.logException('APIUtility.copyFile', exp);
		}
		return response;
	}

	/**
	 * To make API callout to delete the files from aws s3.
	 * @param strPresignedURL,strReqMethod from EmptyRecycleBinBatch, ViewFilesController Classes.
	 * @return HttpResponse
	 */
	public static HttpResponse deleteFileFromExternalStorage(String strPresignedURL, String strReqMethod) {
		HttpResponse response = new HttpResponse();
		try {
			HttpRequest request = new HttpRequest();
			request.setMethod(strReqMethod);
			request.setEndpoint(strPresignedURL);
			Http http = new Http();
			response = http.send(request);
		} catch (Exception exp) {
			ErrorLogger.logException('APIUtility.deleteFileFromExternalStorage', exp);
		}
		return response;
	}

	/**
	 * To make API callout to upload the files to aws s3.
	 * @param strFileContent,strName,strType,strPresignedURL from UploadFilesController, MigrateAttachmentsBatch Classes.
	 * @return HttpResponse
	 */
	public static HttpResponse uploadFile(UploadFileWrapper objUploadFileWrapper) {
		HttpResponse response = new HttpResponse();
		try {
			Blob base64Content = EncodingUtil.base64Decode(objUploadFileWrapper.strFileContent);
			Http http = new Http();
			HttpRequest request = new HttpRequest();
			request.setBodyAsBlob(base64Content);
			request.setHeader('Content-Encoding', 'UTF-8');
			request.setHeader('Content-type', objUploadFileWrapper.strType);
			request.setHeader('Connection', 'keep-alive');
			request.setHeader('Date', Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z'));
			request.setHeader('ACL', 'public-read');
			request.setEndpoint(objUploadFileWrapper.strPresignedURL);
			request.setMethod('PUT');
			response = http.send(request);
		} catch (Exception exp) {
			ErrorLogger.logException('APIUtility.uploadFile', exp);
		}
		return response;
	}

	public class UploadFileWrapper {
	 @AuraEnabled
	 public String strFileContent { get; set; }
	 @AuraEnabled
	 public String strName { get; set; }
	 @AuraEnabled
	 public String strType { get; set; }
	 @AuraEnabled
	 public String strPresignedURL { get; set; }
	}
}