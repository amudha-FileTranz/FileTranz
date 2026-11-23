/*
 * Purpose : To upload local files to external system.
 * Author  : Giri
 */

import { loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, api, track } from "lwc";
// Importing Apex methods
import createExternalFileLinks from "@salesforce/apex/UploadFilesController.createExternalFileLinks";
import createExternalFiles from "@salesforce/apex/UploadFilesController.createExternalFiles";
import generateAuthHeaderForAWS from "@salesforce/apex/UploadFilesController.generateAuthHeaderForAWS";
import retrieveRelatedExternalFiles from "@salesforce/apex/UploadFilesController.retrieveRelatedExternalFiles";
import logError from "@salesforce/apex/ErrorLogger.logError";
// Importing Static Resources
import IMAGES from "@salesforce/resourceUrl/FTstaticResource";
import styles from "@salesforce/resourceUrl/ftCSS";
import toastCSS from "@salesforce/resourceUrl/toastCSS";
// Importing Custom labels to provide multi language support
import Add_Files from "@salesforce/label/c.Add_Files";
import Attachment from "@salesforce/label/c.Attachment";
import Below_file_types_are_restricted_for_upload from "@salesforce/label/c.Below_file_types_are_restricted_for_upload";
import Below_files_are from "@salesforce/label/c.Below_files_are";
import Below_files_are_larger_than_the_maximum_size_configured_for_upload from "@salesforce/label/c.Below_files_are_larger_than_the_maximum_size_configured_for_upload";
import Below_files_are_uploaded_successfully from "@salesforce/label/c.Below_files_are_uploaded_successfully";
import Cancel from "@salesforce/label/c.Cancel";
import Cancelled from "@salesforce/label/c.Cancelled";
import Completed from "@salesforce/label/c.Completed";
import Drag_your_files_here from "@salesforce/label/c.Drag_your_files_here";
import Error from "@salesforce/label/c.Error";
import File_Icon from "@salesforce/label/c.File_Icon";
import File_Upload from "@salesforce/label/c.File_Upload";
import File_upload_is_failed from "@salesforce/label/c.File_upload_is_failed";
import Inprogress from "@salesforce/label/c.Inprogress";
import Loading from "@salesforce/label/c.Loading";
import MB from "@salesforce/label/c.MB";
import Max_Size from "@salesforce/label/c.Max_Size";
import Max_File from "@salesforce/label/c.Max_File";
import Per_Upload from "@salesforce/label/c.Per_Upload";
import files from "@salesforce/label/c.files";
import Maximum_Files_Warning from "@salesforce/label/c.Maximum_Files_Warning";
import Please_select_upto from "@salesforce/label/c.Please_select_upto";
import Success from "@salesforce/label/c.Success";
import Upload_File from "@salesforce/label/c.Upload_File";
import Upload_here from "@salesforce/label/c.Upload_here";
import Warning from "@salesforce/label/c.Warning";
import already_selected_for_upload from "@salesforce/label/c.already_selected_for_upload";
import file from "@salesforce/label/c.file";
import files_selected from "@salesforce/label/c.files_selected";
import Something_went_wrong from "@salesforce/label/c.Something_went_wrong";
import of from "@salesforce/label/c.of";
import There_is_already_a_file_s_with_same_name_in_this_location from "@salesforce/label/c.There_is_already_a_file_s_with_same_name_in_this_location";
import Files_Upload from "@salesforce/label/c.Files_Upload";

// Constants
const API_FAILURE = "API Failure";
const UPLOAD_CHUNK_SIZE = 5 * 1024 * 1024;

export default class UploadFiles extends LightningElement {
	wakeLock = null;
	@api recordId;
	@api parentState;
	@api parentData;
	@track data = {
		selectedFilesToUpload: [],
		intSelectedFilesToUpload: 0,
		arrAcceptedFormats: [],
		tempSelectedFilesToUpload: [],
		intMaximumFileSize: 0
	};
	@track state;
	@track bolShowFooter = true;
	@track bolCSSLoaded = false;
	@track bolUploadInprogress = false;
	@track objGenerateAuthHeaderForAWSWrapper = {};
	strFtIconUrl = IMAGES + "/FTstaticResource/ft_icon.svg";
	strFtUploadUrl = IMAGES + "/FTstaticResource/ft_fileupload.svg";
	strUploadId = "";
	arrRelatedFileNames = [];
	//Custom labels
	CUSTOM_LABELS = {
		File_Upload,
		Upload_File,
		Cancel,
		files_selected,
		of,
		Add_Files,
		File_Icon,
		Attachment,
		Below_files_are_uploaded_successfully,
		File_upload_is_failed,
		Please_select_upto,
		Maximum_Files_Warning,
		MB,
		already_selected_for_upload,
		Error,
		Success,
		Below_files_are,
		Below_file_types_are_restricted_for_upload,
		Below_files_are_larger_than_the_maximum_size_configured_for_upload,
		Inprogress,
		Completed,
		Cancelled,
		Loading,
		Upload_here,
		Max_Size,
		Per_Upload,
		Max_File,
		Drag_your_files_here,
		Something_went_wrong,
		file,
		Files_Upload,
		files
	};

