/*
 *
 * Purpose : Screen to upload file to external storage and access those files. 
 * Author  : Giri
 *
 */

import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, api, track, wire } from 'lwc';
// Importing Apex methods
import getActiveStorageSetting from "@salesforce/apex/CommonUtilities.getActiveStorageSettingForLWC";
import getConfigurations from "@salesforce/apex/CommonUtilities.getConfiguration";
import getCurrentUserPermissions from "@salesforce/apex/CommonUtilities.getCurrentUserPermissions";
import delExternalFileLinks from "@salesforce/apex/ViewFilesControllerHelper.deleteExternalFileLinks";
import getFileFromAmazonS3 from "@salesforce/apex/ViewFilesController.getFileFromAmazonS3";
import getPreSignedURL from "@salesforce/apex/ViewFilesController.getPresignedURL";
import retrieveExternalFiles from "@salesforce/apex/ViewFilesController.retrieveExternalFiles";
import updateFileNames from "@salesforce/apex/ViewFilesController.updateFileNames";
import logError from "@salesforce/apex/ErrorLogger.logError";

// Importing Custom labels
import ACTION from "@salesforce/label/c.ACTION";
import Are_you_sure_you_want_to_delete_it from "@salesforce/label/c.Are_you_sure_you_want_to_delete_it";
import Clear from "@salesforce/label/c.Clear";
import Confirm_Delete from "@salesforce/label/c.Confirm_Delete";
import Delete from "@salesforce/label/c.Delete";
import Download from "@salesforce/label/c.Download";
import EDIT from "@salesforce/label/c.EDIT";
import Error from "@salesforce/label/c.Error";
import Error_Found_when_deleting_the_record from "@salesforce/label/c.Error_Found_when_deleting_the_record";
import External_Files from "@salesforce/label/c.External_Files";
import FileTranz_component_is_not_enabled_for_this_profile_user from "@salesforce/label/c.FileTranz_component_is_not_enabled_for_this_profile_user";
import File_Name from "@salesforce/label/c.File_Name";
import File_Name_is_updated_successfully from "@salesforce/label/c.File_Name_is_updated_successfully";
import File_Names_are_updated_successfully from "@salesforce/label/c.File_Names_are_updated_successfully";
import File_Size from "@salesforce/label/c.File_Size";
import File_Type from "@salesforce/label/c.File_Type";
import File_deleted_successfully from "@salesforce/label/c.File_deleted_successfully";
import File_deletion_failed from "@salesforce/label/c.File_deletion_failed";
import File_downloaded_successfully from "@salesforce/label/c.File_downloaded_successfully";
import File_not_found_for_deletion from "@salesforce/label/c.File_not_found_for_deletion";
import Filename_should_not_be_empty from "@salesforce/label/c.Filename_should_not_be_empty";
import Filetranz_banner_message from "@salesforce/label/c.Filetranz_banner_message";
import First from "@salesforce/label/c.First";
import LAST_MODIFIED_DATE from "@salesforce/label/c.LAST_MODIFIED_DATE";
import Loading from "@salesforce/label/c.Loading";
import Next from "@salesforce/label/c.Next";
import No from "@salesforce/label/c.No";
import Page from "@salesforce/label/c.Page";
import Page_Size from "@salesforce/label/c.Page_Size";
import Previous from "@salesforce/label/c.Previous";
import Related_External_Files from "@salesforce/label/c.Related_External_Files";
import S_No from "@salesforce/label/c.S_No";
import Save from "@salesforce/label/c.Save";
import Search_Files from "@salesforce/label/c.Search_Files";
import Something_went_wrong from "@salesforce/label/c.Something_went_wrong";
import Success from "@salesforce/label/c.Success";
import The_selected_file_format_doesn_t_support_the_preview from "@salesforce/label/c.The_selected_file_format_doesn_t_support_the_preview";
import This_file_name_already_exists from "@salesforce/label/c.This_file_name_already_exists";
import Unable_to_download from "@salesforce/label/c.Unable_to_download";
import Unable_to_download_msg from "@salesforce/label/c.Unable_to_download_msg";
import Warning from "@salesforce/label/c.Warning";
import Yes from "@salesforce/label/c.Yes";
import files from "@salesforce/label/c.files";
import last from "@salesforce/label/c.last";
import of from "@salesforce/label/c.of";
import filetranzcustomstyle from "@salesforce/resourceUrl/filetranzcustomstyle";
import { loadStyle } from "lightning/platformResourceLoader";
import { CurrentPageReference } from 'lightning/navigation';

const FILE_LIMIT = "File_Limit";
const UPLOAD_SIZE_LIMIT = "Upload_Size_Limit";
const FILE_TYPES = "File_Types";
const RESTRICT_FILE_TYPES = "Restrict_File_Types";

