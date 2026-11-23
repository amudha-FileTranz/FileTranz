/*
 * Purpose : This is generic method to calcuate presigned url to authenticate aws s3 server.
 * Author  : Giri
 */
public with sharing class PresignedURLGenerator {
    /**
     * To generate presigned URL for the API callout authorization
     * @param strMethod,strAccKy,strStKy,strBucketName,strBucketRegion,strLocation,strFile,intExpires from UploadFilesController,EmptyRecycleBinBatch,ViewFilesController,MigrateAttachmentsBatch classes
     * @return String
     */
    @AuraEnabled
    public static String getSignedURL(GetSignedURLWrapper objGetSignedURLWrapper) {
        // New change - Start 
        CommonUtilities.ExternalStorageSettingWrapper objESSettings = CommonUtilities.getActiveStorageSetting();
        // New change - End
        Datetime currentDateTime = Datetime.now();
        String dateOnlyStr = currentDateTime.formatGmt('yyyyMMdd');
        String strReq = dateOnlyStr + '/' + objGetSignedURLWrapper.strBucketRegion + '/s3/aws4_request';
        String strxAmzCredentialStr = objESSettings.strAccKy + '/' + strReq;
        String strxAmzDate = currentDateTime.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
        String strxAmzSignedHeaders = 'host';
        String strHost = objGetSignedURLWrapper.strBucketName + '.s3.' + objGetSignedURLWrapper.strBucketRegion + '.amazonaws.com';
        // To frame canonical request
        String strCanonicalRequest =
            objGetSignedURLWrapper.strMethod +
            '\n' +
            '/' +
            uriEncode(objGetSignedURLWrapper.strFile, false) +
            '\n' +
            uriEncode('X-Amz-Algorithm', true) +
            '=' +
            uriEncode('AWS4-HMAC-SHA256', true) +
            '&' +
            uriEncode('X-Amz-Credential', true) +
            '=' +
            uriEncode(strxAmzCredentialStr, true) +
            '&' +
            uriEncode('X-Amz-Date', true) +
            '=' +
            uriEncode(strxAmzDate, true) +
            '&' +
            uriEncode('X-Amz-Expires', true) +
            '=' +
            uriEncode(String.valueOf(objGetSignedURLWrapper.intExpires), true) +
            '&' +
            uriEncode('X-Amz-SignedHeaders', true) +
            '=' +
            uriEncode(strxAmzSignedHeaders, true) +
            '\n' +
            'host:' +
            strHost +
            '\n\n' +
            'host\n' +
            'UNSIGNED-PAYLOAD';
        // To frame string to sign
        String stringToSign = 'AWS4-HMAC-SHA256\n' + strxAmzDate + '\n' + strReq + '\n' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(strCanonicalRequest)));
        // To calculate signature
        Blob bloDateKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(dateOnlyStr), Blob.valueOf('AWS4' + objESSettings.strStKy));
        Blob bloDateRegionKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(objGetSignedURLWrapper.strBucketRegion), bloDateKey);
        Blob bloDateRegionServiceKey = Crypto.generateMac('hmacSHA256', Blob.valueOf('s3'), bloDateRegionKey);
        Blob bloSigningKey = Crypto.generateMac('hmacSHA256', Blob.valueOf('aws4_request'), bloDateRegionServiceKey);
        Blob bloSignature = Crypto.generateMac('hmacSHA256', Blob.valueOf(stringToSign), bloSigningKey);
        String strSignature = EncodingUtil.convertToHex(bloSignature);
        // Return presigned URL
        return objGetSignedURLWrapper.strLocation +
            '?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=' +
            EncodingUtil.urlEncode(strxAmzCredentialStr, 'UTF-8') +
            '&X-Amz-Date=' +
            strxAmzDate +
            '&X-Amz-Expires=' +
            String.valueOf(objGetSignedURLWrapper.intExpires) +
            '&X-Amz-Signature=' +
            StrSignature +
            '&X-Amz-SignedHeaders=host';
        // return StrSignature;
    }
    
    @AuraEnabled
    public static String getSignedURLForCopyFile(GetSignedURLForCopyFileWrapper objGetSignedURLForCopyFileWrapper) {
        // New change - Start
        CommonUtilities.ExternalStorageSettingWrapper objESSettings = CommonUtilities.getActiveStorageSetting();
        // New change - End
        Datetime currentDateTime = Datetime.now();
        String dateOnlyStr = currentDateTime.formatGmt('yyyyMMdd');
        String strReq = dateOnlyStr + '/' + objGetSignedURLForCopyFileWrapper.strBucketRegion + '/s3/aws4_request';
        String strxAmzCredentialStr = objESSettings.strAccKy + '/' + strReq;
        String strxAmzDate = currentDateTime.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
        String strxAmzSignedHeaders = uriEncode('host;x-amz-copy-source',true);
        String strHost = objGetSignedURLForCopyFileWrapper.strBucketName + '.s3.' + objGetSignedURLForCopyFileWrapper.strBucketRegion + '.amazonaws.com';
        // To frame canonical request
        String strCanonicalRequest =
            objGetSignedURLForCopyFileWrapper.strMethod +
            '\n' +
            '/' +
            uriEncode(objGetSignedURLForCopyFileWrapper.strFile, false) +
            '\n' +
            uriEncode('X-Amz-Algorithm', true) +
            '=' +
            uriEncode('AWS4-HMAC-SHA256', true) +
            '&' +
            uriEncode('X-Amz-Credential', true) +
            '=' +
            uriEncode(strxAmzCredentialStr, true) +
            '&' +
            uriEncode('X-Amz-Date', true) +
            '=' +
            uriEncode(strxAmzDate, true) +
            '&' +
            uriEncode('X-Amz-Expires', true) +
            '=' +
            uriEncode(String.valueOf(objGetSignedURLForCopyFileWrapper.intExpires), true) +
            '&' +
            uriEncode('X-Amz-SignedHeaders', true) +
            '=' +
            strxAmzSignedHeaders +
            '\n' +
            'host:' +
            strHost +
            '\n' +
            'x-amz-copy-source:' +
            objGetSignedURLForCopyFileWrapper.strCopySource +
            '\n\n' +
            'host;x-amz-copy-source\n' +
            'UNSIGNED-PAYLOAD';
        // To frame string to sign
        String stringToSign = 'AWS4-HMAC-SHA256\n' + strxAmzDate + '\n' + strReq + '\n' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(strCanonicalRequest)));
        // To calculate signature
        Blob bloDateKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(dateOnlyStr), Blob.valueOf('AWS4' + objESSettings.strStKy));
        Blob bloDateRegionKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(objGetSignedURLForCopyFileWrapper.strBucketRegion), bloDateKey);
        Blob bloDateRegionServiceKey = Crypto.generateMac('hmacSHA256', Blob.valueOf('s3'), bloDateRegionKey);
        Blob bloSigningKey = Crypto.generateMac('hmacSHA256', Blob.valueOf('aws4_request'), bloDateRegionServiceKey);
        Blob bloSignature = Crypto.generateMac('hmacSHA256', Blob.valueOf(stringToSign), bloSigningKey);
        String strSignature = EncodingUtil.convertToHex(bloSignature);
        // Return presigned URL
        return objGetSignedURLForCopyFileWrapper.strLocation +
            '?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=' +
            EncodingUtil.urlEncode(strxAmzCredentialStr, 'UTF-8') +
            '&X-Amz-Date=' +
            strxAmzDate +
            '&X-Amz-Expires=' +
            String.valueOf(objGetSignedURLForCopyFileWrapper.intExpires) +
            '&X-Amz-Signature=' +
            StrSignature +
            '&X-Amz-SignedHeaders=host;x-amz-copy-source';
        // return StrSignature;
    }
    
    /**
     * To generate signature for the API callout authorization
     * @param strMethod,strFileKey,strXAmzContentSha256,strAmzDate,strDateOnly,strHost,strContentType,strQueryParam,strUploadId from UploadFilesController class
     * @return String
     */
    @AuraEnabled
    public static String getSignature(GetSignatureWrapper objGetSignatureWrapper) {
        CommonUtilities.ExternalStorageSettingWrapper objExtStorageWrapper = CommonUtilities.getActiveStorageSetting();
        // To frame canonical request
        String strCanonicalRequest =
            objGetSignatureWrapper.strMethod +
            '\n' +
            '/' +
            uriEncode(objGetSignatureWrapper.strFileKey, false) +
            '\n';
        if(objGetSignatureWrapper.strQueryParam != '') {
            strCanonicalRequest = strCanonicalRequest + objGetSignatureWrapper.strQueryParam;
        } else {
            strCanonicalRequest = strCanonicalRequest + '\n';
        }
        strCanonicalRequest = strCanonicalRequest +
            uriEncode('content-type', true) +
            ':' +
            objGetSignatureWrapper.strContentType +
            '\n' +
            'host:' +
            objGetSignatureWrapper.strHost +
            '\n' +
            'x-amz-content-sha256:UNSIGNED-PAYLOAD' +
            '\n' +
            uriEncode('x-amz-date', true) +
            ':' +
            uriEncode(objGetSignatureWrapper.strAmzDate, true);
        strCanonicalRequest += '\n\n' + 'content-type;host;x-amz-content-sha256;x-amz-date\n' + 'UNSIGNED-PAYLOAD';
        // To frame string to sign
        String strToSign =
            'AWS4-HMAC-SHA256\n' +
            objGetSignatureWrapper.strAmzDate +
            '\n' +
            objGetSignatureWrapper.strDateOnly +
            '/' +
            objExtStorageWrapper.strRegion +
            '/s3/aws4_request\n' +
            EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(strCanonicalRequest)));
        // To calculate signature
        Blob bloDateKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(objGetSignatureWrapper.strDateOnly), Blob.valueOf('AWS4' + objExtStorageWrapper.strStKy));
        Blob bloDateRegionKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(objExtStorageWrapper.strRegion), bloDateKey);
        Blob bloDateRegionServiceKey = Crypto.generateMac('hmacSHA256', Blob.valueOf('s3'), bloDateRegionKey);
        Blob bloSigningKey = Crypto.generateMac('hmacSHA256', Blob.valueOf('aws4_request'), bloDateRegionServiceKey);
        Blob bloSignature = Crypto.generateMac('hmacSHA256', Blob.valueOf(strToSign), bloSigningKey);
        String strSignature = EncodingUtil.convertToHex(bloSignature);
        return strSignature;
    }
    /**
     * To generate Uriencode value
     * @param input,encodeSlash
     * @return String
     */
    public static String uriEncode(String input, Boolean encodeSlash) {
        String result = '';
        for (Integer i = 0; i < input.length(); i++) {
            String ch = input.substring(i, i + 1);
            if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') || ch == '_' || ch == '-' || ch == '~' || ch == '.') {
                result += ch;
            } else if (ch == '/') {
                result += encodeSlash ? '%2F' : ch;
            } else {
                String hexValue = EncodingUtil.convertToHex(Blob.valueOf(ch)).toUpperCase();
                if (hexValue.length() == 2) {
                    result += '%' + hexValue;
                } else if (hexValue.length() == 4) {
                    result += '%' + hexValue.substring(0, 2) + '%' + hexValue.substring(2);
                }
            }
        }
        return result;
    }

    /**
     * To generate urlDecode value
     * @param encodedUrl
     * @return String
     */
    public static String decodeUrl(String encodedUrl) {
        // Using URL.decode() to decode the URL-encoded string
        return EncodingUtil.urlDecode(encodedUrl, 'UTF-8');
    }


    public class GetSignedURLWrapper {
        @AuraEnabled
        public String strMethod { get; set;}
        
        @AuraEnabled
        public String strAccKy { get; set;}
        @AuraEnabled
        public String strStKy { get; set;}
        
        @AuraEnabled
        public String strBucketName { get; set;}
        @AuraEnabled
        public String strBucketRegion { get; set;}
        @AuraEnabled
        public String strLocation { get; set;}
        @AuraEnabled
        public String strFile { get; set;}
        @AuraEnabled
        public Integer intExpires { get; set;}
        @AuraEnabled
        public String strFileName { get; set;}
    }
    
    public class GetSignedURLForCopyFileWrapper {
        @AuraEnabled
        public String strMethod { get; set;}
        
        @AuraEnabled
        public String strAccKy { get; set;}
        @AuraEnabled
        public String strStKy { get; set;}
        
        @AuraEnabled
        public String strBucketName { get; set;}
        @AuraEnabled
        public String strBucketRegion { get; set;}
        @AuraEnabled
        public String strLocation { get; set;}
        @AuraEnabled
        public String strFile { get; set;}
        @AuraEnabled
        public Integer intExpires { get; set;}
        @AuraEnabled
        public String strCopySource { get; set;}
    }
    
    public class GetSignatureWrapper {
        @AuraEnabled
        public String strMethod { get; set;}
        @AuraEnabled
        public String strFileKey { get; set;}
        @AuraEnabled
        public String strXAmzContentSha256 { get; set;}
        @AuraEnabled
        public String strAmzDate { get; set;}
        @AuraEnabled
        public String strDateOnly { get; set;}
        @AuraEnabled
        public String strHost { get; set;}
        @AuraEnabled
        public String strContentType { get; set;}
        @AuraEnabled
        public String strQueryParam { get; set;}
        @AuraEnabled
        public String strUploadId { get; set;}
        @AuraEnabled
        public String strFileTitle { get; set;}
    }
}