	connectedCallback() {
		window.addEventListener("beforeunload", this.handleBeforeUnload.bind(this));
		this.state = JSON.parse(JSON.stringify(this.parentState));
		Promise.all([loadStyle(this, styles)]);
		this.data.intMaximumFileSize = this.parentData.intMaximumFileSize * 1024 * 1024;		
		this.data.arrAcceptedFormats = this.parentData.arrAcceptedFormats;
		retrieveRelatedExternalFiles({ strRecordId: this.recordId })
			.then((result) => {
				if (result != null && result.length > 0) {
					result.forEach((item) => {
						this.arrRelatedFileNames.push(item.strFileName.replace(/\.[^/.]+$/, ""));
					});
				}
			})
			.catch((error) => {
				this.showNotification(Error, this.CUSTOM_LABELS.Something_went_wrong, "error");
				this.parentState.bolSpinner = false;
			});

	}

	renderedCallback() {
		if (this.bolCSSLoaded) return;
		this.bolCSSLoaded = true;
		loadStyle(this, toastCSS)
			.then(() => { })
			.catch((error) => {
				this.showNotification(Error + "!", error.message, "error");
			});
	}

	disconnectedCallback() {
		// Remove event listener when the component is disconnected from the DOM
		window.removeEventListener("beforeunload", this.handleBeforeUnload.bind(this));
	}

	// To show warning when user closing the browser window/tab while upload is in progress
	handleBeforeUnload(event) {
		if (this.bolUploadInprogress) {
			event.preventDefault();
		}
	}

	handleDragOver(event) {
		event.preventDefault();
		event.dataTransfer.dropEffect = 'copy';
	}

	handleDrop(event) {
		event.preventDefault();
		let droppedFiles = event.dataTransfer.files;

		if (droppedFiles.length > 0) {
			this.handleSelectedFiles({ target: { files: droppedFiles } });
		}
	}

	handleButtonClick(event) {
		try {
			event.stopPropagation();
			this.template.querySelector('[data-id="fileInput"]').click();
		} catch (error) {
			console.log('Error - drop -- ',error.message);
		}

	}

	// To get the file name from the user"s selection
	async handleSelectedFiles(event) {
		this.state.bolSpinner = true;
		let intNoOfFiles = this.data.intSelectedFilesToUpload + event.target.files.length;		
		
		if (intNoOfFiles > this.parentData.intAllowFilesToUpload) {
			this.showNotification(Error + "!", this.CUSTOM_LABELS.Please_select_upto + " " + this.parentData.intAllowFilesToUpload + " " + this.CUSTOM_LABELS.Maximum_Files_Warning + "!", "error");
		} else if (event.target.files.length > 0) {
			this.data.tempSelectedFilesToUpload = event.target.files;
			this.validateSelectedFiles();
		}
		this.state.bolSpinner = false;
	}

	// To handle add files logics from parent
	@api handleSelectedFilesInAddFiles(arrSelectedFiles) {
		this.data.tempSelectedFilesToUpload = Array.from(arrSelectedFiles);
		this.validateSelectedFiles();
	}