export default class UploadViewFiles extends NavigationMixin(LightningElement) {
	@api recordId;
	@track objectApiName;
	@track preSignedUrl;
	@track parentState = {
		bolFilesSelected: false,
		bolShowAddFile: false,
		bolDisableUpload: false,
		bolCancel: true,
		bolShowUpload: false,
		bolViewFiles: false,
		bolPreviewFile: false,
		bolEditFile: false,
		bolDeleteFile: false,
		bolDownloadFile: false,
		bolShowActions: false,
		bolSpinner: true,
		bolFiles: false,
		bolSearch: false,
		bolObjectEnabled: false,
		bolShowMessage: false,
		bolShowPreviewModal: false,
		bolSave: false
	}
	@track parentData = {
		arrFiles: [],
		arrTempFiles: [],
		strTitle: 'Related External Files',
		arrPreviewFormats: [],
		mapConfigurations: [],
		intAllowFilesToUpload: 5,
		intAllowFilesLimitToUpload: 5,
		arrSelectedFilesToUpload: [],
		arrViewAllFiles: [],
		arrViewSearchFiles: [],
		arrNameUpdateFiles: [],
		setChangedNames: new Set(),
		setFileNames: new Set(),
		strSearchKey: '',
		strFileURL: '',
		mapFileNameOld: new Map(),
		strSortedColumn: 'LastModifiedDate',
		strSortedDirection: 'desc',
		arrTempSelectedFilesToUpload: [],
		bolActiveStorageAvailable: false,
		strSearchValue: '',
		strMessage: '',
		objActiveStorageDetails: {},
		intMaximumFileSize: 0,
		setOldFileName : new Set()
	}

	// To maintain the pagination data's
	@track paginationData = {
		arrPageSizeOptions: [10, 25, 50, 75, 100],
		intTotalRecords: 0,
		intPageSize: 1,
		intTotalPages: 0,
		intPageNumber: 1,
		intStartNumber: 0,
		intEndNumber: 0
	}

	// State that used to maintain the sorting states
	@track sortingState = {
		bolNameUp: false,
		bolNameDown: false,
		bolSizeUp: false,
		bolSizeDown: false,
		bolDateUp: false,
		bolDateDown: true,
		bolTypeDown: false,
		bolTypeUp: false
	};
	@track uploadFilesShow = true;
	@track bolDelete = false;
	@track strStraction = '';
	@track strInvokingscreen = '';
	@track strTargetId = '';
	@track strFileName = '';
	@track objLogErrorWrapper = {};

	// Custom labels
	CUSTOM_LABELS = {
		File_Name,
		File_Size,
		File_Type,
		ACTION,
		Download,
		Delete,
		External_Files,
		Save,
		LAST_MODIFIED_DATE,
		S_No,
		Page_Size,
		Previous,
		Next,
		Something_went_wrong,
		File_Names_are_updated_successfully,
		File_Name_is_updated_successfully,
		This_file_name_already_exists,
		Error_Found_when_deleting_the_record,
		Related_External_Files,
		Unable_to_download_msg,
		Unable_to_download,
		File_downloaded_successfully,
		Clear,
		File_deleted_successfully,
		Page,
		files,
		of,
		Search_Files,
		Filetranz_banner_message,
		FileTranz_component_is_not_enabled_for_this_profile_user,
		The_selected_file_format_doesn_t_support_the_preview,
		Warning,
		File_not_found_for_deletion,
		File_deletion_failed,
		Filename_should_not_be_empty,
		First,
		last,
		EDIT,
		Loading,
		Confirm_Delete,
		Are_you_sure_you_want_to_delete_it,
		Yes,
		No
	};

	
	@wire(CurrentPageReference)
	getPageRef(pageRef) {
		if (pageRef) {
			this.objectApiName = pageRef.attributes.objectApiName;
		}
	}