	// To validate the input files
	validateSelectedFiles() {
		let arrSelectedFiles = [];
		let strRepeatedFileNames = "",
			strFileTypeNotSupportedFileNames = "",
			intRepeatedFile = 1,
			intNotSupportedFileTypes = 1,
			intMaximumSizeFile = 1,
			strMaximumFileSizeNames = "",
			strDuplicateFileNames = "",
			intDuplicateFiles = 1;

		if (this.data.selectedFilesToUpload.length === 0) {
			for (let i = 0; i < this.data.tempSelectedFilesToUpload.length; i++) {
				let fileType = "." + this.data.tempSelectedFilesToUpload[i].type.trim();
				if (this.arrRelatedFileNames.includes(this.data.tempSelectedFilesToUpload[i].name.replace(/\.[^/.]+$/, ""))) {
					strDuplicateFileNames += intDuplicateFiles + ". " + this.data.tempSelectedFilesToUpload[i].name + " \n";
					intDuplicateFiles++;
				} else if (this.data.tempSelectedFilesToUpload[i].size > this.data.intMaximumFileSize) {
					strMaximumFileSizeNames += intMaximumSizeFile + ". " + this.data.tempSelectedFilesToUpload[i].name + " \n";
					intMaximumSizeFile++;
				} else if (
					this.data.arrAcceptedFormats.includes(this.data.tempSelectedFilesToUpload[i].name.substring(this.data.tempSelectedFilesToUpload[i].name.lastIndexOf(".")).toLowerCase()) ||
					this.data.arrAcceptedFormats.includes(fileType) || this.data.tempSelectedFilesToUpload[i].id != undefined
				) {
					arrSelectedFiles.push(this.data.tempSelectedFilesToUpload[i]);
					this.arrRelatedFileNames.push(this.data.tempSelectedFilesToUpload[i].name.replace(/\.[^/.]+$/, ""));
				} else {
					strFileTypeNotSupportedFileNames += intNotSupportedFileTypes + ". " + this.data.tempSelectedFilesToUpload[i].name + " \n";
					intNotSupportedFileTypes++;
				}
			}
		} else {
			for (let i = 0; i < this.data.tempSelectedFilesToUpload.length; i++) {
				let bolFileAvailable = false;
				if (this.arrRelatedFileNames.includes(this.data.tempSelectedFilesToUpload[i].name)) {
					bolFileAvailable = true;
					strDuplicateFileNames += intDuplicateFiles + ". " + this.data.tempSelectedFilesToUpload[i].name + " \n";
					intDuplicateFiles++;
				} else if (this.data.tempSelectedFilesToUpload[i].size > this.data.intMaximumFileSize) {
					strMaximumFileSizeNames += intMaximumSizeFile + ". " + this.data.tempSelectedFilesToUpload[i].name + " \n";
					intMaximumSizeFile++;
				} else if (
					this.data.arrAcceptedFormats.includes(this.data.tempSelectedFilesToUpload[i].name.substring(this.data.tempSelectedFilesToUpload[i].name.lastIndexOf(".")).toLowerCase()) ||
					this.data.arrAcceptedFormats.includes(fileType)
				) {
				} else {
					bolFileAvailable = true;
					strFileTypeNotSupportedFileNames += intNotSupportedFileTypes + ". " + this.data.tempSelectedFilesToUpload[i].name + " \n";
					intNotSupportedFileTypes++;
				}
				if (!bolFileAvailable) {
					for (let j = 0; j < this.data.selectedFilesToUpload.length; j++) {
						if (this.data.tempSelectedFilesToUpload[i].name === this.data.selectedFilesToUpload[j].name) {
							bolFileAvailable = true;
							strRepeatedFileNames += intRepeatedFile + ". " + this.data.tempSelectedFilesToUpload[i].name + " \n";
							intRepeatedFile++;
						}
					}
				}
				if (!bolFileAvailable) {
					arrSelectedFiles.push(this.data.tempSelectedFilesToUpload[i]);
					this.arrRelatedFileNames.push(this.data.tempSelectedFilesToUpload[i].name.replace(/\.[^/.]+$/, ""));
				}
			}
		}
		
		if (strRepeatedFileNames != "") {
			this.showNotification(Warning + "!", this.CUSTOM_LABELS.Below_files_are + " " + this.CUSTOM_LABELS.already_selected_for_upload + "\n" + strRepeatedFileNames, "warning");
		}
		if (strDuplicateFileNames != "") {
			this.showNotification(Warning + "!", There_is_already_a_file_s_with_same_name_in_this_location + "\n" + strDuplicateFileNames, "warning");
		}
		if (strFileTypeNotSupportedFileNames != "") {
			this.showNotification(Warning + "!", this.CUSTOM_LABELS.Below_file_types_are_restricted_for_upload + ", " + "\n" + strFileTypeNotSupportedFileNames, "warning");
		}

		if (strMaximumFileSizeNames != "") {
			this.showNotification(Warning + "!", this.CUSTOM_LABELS.Below_files_are_larger_than_the_maximum_size_configured_for_upload + ", " + "\n" + strMaximumFileSizeNames, "warning");
		}
		if (arrSelectedFiles.length > 0) {
			arrSelectedFiles.forEach((item) => {
				switch (true) {
					case item.type.includes("image") ||
						item.type.includes("png") ||
						item.type.includes("jpeg") ||
						item.type.includes("gif") ||
						item.type.includes("bmp") ||
						item.type.includes("svg") ||
						item.type.includes("vnd.adobe") ||
						item.type.includes("webp") ||
						item.type.includes("jpg") ||
						item.type.includes("tif"):
						item.icon = "doctype:image";
						break;
					case item.type.includes("csv"):
						item.icon = "doctype:csv";
						break;
					case item.type.includes("pdf"):
						item.icon = "doctype:pdf";
						break;
					case item.type.includes("plain") || item.type.includes("txt"):
						item.icon = "doctype:txt";
						break;
					case item.type.includes("sheet"):
						item.icon = "doctype:gsheet";
						break;
					case item.type.includes("document"):
						item.icon = "doctype:gdoc";
						break;
					case item.type.includes("xml"):
						item.icon = "doctype:xml";
						break;
					case item.type.includes("postscript") || item.type.includes("eps") || item.type.includes("ai"):
						item.icon = "doctype:ai";
						break;
					case item.type.includes("audio") || item.type.includes("mp3") || item.type.includes("m4a"):
						item.icon = "doctype:audio";
						break;
					case item.type.includes("mp4"):
						item.icon = "doctype:mp4";
						break;
					case item.type.includes("video") || item.type.includes("mov") || item.type.includes("mpeg"):
						item.icon = "doctype:video";
						break;
					case item.type.includes("excel") || item.type.includes("xl") || item.type.includes("xsl"):
						item.icon = "doctype:excel";
						break;
					case item.type.includes("htm") || item.type.includes("multipart/related"):
						item.icon = "doctype:html";
						break;
					case item.type.includes("msword") ||
						item.type.includes("rtf") ||
						item.type.includes("doc") ||
						item.type.includes("dot") ||
						item.type.includes("wps") ||
						item.type.includes("xps") ||
						item.type.includes("rtf"):
						item.icon = "doctype:word";
						break;
					case item.type.includes("x-msdownload"):
						item.icon = "doctype:exe";
						break;
					case item.type.includes("zip"):
						item.icon = "doctype:zip";
						break;
					case item.type.includes("flash") || item.type.includes("swf"):
						item.icon = "doctype:flash";
						break;
					case item.type.includes("json"):
						item.icon = "doctype:unknown";
						break;
					case item.type.includes("powerpoint") || item.type.includes("pot") || item.type.includes("vsd") || item.type.includes("ppt"):
						item.icon = "doctype:ppt";
						break;
					default:
						item.icon = "doctype:attachment";
				}
				item.progressIndicator = "0";
				item.progressVariant = "base-autocomplete";
				item.spinnerTitle = this.CUSTOM_LABELS.Inprogress;
				item.bolCancel = true;
				item.bolUpload = false;
				this.data.selectedFilesToUpload.push(item);

			});
			this.data.intSelectedFilesToUpload = this.data.selectedFilesToUpload.length;
			if (this.data.intSelectedFilesToUpload === this.parentData.intAllowFilesToUpload) {
				this.state.bolDisableUpload = true;
			}
			this.dispatchEvent(
				new CustomEvent("handleselectedfiles", {
					detail: { arrSelectedFiles: this.data.selectedFilesToUpload }
				})
			);
			this.state.bolFilesSelected = true;
			if(this.state.bolFilesSelected == true) {
				this.handleFileUpload();
			}
		}
	}