	// To retrieve related file details from the external files object.
	async connectedCallback() {
		console.log('objectapiname::', this.objectApiName);
		let bolStorageAvailable = false;
		await getActiveStorageSetting()
			.then((result) => {
				this.parentData.objActiveStorageDetails = result;
				this.parentState.bolSpinner = false;
				bolStorageAvailable = true;
			})
			.catch((error) => {
				this.parentState.bolSpinner = false;
				this.parentData.bolActiveStorageAvailable = false;
				this.objLogErrorWrapper = {};
				this.objLogErrorWrapper.relatedTo = "CommonUtilities.getActiveStorageSettingForLWC";
				this.objLogErrorWrapper.summary = "";
				this.objLogErrorWrapper.message = error;
				this.objLogErrorWrapper.batchJobId = "";
				this.objLogErrorWrapper.recordIds = this.recordId;
				this.objLogErrorWrapper.statusCode = "";
				logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });	
				this.showNotification(Error, this.CUSTOM_LABELS.Something_went_wrong, "error");
				
			});
		if (bolStorageAvailable) {
			await this.handleConfigurations();
		} else {
			this.parentData.strMessage = this.CUSTOM_LABELS.Filetranz_banner_message;
			this.parentState.bolShowMessage = true;
		}
		loadStyle(this, filetranzcustomstyle);
	}

	// This method is to query the external file record 
	async handleRetrieveExternalFiles() {
		retrieveExternalFiles({ strRecordId: this.recordId })
			.then((result) => {				
				if (result != null && result.length > 0) {
					this.parentData.arrFiles = result;
					this.parentData.arrTempFiles = this.parentData.arrFiles.slice(0, 5);
					this.parentData.strTitle += " (" + this.parentData.arrFiles.length + ")";
					this.parentState.bolFiles = true;
					this.paginationData.intPageSize = this.paginationData.arrPageSizeOptions[0];
				}
				this.parentState.bolSpinner = false;
				this.parentData.bolActiveStorageAvailable = true;
			})
			.catch((error) => {
				this.objLogErrorWrapper = {};
				this.objLogErrorWrapper.relatedTo = "ViewFilesController.retrieveExternalFiles";
				this.objLogErrorWrapper.summary = "";
				this.objLogErrorWrapper.message = error;
				this.objLogErrorWrapper.batchJobId = "";
				this.objLogErrorWrapper.recordIds = this.recordId;
				this.objLogErrorWrapper.statusCode = "";
				logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });	
				this.showNotification(Error, this.CUSTOM_LABELS.Something_went_wrong, "error");
				this.parentState.bolSpinner = false;
			});
	}

	// This method is to handle configuration records and based on configuration
	async handleConfigurations() {
		this.parentState.bolViewFiles = false;
		this.parentState.bolPreviewFile = false;
		this.parentState.bolDownloadFile = false;
		this.parentState.bolEditFile = false;
		this.parentState.bolDeleteFile = false;

		// To initiate org wide setup  once the profile/user level setup completed
		let setConfigurationType = ["File Configuration"];
		await getConfigurations({ lstConfigurationType: setConfigurationType })
			.then((data) => {
				const stringifiedData = JSON.stringify(data);
    			const result = JSON.parse(stringifiedData);
				this.parentData.intAllowFilesToUpload = Number(result['File_Limit']);
				this.parentData.intAllowFilesLimitToUpload = Number(result['Upload_Size_Limit']);
				this.parentData.intMaximumFileSize = Number(result['Upload_Size_Limit'] || 0); //-->Corrected to handle null value
				//this.parentData.intMaximumFileSize = Number(result['Upload_Size_Limit']);
				this.parentData.mapConfigurations = result;
				if (result["Preview_Formats"] != null) {
					this.parentData.arrPreviewFormats = result['Preview_Formats'].split("; ");
				}

				let arrFileTypes, arrRestFileTypes;
				if (result['File_Types'] != null) {
					arrFileTypes = result['File_Types'].split('; ');
				}
				if (result['Restrict_File_Types'] != null) {
					arrRestFileTypes = result['Restrict_File_Types'].split('; ');
				}
				const setRestrictTypes = new Set(arrRestFileTypes);
				this.parentData.arrAcceptedFormats = arrFileTypes.filter((type) => {
					return setRestrictTypes.has(type);
				});

				this.parentState.bolShowActions = this.parentState.bolDeleteFile || this.parentState.bolDownloadFile ? true : false;
			})
			.catch((error) => {
				this.objLogErrorWrapper = {};
				this.objLogErrorWrapper.relatedTo = "CommonUtilities.getConfiguration";
				this.objLogErrorWrapper.summary = "";
				this.objLogErrorWrapper.message = error;
				this.objLogErrorWrapper.batchJobId = "";
				this.objLogErrorWrapper.recordIds = this.recordId;
				this.objLogErrorWrapper.statusCode = "";
				logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
				this.showNotification(Error, this.CUSTOM_LABELS.Something_went_wrong, "error");
			});

		await getCurrentUserPermissions()
			.then((result) => {
				if(result != null && result != undefined) {
					let arrPermissions = result;
					this.parentState.bolShowUpload = arrPermissions.includes("Upload");
					this.parentState.bolViewFiles = arrPermissions.includes("View");
					this.parentState.bolPreviewFile = arrPermissions.includes("Preview");
					this.parentState.bolDownloadFile = arrPermissions.includes("Download");
					this.parentState.bolEditFile = arrPermissions.includes("Edit");
					this.parentState.bolDeleteFile = arrPermissions.includes("Delete");
					this.parentState.bolShowActions = (this.parentState.bolDownloadFile || this.parentState.bolDeleteFile) ? true : false;
					// To show the message if no access for the reepective profile/user
					if (!this.parentState.bolShowUpload && !this.parentState.bolViewFiles && !this.parentState.bolPreviewFile && !this.parentState.bolDownloadFile && !this.parentState.bolEditFile && !this.parentState.bolDeleteFile) {
						this.parentState.bolShowMessage = true;
						this.parentData.strMessage = this.CUSTOM_LABELS.FileTranz_component_is_not_enabled_for_this_profile_user + "!";
					}
				} 	else {
						this.parentState.bolShowUpload = false;
						this.parentState.bolViewFiles = false;
						this.parentState.bolPreviewFile = false;
						this.parentState.bolDownloadFile = false;
						this.parentState.bolEditFile = false;
						this.parentState.bolDeleteFile = false;
						this.parentState.bolShowActions = false;
						this.parentState.bolShowMessage = true;
						this.parentData.strMessage = this.CUSTOM_LABELS.FileTranz_component_is_not_enabled_for_this_profile_user + "!";
					}
				this.handleRetrieveExternalFiles();
			})
			.catch((error) => {
				this.showNotification(Error, this.CUSTOM_LABELS.Something_went_wrong, "error");
			});	
		if (!this.parentState.bolViewFiles) {
			this.parentState.bolSpinner = false;
		}
	}

	// To retrieve files after uploading the files
	handleFileUplaod(event) {
		this.parentState.bolFilesSelected = false;
		this.parentState.bolSpinner = event.detail.bolFileUploaded;
		this.uploadFilesShow = false;
		retrieveExternalFiles({ strRecordId: this.recordId })
			.then((result) => {				
				if (result.length > 0) {
					this.parentData.arrFiles = result;
					this.parentData.arrTempFiles = this.parentData.arrFiles.slice(0, 5);
					this.parentData.strTitle = this.CUSTOM_LABELS.Related_External_Files;
					this.parentData.strTitle += " (" + this.parentData.arrFiles.length + ")";
					this.parentState.bolFiles = true;
					this.parentState.bolSpinner = false;
					this.uploadFilesShow = true;
				} else {
					this.showNotification(Error, this.CUSTOM_LABELS.Something_went_wrong, "error");
					this.parentState.bolSpinner = false;
				}
			})
			.catch(() => {
				this.showNotification(Error, this.CUSTOM_LABELS.Something_went_wrong, "error");
				this.parentState.bolSpinner = false;
			});
	}

	// To handle files upload while trying with the add file component
	async addFiles(event) {
		this.parentData.arrTempSelectedFilesToUpload = Array.from(event.detail.arrSelectedFiles);
		this.parentState.bolFilesSelected = true;
		let child = this.template.querySelector('c-upload-files');
		await child.handleSelectedFilesInAddFiles(this.parentData.arrTempSelectedFilesToUpload);
		this.closePopup();
	}

	// This is to handle Add Files - click action
	handleAddFile(event) {
		this.parentState.bolShowAddFile = event.detail.bolShowAddFile;
		this.parentData.arrSelectedFilesToUpload = [...event.detail.selectedFilesToUpload];
	}

	// This is to hide Add Files screen
	closePopup() {
		this.parentState.bolShowAddFile = false;
	}

	// To handle view all screen
	handleViewAll() {
		this.parentState.bolSave = false;
		this.parentData.arrViewSearchFiles = [];
		this.parentData.arrViewAllFiles = this.parentData.arrFiles;
		this.paginationData.intTotalRecords = this.parentData.arrFiles.length;
		this.parentState.isShowModal = true;
		this.parentState.bolSpinner = true;
		this.paginationHelper();	
		this.parentData = { ...this.parentData };
        this.parentState = { ...this.parentState };
	}

	// This is to hide modal popup
	hideModalBox() {
		if(this.parentData.setChangedNames!=null){
			this.parentData.setChangedNames.clear();
			this.template.querySelector('c-view-files').handleRefresh();
		}
		this.parentState.bolSpinner = true;
		this.parentData.strTitle = this.CUSTOM_LABELS.Related_External_Files;
		this.handleRetrieveExternalFiles();
		this.parentState.isShowModal = false;
		this.paginationData.intPageNumber = 1;
		this.sortingState.bolDateDown = true;
		this.sortingState.bolNameUp = false;
		this.sortingState.bolNameDown = false;
		this.sortingState.bolSizeUp = false;
		this.sortingState.bolSizeDown = false;
		this.sortingState.bolDateUp = false;
		this.sortingState.bolTypeDown = false;
		this.sortingState.bolTypeUp = false;
		this.parentData.strSortedColumn = "LastModifiedDate";
		this.parentData.strSearchValue = "";
	}

	get bolDisableFirst() {
		return this.paginationData.intPageNumber === 1;
	}

	get bolDisableLast() {
		return this.paginationData.intPageNumber === this.paginationData.intTotalPages;
	}

	get dynamicModal() {
		return this.bolDelete ? 'modelContent5' : 'modelContent4';
	}

	// To handle sorting in the view all screen
	sortRecs(event) {
		this.sortingState.bolNameUp = false;
		this.sortingState.bolNameDown = false;
		this.sortingState.bolSizeUp = false;
		this.sortingState.bolSizeDown = false;
		this.sortingState.bolDateUp = false;
		this.sortingState.bolDateDown = false;
		this.sortingState.bolTypeUp = false;
		this.sortingState.bolTypeDown = false;
		let colName = event.target.name;
		if (this.parentData.strSortedColumn === colName) {
			this.parentData.strSortedDirection = this.parentData.strSortedDirection === "asc" ? "desc" : "asc";
		} else {
			this.parentData.strSortedDirection = "asc";
		}
		let isReverse = this.parentData.strSortedDirection === "asc" ? 1 : -1;
		this.parentData.strSortedColumn = colName;

		switch (colName) {
			case "strFileName":
				if (this.parentData.strSortedDirection === "asc") {
					this.sortingState.bolNameUp = true;
				} else {
					this.sortingState.bolNameDown = true;
				}
				break;

			case "strFileType":
				if (this.parentData.strSortedDirection === "asc") {
					this.sortingState.bolTypeUp = true;
				} else {
					this.sortingState.bolTypeDown = true;
				}
				break;

			case "dblSize":
				if (this.parentData.strSortedDirection === "asc") {
					this.sortingState.bolSizeUp = true;
				} else {
					this.sortingState.bolSizeDown = true;
				}
				break;

			case "LastModifiedDate":
				if (this.parentData.strSortedDirection === "asc") {
					this.sortingState.bolDateUp = true;
				} else {
					this.sortingState.bolDateDown = true;
				}
				break;
			default:
		}

		// sort the data
		if (this.parentData.strSortedColumn === "LastModifiedDate") {
			this.parentData.arrFiles = this.parentData.arrFiles.sort((a, b) => {
				a = new Date(a[colName]);
				b = new Date(b[colName]);
				return a > b ? 1 * isReverse : -1 * isReverse;
			});
		} else if (this.parentData.strSortedColumn !== "dblSize") {
			this.parentData.arrFiles = JSON.parse(JSON.stringify(this.parentData.arrFiles)).sort((a, b) => {
				a = a[colName] ? a[colName].toLowerCase() : ""; // Handle null values
				b = b[colName] ? b[colName].toLowerCase() : "";
				return a > b ? 1 * isReverse : -1 * isReverse;
			});
		} else {
			this.parentData.arrFiles = this.parentData.arrFiles.sort((a, b) => {
				a = a[colName];
				b = b[colName];
				return a > b ? 1 * isReverse : -1 * isReverse;
			});
		}
		if (this.parentData.strSearchValue === "") {
			this.paginationHelper();
		} else {
			this.getSearchResults();
		}
	}

	// To handle file preview, download, delete actions
	handlePrevDelDownload(event) {		
		try {
			if(event.currentTarget.dataset.straction == 'Delete'){
				this.strStraction = event.currentTarget.dataset.straction;
				this.strInvokingscreen = event.currentTarget.dataset.invokingscreen;
				this.strTargetId = event.currentTarget.dataset.strid;
				this.strFileName = event.currentTarget.dataset.filename;

				this.bolDelete = true;
			}else{
				this.handleActions(event.currentTarget.dataset.straction, event.currentTarget.dataset.invokingscreen, event.currentTarget.dataset.strid, event.currentTarget.dataset.strFileName);
				this.bolDelete = false;
			}
		} catch (error) {
			console.log('err '+ error.message);
		}

	}



	// To handle file preview, download, delete actions from child screen
	handlePrevDelDownloadChild(event) {		
		this.handleActions(event.detail.strStraction, event.detail.strInvokingscreen, event.detail.strTargetId, event.detail.strFileName);
	}

	// To handle logics of preview, download and delete
	handleActions(strAction, strInvokingScreen, strTargetId, strFileName) {
		try {
		let objCurrFile;
		if (this.parentData.objActiveStorageDetails.strStorageType == "Amazon S3") {
			let strReqMethod = strAction === "Delete" ? "DELETE" : "GET";
			if (strInvokingScreen === "ViewAll") {
				objCurrFile = this.parentData.arrViewAllFiles.find(({ strId }) => strId === strTargetId);
			} else {
				objCurrFile = this.parentData.arrTempFiles.find(({ strId }) => strId === strTargetId);
			}
			// strTargetId is the External_File_Link__c Id - the server looks up the file and verifies
			// record access itself rather than trusting a client-supplied S3 key directly.
			getPreSignedURL({ strKy: strTargetId, strReqMethod: strReqMethod })
				.then((result) => {					
					this.parentData.strFileURL = result;
					switch (strAction) {
						case "Preview":
							this.handlePreview(result, objCurrFile);
							break;
						case "Download":
							this.parentState.bolSpinner = true;
							this.handleDownload(result, objCurrFile);
							break;
						case "Delete":
							this.parentState.bolSpinner = true;							
							this.handleDelete(objCurrFile, result, strFileName);
							break;
						default:
					}
				})
				.catch((error) => {
					this.objLogErrorWrapper = {};
					this.objLogErrorWrapper.relatedTo = "ViewFilesController.getPresignedURL";
					this.objLogErrorWrapper.summary = "";
					this.objLogErrorWrapper.message = error;
					this.objLogErrorWrapper.batchJobId = "";
					this.objLogErrorWrapper.recordIds = this.recordId;
					this.objLogErrorWrapper.statusCode = "";
					logError({ objLogErrorWrapper : this.objLogErrorWrapper });				
					this.showNotification(Error, this.CUSTOM_LABELS.Something_went_wrong, "error");
				});
		} else {
			// For Storage Services Other Than AWS S3.
		}
		} catch (error) {
			console.log('Error -- ',error.message);			
		}
		
	}

	// To handle file preview
	handlePreview(result, objCurrFile) {
		try {
			if (this.parentData.arrPreviewFormats.includes('.' + objCurrFile.strFileType)) {
				this.parentData.bolShowPreviewModal = true;
				this.preSignedUrl = result;
			} else {
				const event = new ShowToastEvent({
					title: Warning + '!',
					message: this.CUSTOM_LABELS.The_selected_file_format_doesn_t_support_the_preview + "!",
					variant: 'warning',
					mode: 'sticky'
				});
				this.dispatchEvent(event);
			}
		} catch (error) {
			this.showNotification(Error, this.CUSTOM_LABELS.Something_went_wrong, "error");
		}
	}

	hidePreviewModalBox() {
		this.parentData.bolShowPreviewModal = false;
	}

	// To handlefile download
	handleDownload(strPresigned, objCurrFile) {		
		if (objCurrFile.dblSize <= 6000000) {
			getFileFromAmazonS3({ strpresigned: strPresigned, strEFId: objCurrFile.strId, strRelatedTo: objCurrFile.strRelatedTo })
				.then((result) => {					
					let strFileName = objCurrFile.strFileName;
					if (!objCurrFile.strFileName.includes('.' + objCurrFile.strFileType)) {
						strFileName = strFileName.split('.')[0];
						strFileName += '.' + objCurrFile.strFileType;
					}
					const binaryString = window.atob(result);
					const bytes = new Uint8Array(binaryString.length);
					for (let i = 0; i < binaryString.length; i++) {
						bytes[i] = binaryString.charCodeAt(i);
					}
					const blob = new Blob([bytes], { type: "application/octet-stream" });
					const fileUrl = URL.createObjectURL(blob);
					const anchor = document.createElement("a");
					anchor.href = fileUrl;
					anchor.target = "_blank";
					anchor.download = strFileName;
					document.body.appendChild(anchor);
					anchor.click();
					document.body.removeChild(anchor);
					URL.revokeObjectURL(anchor.href);

					this.showNotification(Success, this.CUSTOM_LABELS.File_downloaded_successfully, "success");
					this.parentState.bolSpinner = false;
					this.parentState.bolFilesSelected = false;
				})
				.catch((error) => {
					this.objLogErrorWrapper = {};
					this.objLogErrorWrapper.relatedTo = "ViewFilesController.getFileFromAmazonS3";
					this.objLogErrorWrapper.summary = "";
					this.objLogErrorWrapper.message = error;
					this.objLogErrorWrapper.batchJobId = "";
					this.objLogErrorWrapper.recordIds = this.recordId;
					this.objLogErrorWrapper.statusCode = "";
					logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });					
					this.showNotification(this.CUSTOM_LABELS.Something_went_wrong, this.CUSTOM_LABELS.Unable_to_download, "error");
					this.parentState.bolSpinner = false;
				});
		} else {
			const event = new ShowToastEvent({
				title: Warning + '!',
				message: this.CUSTOM_LABELS.Unable_to_download_msg,
				messageData: [
					{
						url: strPresigned,
						label: "Click",
					},
				],
				variant: 'warning',
				mode: 'sticky'
			});
			this.dispatchEvent(event);
			this.parentState.bolSpinner = false;
		}
	}

	// To handle file delete
	handleDelete(objCurrFile, strPreSignedURL, strFileName) {
		let arrEFLId = [objCurrFile.strId];
		let strMoveToBin = this.parentData.mapConfigurations["Recycle_Bin"];
		
		delExternalFileLinks({ lstExternalFileLinkIds: arrEFLId, strMoveToBin: strMoveToBin, strPreSignedURL: strPreSignedURL })
			.then((result) => {
				if (result === "success") {
					let SNo = 0;
					for (let i = 0; i < this.parentData.arrFiles.length; i++) {
						if (this.parentData.arrFiles[i].strId === arrEFLId[0]) {
							this.parentData.arrFiles.splice(i, 1);
						}
						if (i !== this.parentData.arrFiles.length) {
							this.parentData.arrFiles[i].SNo = ++SNo;
						}
					}
					if (this.parentData.strSearchValue == "") {
						this.parentData.arrTempFiles = this.parentData.arrFiles.slice(0, 5);
						this.parentData.arrViewAllFiles = [...this.parentData.arrFiles];
						this.paginationData.intTotalRecords = this.parentData.arrFiles.length;
						this.paginationData.intPageSize = this.paginationData.arrPageSizeOptions[0];
						this.paginationHelper();
					} else {
						this.getSearchResults();
					}

					this.parentData.strTitle = '';
					if (this.parentData.arrFiles.length > 0) {
						this.parentData.strTitle = this.CUSTOM_LABELS.Related_External_Files + "(" + this.parentData.arrFiles.length + ")";
					} else {
						this.parentState.bolFiles = false;
						this.parentData.strTitle = this.CUSTOM_LABELS.Related_External_Files;
						this.hideModalBox();
					}
					let child = this.template.querySelector('c-upload-files');
					child.handleDeletedExternalFiles(strFileName);
					this.showNotification(Success, this.CUSTOM_LABELS.File_deleted_successfully, "success");
				} else if (result === "File Not Found") {
					this.showNotification(Warning, this.CUSTOM_LABELS.File_not_found_for_deletion + "!", "warning");
				} else {
					this.showNotification(Error, this.CUSTOM_LABELS.File_deletion_failed + "!", "error");
				}
				this.template.querySelector('c-view-files').handleRefresh();
				this.parentState.bolFilesSelected = false;
				this.parentState.bolSpinner = false;
			})
			.catch((error) => {
				this.parentState.bolSpinner = false;
				this.showNotification(Error, this.CUSTOM_LABELS.Error_Found_when_deleting_the_record + error.message, "error");
			});
	}

	// To show/hide edit icon in table
	onRowHighlightRemove() {
		for (let i = 0; i < this.parentData.arrViewAllFiles.length; i++) {
			this.parentData.arrViewAllFiles[i].bolShowEdit = false;
		}
	}

	// To show/hide edit icon in table
	onRowHighlight(event) {
		for (let i = 0; i < this.parentData.arrViewAllFiles.length; i++) {
			if (this.parentData.arrViewAllFiles[i].strName === event.currentTarget.dataset.name) {
				this.parentData.arrViewAllFiles[i].bolShowEdit = this.parentData.arrViewAllFiles[i].bolEditField === true ? false : true;	
			} else {
				this.parentData.arrViewAllFiles[i].bolShowEdit = false;
			}
		}
	}

	// To handle file name edit logics in the view all screen
	handleEdit(event) {
		this.template.querySelector('c-view-files').handleRefresh();
		this.parentState.bolClear = true;
		for (let i = 0; i < this.parentData.arrViewAllFiles.length; i++) {
			if(this.parentData.setChangedNames.size == 0) {
				this.parentData.setFileNames.add(this.parentData.arrViewAllFiles[i].strFileName);
			}
			if (this.parentData.arrViewAllFiles[i].strName === event.currentTarget.dataset.name ) {
				this.parentData.mapFileNameOld.set(event.currentTarget.dataset.strid,this.parentData.arrViewAllFiles[i].strFileName);
				this.parentData.arrViewAllFiles[i].bolEditField = true;
			} else {
				this.parentData.arrViewAllFiles[i].bolEditField = false;
			}
		}
		for (let i = 0; i < this.parentData.arrViewAllFiles.length; i++) {
			if(this.parentData.setChangedNames != null && this.parentData.setChangedNames.has(this.parentData.arrViewAllFiles[i].strName)){
					this.parentData.arrViewAllFiles[i].bolEditField = true;
				}
		}
	}

	// To handle search 
	handleSearch(event) {
		this.parentData.strSearchValue = event.detail.value;
		this.parentState.bolSearch = this.parentData.strSearchValue.length > 0 ? true : false;
		this.getSearchResults();
	}

	// To handle serach logics
	getSearchResults() {
		this.parentData.arrViewSearchFiles = [];
		let SNo = 0;
		for (let i = 0; i < this.parentData.arrFiles.length; i++) {
			if (this.parentData.arrFiles[i].strFileName.toLowerCase().includes(this.parentData.strSearchValue.toLowerCase()) || this.parentData.arrFiles[i].strFileType.toLowerCase().includes(this.parentData.strSearchValue.toLowerCase())) {
				this.parentData.arrFiles[i].SNo = ++SNo;
				this.parentData.arrViewSearchFiles.push(this.parentData.arrFiles[i]);
			}
		}
		this.paginationData.intTotalRecords = this.parentData.arrViewSearchFiles.length;
		if (this.parentData.strSearchValue === "") {
			this.handleViewAll();
		} else {
			this.paginationHelper();
		}
	}

	// To handle pagination
	handleRecordsPerPage(event) {
		this.paginationData.intPageSize = event.target.value;
		this.paginationHelper();
	}

	previousPage() {
		this.paginationData.intPageNumber = this.paginationData.intPageNumber - 1;
		this.paginationHelper();
	}

	nextPage() {
		this.paginationData.intPageNumber = this.paginationData.intPageNumber + 1;
		this.paginationHelper();
	}

	firstPage() {
		this.paginationData.intPageNumber = 1;
		this.paginationHelper();
	}

	lastPage() {
		this.paginationData.intPageNumber = this.paginationData.intTotalPages;
		this.paginationHelper();
	}

	paginationHelper() {
		this.parentState.bolSpinner = false;
		this.parentData.arrViewAllFiles = [];
		// calculate total pages
		this.paginationData.intPageSize = this.paginationData.arrPageSizeOptions[0]
		this.paginationData.intTotalPages = Math.ceil(this.paginationData.intTotalRecords / this.paginationData.intPageSize);
		
		// set page number
		if (this.paginationData.intPageNumber <= 1) {
			this.paginationData.intPageNumber = 1;
			this.paginationData.intStartNumber = 1;
			this.paginationData.intEndNumber = this.paginationData.intTotalPages === 1 ? this.paginationData.intTotalRecords : this.paginationData.intPageSize;
		} else if (this.paginationData.intPageNumber >= this.paginationData.intTotalPages) {
			this.paginationData.intPageNumber = this.paginationData.intTotalPages;
			this.paginationData.intStartNumber = (this.paginationData.intPageNumber - 1) * this.paginationData.intPageSize + 1;
			this.paginationData.intEndNumber = this.paginationData.intTotalRecords;
		} else {
			this.paginationData.intStartNumber = (this.paginationData.intPageNumber - 1) * this.paginationData.intPageSize + 1;
			this.paginationData.intEndNumber = this.paginationData.intStartNumber + (this.paginationData.intPageSize - 1);
		}
		// set records to display on current page
		if (this.parentData.strSearchValue != "") { // If files are in search view
			if (this.parentData.arrViewSearchFiles.length > 0) {
				let tempSNo = (this.paginationData.intPageNumber - 1) * this.paginationData.intPageSize + 1;
				for (let i = (this.paginationData.intPageNumber - 1) * this.paginationData.intPageSize; i < this.paginationData.intPageNumber * this.paginationData.intPageSize; i++) {
					if (i === this.paginationData.intTotalRecords) {
						break;
					}
					this.parentData.arrViewSearchFiles[i].SNo = tempSNo++;
					this.parentData.arrViewAllFiles.push(this.parentData.arrViewSearchFiles[i]);
				}
			} else {
				this.paginationData.intPageNumber = 1;
				this.paginationData.intTotalPages = 1;
				this.paginationData.intStartNumber = 0;
				this.paginationData.intEndNumber = 0;
			}
			this.parentState.bolSearch = false;
		} else {
			let tempSNo = (this.paginationData.intPageNumber - 1) * this.paginationData.intPageSize + 1;
			for (let i = (this.paginationData.intPageNumber - 1) * this.paginationData.intPageSize; i < this.paginationData.intPageNumber * this.paginationData.intPageSize; i++) {
				if (i === this.paginationData.intTotalRecords) {
					break;
				}
				if(this.parentData.arrViewAllFiles.strExternalFileId != this.parentData.arrFiles[i].strExternalFileId){
					this.parentData.arrFiles[i].SNo = tempSNo++;
					this.parentData.arrViewAllFiles.push(this.parentData.arrFiles[i]);
				}
				
			}
		}

	}

	// To handle file name input change
	onfileNameChange(event) {
		let fileUrl = "";
		let fileName = "";
		if(!this.parentData.setOldFileName.has(event.currentTarget.dataset.filename)){
			this.parentData.setOldFileName.add(event.currentTarget.dataset.filename);
		}	
		if (event.detail.value == '' || event.detail.value == null) {
			this.showNotification(Error, this.CUSTOM_LABELS.Filename_should_not_be_empty, "error");
			this.parentState.bolSave = false;
		} else {
			for (let i = 0; i < this.parentData.arrViewAllFiles.length; i++) {
				if (this.parentData.arrViewAllFiles[i].strName === event.currentTarget.dataset.name) {
					if (this.parentData.arrViewAllFiles[i].strFileName !== event.detail.value) {
						this.parentData.arrViewAllFiles[i].strFileName = event.detail.value;
						fileUrl = this.parentData.arrViewAllFiles[i].strFileURL.substring(0, this.parentData.arrViewAllFiles[i].strFileURL.indexOf("/", + this.parentData.arrViewAllFiles[i].strFileURL.indexOf(".com/") + 5) + 1);
						fileName = event.detail.value;
						this.parentData.arrViewAllFiles[i].strFileURL = fileUrl+fileName+'.'+this.parentData.arrViewAllFiles[i].strFileType;
						this.parentData.setChangedNames.add(this.parentData.arrViewAllFiles[i].strName);
					}
				}
			}
			this.parentState.bolSave = true;
		}
		this.parentState.bolClear = true;
	}

	// To update the file name
	async handleNameSave(event) {
		let saveType = event.currentTarget.dataset.type;
		let fileName = event.currentTarget.dataset.name;

		if (saveType === "RowSave") {
			this.parentData.arrNameUpdateFiles = [];
			let fileToUpdate = this.parentData.arrFiles.find(file => file.strName === fileName);
			if (fileToUpdate) {
				if (!this.parentData.setFileNames.has(fileToUpdate.strFileName)) {
					this.parentData.arrNameUpdateFiles.push(fileToUpdate);
					this.parentData.setChangedNames.delete(fileName);
				} else {
					this.showNotification(Error, this.CUSTOM_LABELS.This_file_name_already_exists, "error");
				}
			}
		} else if (saveType === "MainSave") {
			let changedFiles = this.parentData.arrFiles.filter(file => this.parentData.setChangedNames.has(file.strName));
			changedFiles.forEach(file => {
				if (!this.parentData.setFileNames.has(file.strFileName)) {
					this.parentData.arrNameUpdateFiles.push(file);
				} else {
					this.showNotification(Error, this.CUSTOM_LABELS.This_file_name_already_exists, "error");
				}
			});
			this.parentData.setChangedNames.clear();
		}

		if (this.parentData.arrNameUpdateFiles.length > 0 ) {
			await updateFileNames({ lstEFWrapper: this.parentData.arrNameUpdateFiles })
				.then((result) => {				
					if (result === true) {
						this.parentState.bolSave = false;
						this.parentState.bolClear = false;
						for (let i = 0; i < this.parentData.arrFiles.length; i++) {
							if(this.parentData.setChangedNames != null && this.parentData.setChangedNames.has(this.parentData.arrFiles[i].strName)){
								this.parentData.arrFiles[i].bolEditField = true;
								this.parentState.bolSave = true;
								this.parentState.bolClear = true;
							} else{
								this.parentData.arrFiles[i].bolEditField = false;
							}
						}
						if(saveType == "RowSave"){
							for(let i = 0; i < Array.from(this.parentData.setOldFileName).length; i++){
								if(this.parentData.setFileNames.has(Array.from(this.parentData.setOldFileName)[i])){
									this.parentData.setFileNames.delete(Array.from(this.parentData.setOldFileName)[i]);
									break;
								}
							}
						}else{
							this.parentData.setFileNames.clear();
						}
						if (this.parentData.arrNameUpdateFiles.length > 1) {
							this.showNotification(Success, this.CUSTOM_LABELS.File_Names_are_updated_successfully, "success");
						} else {
							this.showNotification(Success, this.CUSTOM_LABELS.File_Name_is_updated_successfully, "success");
						}
					} else {
						this.showNotification(Error, this.CUSTOM_LABELS.Something_went_wrong, "error");
					}
					this.template.querySelector('c-view-files').handleRefresh();
				})
				.catch(() => {
					this.showNotification(Error, this.CUSTOM_LABELS.Something_went_wrong, "error");
				});
		}
		this.parentData.arrNameUpdateFiles = [];
	}

	// To rollback file name change
	handleNameClear(event) {
		let intIndex = this.parentData.arrViewAllFiles.findIndex(({ strName }) => strName === event.currentTarget.dataset.name);
		this.parentData.arrViewAllFiles[intIndex].bolEditField = false;
		this.parentData.arrViewAllFiles[intIndex].strFileName = this.parentData.mapFileNameOld.get(event.currentTarget.dataset.strid);;

		if(this.parentData.setChangedNames.size === 1 && this.parentData.setChangedNames.has(event.currentTarget.dataset.name) ){
			this.parentData.setChangedNames.clear();
			this.parentState.bolSave = false;
		}
		if(this.parentData.setChangedNames != null && this.parentData.setChangedNames.has(event.currentTarget.dataset.name)){
			this.parentData.setChangedNames.delete(event.currentTarget.dataset.name);
			this.parentData.arrViewAllFiles[intIndex].bolSave = false;
			this.parentData.arrViewAllFiles[intIndex].bolClear = false;
		}
	}

	hideDeleteModal() {
		this.bolDelete = false;		
	}

	handleConfirmDelete(){
		this.handleActions(this.strStraction, this.strInvokingscreen, this.strTargetId, this.strFileName);
		this.bolDelete = false;
	}

	// To handle input files for upload
	handleSelectedFiles(event) {
		this.parentData.arrSelectedFilesToUpload = [...event.detail.arrSelectedFiles];
	}

	// Generic toast method
	showNotification(strTitle, strMessage, strType) {
		let strMode = strType === "error" ? "sticky" : "dismissable";
		const objToastEvent = new ShowToastEvent({
			title: strTitle,
			message: strMessage,
			variant: strType,
			mode: strMode
		});
		this.dispatchEvent(objToastEvent);
	}

}