	// To handle file upload process
	async handleFileUpload() {
		this.bolUploadInprogress = true;
		this.bolShowFooter = false;
		let arrExternalFiles = [];
		let strSucFileNames = "",
			strErrFileNames = new Set(),
			intError = 1,
			intSuccess = 1;
		this.data.selectedFilesToUpload.forEach((element) => {
			element.bolUpload = true;
			if (element.bolExistingFile) {
				arrExternalFiles.push(element);
				this.state.bolSpinner = true;
				element.bolCancel = false;
				element.progressIndicator = "100";
				element.progressVariant = "base-autocomplete";
				element.spinnerTitle = this.CUSTOM_LABELS.Success;
				this.state.bolSpinner = false;
			}
		});
		if (arrExternalFiles.length > 0) {
			let strSuccessFileNames = "",
				strErrorFileNames = "";
			for (let z = 0; z < arrExternalFiles.length; z++) {
				strSuccessFileNames += intSuccess + ". " + arrExternalFiles[z].name + "\n";
				intSuccess++;
				strErrorFileNames += intError + ". " + arrExternalFiles[z].name + "\n";
				intError++;
			}

			await createExternalFileLinks({ lstEFWrapper: arrExternalFiles, strRecordId: this.recordId })
				.then((result) => {
					if (result) {
						strSucFileNames += strSuccessFileNames;
					} else {
						strErrorFileNames += strErrorFileNames;
					}
				})
				.catch((error) => {
					this.objLogErrorWrapper = {};
					this.objLogErrorWrapper.relatedTo = "UploadFilesController.createExternalFileLinks";
					this.objLogErrorWrapper.summary = "";
					this.objLogErrorWrapper.message = error;
					this.objLogErrorWrapper.batchJobId = "";
					this.objLogErrorWrapper.recordIds = "";
					this.objLogErrorWrapper.statusCode = this.recordId;
					logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
					strErrorFileNames += strErrorFileNames;
				});
		}
		if (this.parentData.objActiveStorageDetails.strStorageType === "Amazon S3") {
			for (let i = 0; i < this.data.selectedFilesToUpload.length; i++) {
				const file = this.data.selectedFilesToUpload[i];
				let strFileName = file.name.substring(0, file.name.lastIndexOf("."));
				let strFileExtension = file.name.substring(file.name.lastIndexOf("."), file.name.length);
				this.strUploadId = "";
				if (this.data.selectedFilesToUpload[i].bolCancel) {
					if (!this.data.selectedFilesToUpload[i].bolExistingFile) {
						if (file.size < UPLOAD_CHUNK_SIZE) {
							// Get presigned url for single file upload
							let strAmzDateSingleUploadRequest = this.getCurrentDateTimeAsString();
							this.objGenerateAuthHeaderForAWSWrapper = {};
							this.objGenerateAuthHeaderForAWSWrapper.strMethod = "PUT";
							this.objGenerateAuthHeaderForAWSWrapper.strRecordId = this.recordId;
							this.objGenerateAuthHeaderForAWSWrapper.strFileName = strFileName + "_v1" + strFileExtension;
							this.objGenerateAuthHeaderForAWSWrapper.strContentType = file.type;
							this.objGenerateAuthHeaderForAWSWrapper.strAmzDate = strAmzDateSingleUploadRequest;
							this.objGenerateAuthHeaderForAWSWrapper.strUploadId = null;
							this.objGenerateAuthHeaderForAWSWrapper.intPartNumber = null;
							this.objGenerateAuthHeaderForAWSWrapper.intTotalParts = null;

							await generateAuthHeaderForAWS({ strGenerateAuthHeaderForAWSWrapper: JSON.stringify(this.objGenerateAuthHeaderForAWSWrapper) })
								.then(async (result) => {
									if (result != null) {
										let objSingleUploadCallHeaders = {
											Authorization: result,
											"x-amz-content-sha256": "UNSIGNED-PAYLOAD",
											"x-amz-date": strAmzDateSingleUploadRequest,
											"content-type": file.type,
											host: this.strHost
										};
										let strSingleUploadEndPoint = this.parentData.objActiveStorageDetails.strEndPoint + "/" + this.recordId + "/" + strFileName + "_v1" + strFileExtension;
										// API callout to single file upload
										await fetch(strSingleUploadEndPoint, {
											method: "PUT",
											headers: objSingleUploadCallHeaders,
											body: file
										})
											.then((response) => {
												if (!response.ok) {
													return API_FAILURE;
												}
												return response.text();
											})
											.then(async (data) => {
												if (data != API_FAILURE) {
													await createExternalFiles({ strFileName: file.name, strRecordId: this.recordId, strSize: file.size })
														.then((result) => {
															if (result === this.CUSTOM_LABELS.Success) {
																this.state.bolSpinner = true;
																strSucFileNames += intSuccess + ". " + file.name + "\n";
																intSuccess++;
																this.data.selectedFilesToUpload[i].bolCancel = false;
																this.data.selectedFilesToUpload[i].progressIndicator = "100";
																this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Completed;
																this.state.bolSpinner = false;
															} else {
																strErrFileNames.add(file.name);
																this.data.selectedFilesToUpload[i].bolCancel = false;
																this.data.selectedFilesToUpload[i].progressVariant = "expired";
																this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
															}
														})
														.catch((error) => {
															this.objLogErrorWrapper = {};
															this.objLogErrorWrapper.relatedTo = "UploadFilesController.createExternalFiles";
															this.objLogErrorWrapper.summary = "";
															this.objLogErrorWrapper.message = error;
															this.objLogErrorWrapper.batchJobId = "";
															this.objLogErrorWrapper.recordIds = this.recordId;
															this.objLogErrorWrapper.statusCode = "";
															logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
															strErrFileNames.add(file.name);
															this.data.selectedFilesToUpload[i].bolCancel = false;
															this.data.selectedFilesToUpload[i].progressVariant = "expired";
															this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
														});
												} else {
													strErrFileNames.add(file.name);
													this.data.selectedFilesToUpload[i].bolCancel = false;
													this.data.selectedFilesToUpload[i].progressVariant = "expired";
													this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
												}
											})
											.catch((error) => {
												this.objLogErrorWrapper = {};
												this.objLogErrorWrapper.relatedTo = "UploadFilesController.generateAuthHeaderForAWS";
												this.objLogErrorWrapper.summary = "";
												this.objLogErrorWrapper.message = error;
												this.objLogErrorWrapper.batchJobId = "";
												this.objLogErrorWrapper.recordIds = this.recordId;
												this.objLogErrorWrapper.statusCode = "";
												logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
												strErrFileNames.add(file.name);
												this.data.selectedFilesToUpload[i].bolCancel = false;
												this.data.selectedFilesToUpload[i].progressVariant = "expired";
												this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
											});
									}
								})
								.catch((error) => {
									this.objLogErrorWrapper = {};
									this.objLogErrorWrapper.relatedTo = "UploadFilesController.generateAuthHeaderForAWS ";
									this.objLogErrorWrapper.summary = "";
									this.objLogErrorWrapper.message = error;
									this.objLogErrorWrapper.batchJobId = "";
									this.objLogErrorWrapper.recordIds = this.recordId;
									this.objLogErrorWrapper.statusCode = "";
									logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
									strErrFileNames.add(file.name);
									this.data.selectedFilesToUpload[i].bolCancel = false;
									this.data.selectedFilesToUpload[i].progressVariant = "expired";
									this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
								});
						} else {
							if (this.data.selectedFilesToUpload[i].bolCancel) {
								let strAmzDateInitiateRequest = this.getCurrentDateTimeAsString();
								this.objGenerateAuthHeaderForAWSWrapper = {};
								this.objGenerateAuthHeaderForAWSWrapper.strMethod = "POST";
								this.objGenerateAuthHeaderForAWSWrapper.strRecordId = this.recordId;
								this.objGenerateAuthHeaderForAWSWrapper.strFileName = strFileName + "_v1" + strFileExtension;
								this.objGenerateAuthHeaderForAWSWrapper.strContentType = file.type;
								this.objGenerateAuthHeaderForAWSWrapper.strAmzDate = strAmzDateInitiateRequest;
								this.objGenerateAuthHeaderForAWSWrapper.strUploadId = null;
								this.objGenerateAuthHeaderForAWSWrapper.intPartNumber = null;
								this.objGenerateAuthHeaderForAWSWrapper.intTotalParts = null;
								// Get AuthHeader for Initiate Multipart Request call
								await generateAuthHeaderForAWS({ strGenerateAuthHeaderForAWSWrapper: JSON.stringify(this.objGenerateAuthHeaderForAWSWrapper) })
									.then(async (result) => {
										if (result != null) {
											let objInitiateCallHeaders = {
												Authorization: result,
												"x-amz-content-sha256": "UNSIGNED-PAYLOAD",
												"x-amz-date": strAmzDateInitiateRequest,
												"content-type": file.type,
												host: this.strHost
											};
											let strInitiateEndpoint = this.parentData.objActiveStorageDetails.strEndPoint + "/" + this.recordId + "/" + strFileName + "_v1" + strFileExtension + "?uploads=";
											// API callout to initiate multipart upload
											await fetch(strInitiateEndpoint, {
												method: "POST",
												headers: objInitiateCallHeaders
											})
												.then(async (response) => {
													if (!response.ok) {
														return API_FAILURE;
													}
													// Parse upload id from response
													const objDOMParser = new DOMParser();
													const objXmlDoc = objDOMParser.parseFromString(await response.text(), "text/xml");
													const strUplId = objXmlDoc.getElementsByTagName("UploadId")[0].textContent;
													return strUplId;
												})
												.then(async (data) => {
													if (data != API_FAILURE) {
														this.strUploadId = data;
														const intChunkSize = UPLOAD_CHUNK_SIZE; // 5MB in bytes
														const arrChunks = [];
														const intChunkCount = Math.ceil(file.size / intChunkSize);

														// Split Blob into chunks
														for (let b = 0; b < intChunkCount; b++) {
															const intStartIndex = b * intChunkSize;
															const intEndIndex = Math.min(intStartIndex + intChunkSize, file.size);
															const blbChunk = file.slice(intStartIndex, intEndIndex);
															arrChunks.push(blbChunk);
														}
														let mapEtags = new Map();
														await Promise.all(
															arrChunks.map(async (blbPart, intIndex) => {
																if (this.data.selectedFilesToUpload[i].bolCancel) {
																	try {
																		if (this.data.selectedFilesToUpload[i].bolCancel) {
																			let strAmzDateUploadPartRequest = this.getCurrentDateTimeAsString();
																			this.objGenerateAuthHeaderForAWSWrapper = {};
																			this.objGenerateAuthHeaderForAWSWrapper.strMethod = "PUT";
																			this.objGenerateAuthHeaderForAWSWrapper.strRecordId = this.recordId;
																			this.objGenerateAuthHeaderForAWSWrapper.strFileName = strFileName + "_v1" + strFileExtension;
																			this.objGenerateAuthHeaderForAWSWrapper.strContentType = file.type;
																			this.objGenerateAuthHeaderForAWSWrapper.strAmzDate = strAmzDateUploadPartRequest;
																			this.objGenerateAuthHeaderForAWSWrapper.strUploadId = this.strUploadId;
																			this.objGenerateAuthHeaderForAWSWrapper.intPartNumber = intIndex + 1;
																			this.objGenerateAuthHeaderForAWSWrapper.intTotalParts = arrChunks.length;
																			// Get AuthHeader for Upload Part call
																			const result = await generateAuthHeaderForAWS({ strGenerateAuthHeaderForAWSWrapper: JSON.stringify(this.objGenerateAuthHeaderForAWSWrapper) });
																			if (result != null && this.data.selectedFilesToUpload[i].bolCancel) {
																				let objUploadCallHeaders = {
																					Authorization: result,
																					"x-amz-content-sha256": "UNSIGNED-PAYLOAD",
																					"x-amz-date": strAmzDateUploadPartRequest,
																					"content-type": file.type
																				};
																				let strUploadPartEndPoint =
																					this.parentData.objActiveStorageDetails.strEndPoint +
																					"/" +
																					this.recordId +
																					"/" +
																					strFileName +
																					"_v1" +
																					strFileExtension +
																					"?partNumber=" +
																					String(intIndex + 1) +
																					"&uploadId=" +
																					this.strUploadId;
																				if (this.data.selectedFilesToUpload[i].bolCancel) {
																					await fetch(strUploadPartEndPoint, {
																						method: "PUT",
																						headers: objUploadCallHeaders,
																						body: blbPart
																					})
																						.then(async (response) => {
																							if (!response.ok) {
																								return API_FAILURE;
																							}
																							const resHeaders = response.headers;
																							return resHeaders.get("etag");
																						})
																						.then((data) => {
																							if (data != API_FAILURE && this.data.selectedFilesToUpload[i].bolCancel) {
																								mapEtags.set(intIndex + 1, String(data));
																								// Placeholder lines to display a progress indicator without triggering a UI refresh issue when using Promise.all() to handle multiple asynchronous operations.
																								const dummy = { ...this.data.selectedFilesToUpload[i] };
																								this.data.selectedFilesToUpload[i] = { ...dummy };

																								this.data.selectedFilesToUpload[i].name = file.name;
																								this.data.selectedFilesToUpload[i].progressIndicator = ((mapEtags.size / arrChunks.length) * 100).toString();
																								this.data.selectedFilesToUpload[i].progressVariant = "base-autocomplete";
																								this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Inprogress;
																							} else {
																								this.data.selectedFilesToUpload[i].bolCancel = false;
																								this.data.selectedFilesToUpload[i].progressVariant = "expired";
																								this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
																							}
																						})
																						.catch((error) => {
																							strErrFileNames.add(file.name);
																							this.data.selectedFilesToUpload[i].bolCancel = false;
																							this.data.selectedFilesToUpload[i].progressVariant = "expired";
																							this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
																						});
																				}
																			} else {
																				this.data.selectedFilesToUpload[i].bolCancel = false;
																				this.data.selectedFilesToUpload[i].progressVariant = "expired";
																				this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
																			}
																		}
																	} catch (error) {
																		strErrFileNames.add(file.name);
																		this.data.selectedFilesToUpload[i].bolCancel = false;
																		this.data.selectedFilesToUpload[i].progressVariant = "expired";
																		this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
																	}
																}
															})
														);
														if (this.strUploadId != null && this.strUploadId != "" && !this.data.selectedFilesToUpload[i].bolCancel) {
															// Get AuthHeader for Abort Multipart Request call
															let strAmzDateAbortRequest = this.getCurrentDateTimeAsString();
															this.objGenerateAuthHeaderForAWSWrapper = {};
															this.objGenerateAuthHeaderForAWSWrapper.strMethod = "DELETE";
															this.objGenerateAuthHeaderForAWSWrapper.strRecordId = this.recordId;
															this.objGenerateAuthHeaderForAWSWrapper.strFileName = strFileName + "_v1" + strFileExtension;
															this.objGenerateAuthHeaderForAWSWrapper.strContentType = file.type;
															this.objGenerateAuthHeaderForAWSWrapper.strAmzDate = strAmzDateAbortRequest;
															this.objGenerateAuthHeaderForAWSWrapper.strUploadId = this.strUploadId;
															this.objGenerateAuthHeaderForAWSWrapper.intPartNumber = null;
															this.objGenerateAuthHeaderForAWSWrapper.intTotalParts = null;
															await generateAuthHeaderForAWS({ strGenerateAuthHeaderForAWSWrapper: JSON.stringify(this.objGenerateAuthHeaderForAWSWrapper) })
																.then(async (result) => {
																	if (result != null) {
																		const objCompleteCallHeaders = {
																			Authorization: result,
																			"x-amz-content-sha256": "UNSIGNED-PAYLOAD",
																			"x-amz-date": strAmzDateAbortRequest,
																			"content-type": file.type
																		};
																		let strEndPoint =
																			this.parentData.objActiveStorageDetails.strEndPoint +
																			"/" +
																			this.recordId +
																			"/" +
																			strFileName +
																			"_v1" +
																			strFileExtension +
																			"?uploadId=" +
																			this.strUploadId;
																		// API callout to Abort Multipart Request
																		await fetch(strEndPoint, {
																			method: "DELETE",
																			headers: objCompleteCallHeaders
																		}).then(async (response) => {
																			if (!response.ok) {
																				return API_FAILURE;
																			}
																			return response.text();
																		});
																	}
																})
																.catch((error) => {
																	strErrFileNames.add(file.name);
																	this.data.selectedFilesToUpload[i].bolCancel = false;
																	this.data.selectedFilesToUpload[i].progressVariant = "expired";
																	this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
																});
														}
														if (mapEtags.size == arrChunks.length && this.data.selectedFilesToUpload[i].bolCancel) {
															let strAmzDateCompleteRequest = this.getCurrentDateTimeAsString();
															this.objGenerateAuthHeaderForAWSWrapper = {};
															this.objGenerateAuthHeaderForAWSWrapper.strMethod = "POST";
															this.objGenerateAuthHeaderForAWSWrapper.strRecordId = this.recordId;
															this.objGenerateAuthHeaderForAWSWrapper.strFileName = strFileName + "_v1" + strFileExtension;
															this.objGenerateAuthHeaderForAWSWrapper.strContentType = file.type;
															this.objGenerateAuthHeaderForAWSWrapper.strAmzDate = strAmzDateCompleteRequest;
															this.objGenerateAuthHeaderForAWSWrapper.strUploadId = this.strUploadId;
															this.objGenerateAuthHeaderForAWSWrapper.intPartNumber = null;
															this.objGenerateAuthHeaderForAWSWrapper.intTotalParts = arrChunks.length;
															// Get AuthHeader for Complete Multipart Request call
															await generateAuthHeaderForAWS({ strGenerateAuthHeaderForAWSWrapper: JSON.stringify(this.objGenerateAuthHeaderForAWSWrapper) })
																.then(async (result) => {
																	if (result != null) {
																		const objCompleteCallHeaders = {
																			Authorization: result,
																			"x-amz-content-sha256": "UNSIGNED-PAYLOAD",
																			"x-amz-date": strAmzDateCompleteRequest,
																			"content-type": file.type
																		};
																		const objDocument = document.implementation.createDocument(null, "CompleteMultipartUpload", null);
																		const objRootNode = objDocument.documentElement;
																		for (let a = 1; a <= arrChunks.length; a++) {
																			const objPartElement = objDocument.createElement("Part");
																			objRootNode.appendChild(objPartElement);
																			const objPartNumberElement = objDocument.createElement("PartNumber");
																			objPartNumberElement.textContent = String(a);
																			objPartElement.appendChild(objPartNumberElement);
																			const objEtagElement = objDocument.createElement("ETag");
																			objEtagElement.textContent = mapEtags.get(a);
																			objPartElement.appendChild(objEtagElement);
																		}
																		// Serialize the XML document to a string
																		const objXMLSerializer = new XMLSerializer();
																		const strCompleteRequestBody = objXMLSerializer.serializeToString(objDocument);
																		const objEncoder = new TextEncoder();
																		const arruint8Array = objEncoder.encode(strCompleteRequestBody);

																		let strEndPoint =
																			this.parentData.objActiveStorageDetails.strEndPoint +
																			"/" +
																			this.recordId +
																			"/" +
																			strFileName +
																			"_v1" +
																			strFileExtension +
																			"?uploadId=" +
																			this.strUploadId;
																		// API callout to complete Multipart Upload
																		await fetch(strEndPoint, {
																			method: "POST",
																			headers: objCompleteCallHeaders,
																			body: new Blob([arruint8Array], { type: "application/xml" })
																		})
																			.then(async (response) => {
																				if (!response.ok) {
																					return API_FAILURE;
																				}
																				return response.text();
																			})
																			.then(async (data) => {
																				if (data != API_FAILURE) {
																					// To create External Files and related records once multipart upload is completed.
																					await createExternalFiles({ strFileName: file.name, strRecordId: this.recordId, strSize: file.size })
																						.then((result) => {
																							if (result === this.CUSTOM_LABELS.Success) {
																								this.state.bolSpinner = true;
																								strSucFileNames += intSuccess + ". " + file.name + "\n";
																								intSuccess++;
																								this.data.selectedFilesToUpload[i].bolCancel = false;
																								this.data.selectedFilesToUpload[i].progressIndicator = "100";
																								this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Completed;
																								this.state.bolSpinner = false;
																							} else {
																								strErrFileNames.add(file.name);
																								this.data.selectedFilesToUpload[i].bolCancel = false;
																								this.data.selectedFilesToUpload[i].progressVariant = "expired";
																								this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
																							}
																						})
																						.catch((error) => {
																							strErrFileNames.add(file.name);
																							this.data.selectedFilesToUpload[i].bolCancel = false;
																							this.data.selectedFilesToUpload[i].progressVariant = "expired";
																							this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
																						});
																				}
																			})
																			.catch((error) => {
																				strErrFileNames.add(file.name);
																				this.data.selectedFilesToUpload[i].bolCancel = false;
																				this.data.selectedFilesToUpload[i].progressVariant = "expired";
																				this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
																			});
																	}
																})
																.catch((error) => {
																	strErrFileNames.add(file.name);
																	this.data.selectedFilesToUpload[i].bolCancel = false;
																	this.data.selectedFilesToUpload[i].progressVariant = "expired";
																	this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
																});
														}
													} else {
														strErrFileNames.add(file.name);
														this.data.selectedFilesToUpload[i].bolCancel = false;
														this.data.selectedFilesToUpload[i].progressVariant = "expired";
														this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
													}
												})
												.catch((error) => {
													strErrFileNames.add(file.name);
													this.data.selectedFilesToUpload[i].bolCancel = false;
													this.data.selectedFilesToUpload[i].progressVariant = "expired";
													this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
												});
										} else {
											strErrFileNames.add(file.name);
											this.data.selectedFilesToUpload[i].bolCancel = false;
											this.data.selectedFilesToUpload[i].progressVariant = "expired";
											this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
										}
									})
									.catch((error) => {
										strErrFileNames.add(file.name);
										this.data.selectedFilesToUpload[i].bolCancel = false;
										this.data.selectedFilesToUpload[i].progressVariant = "expired";
										this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Error;
									});
							}
						}
					}
				}
			}
		} else {

		}
		if (strSucFileNames != " ") {
			this.showNotification(Success + "!", this.CUSTOM_LABELS.Below_files_are_uploaded_successfully + "\n" + strSucFileNames, "success");
			this.state.bolSpinner = false;
		}
		if (strErrFileNames.size > 0) {
			let strMessage = '';
			let intError = 1;
			for (const value of strErrFileNames) {
				strMessage += intError + ". " + value + "\n";
				intError++;
			}
			this.showNotification(Error + "!", this.CUSTOM_LABELS.File_upload_is_failed + "\n" + strMessage, "Error");
		}
		this.state.bolDisableUpload = false;
		this.data.intSelectedFilesToUpload = 0;
		this.dispatchEvent(
			new CustomEvent("handleuploadfile", {
				detail: { bolFileUploaded: true }
			})
		);
		this.dispatchEvent(
			new CustomEvent("handleaddfile", {
				detail: {
					selectedFilesToUpload: [],
					bolShowAddFile: false
				}
			})
		);
		this.bolUploadInprogress = false;
	}

	getCurrentDateTimeAsString() {
		var dtNow = new Date();
		return (
			dtNow.getUTCFullYear() +
			("0" + (dtNow.getUTCMonth() + 1)).slice(-2) +
			("0" + dtNow.getUTCDate()).slice(-2) +
			"T" +
			("0" + dtNow.getUTCHours()).slice(-2) +
			("0" + dtNow.getUTCMinutes()).slice(-2) +
			("0" + dtNow.getUTCSeconds()).slice(-2) +
			"Z"
		);
	}

	// To remove file if the user clicks remove button
	removeFileForUpload(event) {
		this.state.bolSpinner = true;
		this.data.intSelectedFilesToUpload -= 1;
		let fileName = event.currentTarget.dataset.filename;
		this.data.tempSelectedFilesToUpload = this.data.selectedFilesToUpload;
		if (this.bolUploadInprogress) {
			let bolUploadProgressTemp = false;
			for (let i = 0; i < this.data.selectedFilesToUpload.length; i++) {
				if (fileName === this.data.selectedFilesToUpload[i].name) {
					this.data.selectedFilesToUpload[i].bolCancel = false;
					this.data.selectedFilesToUpload[i].progressVariant = "expired";
					this.data.selectedFilesToUpload[i].spinnerTitle = this.CUSTOM_LABELS.Cancelled;
				}
				if (this.data.selectedFilesToUpload[i].bolCancel) {
					bolUploadProgressTemp = true;
				}
				this.bolUploadInprogress = bolUploadProgressTemp;
			}
		} else {
			this.data.selectedFilesToUpload = [];
			for (let i = 0; i < this.data.tempSelectedFilesToUpload.length; i++) {
				if (fileName != this.data.tempSelectedFilesToUpload[i].name) {
					this.data.selectedFilesToUpload.push(this.data.tempSelectedFilesToUpload[i]);
				}
			}
		}
		if (this.data.selectedFilesToUpload.length < 1) {
			this.data.intSelectedFilesToUpload = 0;
			this.state.bolFilesSelected = false;
		} else {
			this.data.intSelectedFilesToUpload = this.data.selectedFilesToUpload.length;
			if (this.state.bolDisableUpload) {
				this.state.bolDisableUpload = false;
			}
		}
		this.state.bolSpinner = false;
		this.dispatchEvent(
			new CustomEvent("handleselectedfiles", {
				detail: { arrSelectedFiles: this.data.selectedFilesToUpload }
			})
		);
		this.arrRelatedFileNames.splice(this.arrRelatedFileNames.indexOf(event.currentTarget.dataset.strfilename), 1);
		
	}

	// To handle add file logics
	handleAddFile() {
		this.dispatchEvent(
			new CustomEvent("handleaddfile", {
				detail: {
					selectedFilesToUpload: this.data.selectedFilesToUpload,
					bolShowAddFile: true
				}
			})
		);
	}

	// To handle cancel upload logics
	cancelFileUpload() {
		this.state.bolFilesSelected = false;
		this.dispatchEvent(
			new CustomEvent("handleaddfile", {
				detail: {
					selectedFilesToUpload: this.data.selectedFilesToUpload,
					bolShowAddFile: false
				}
			})
		);
		this.state.bolDisableUpload = false;
		this.data.selectedFilesToUpload = [];
		this.data.intSelectedFilesToUpload = 0;
	}

	@api handleDeletedExternalFiles(objDeletedFiles) {
        this.arrRelatedFileNames.splice(this.arrRelatedFileNames.indexOf(objDeletedFiles), 1);
	}

	showNotification(strTitle, strMessage, strType) {
		const objToastEvent = new ShowToastEvent({
			title: strTitle,
			message: strMessage,
			variant: strType,
			mode: "sticky"
		});
		this.dispatchEvent(objToastEvent);
	}

}