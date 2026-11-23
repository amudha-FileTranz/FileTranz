/*
 * Purpose : To add the existing/new files from the record page.
 * Author  : Anandhakumar Thangasamy
 */

import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, api, track, wire } from "lwc";
// Importing Apex Methods
import getExternalFiles from "@salesforce/apex/AddFilesController.getExternalFiles";
import getConfigurations from "@salesforce/apex/CommonUtilities.getConfiguration";
// Importing Custom labels to provide multi language support
import Add_Files from "@salesforce/label/c.Add_Files";
import Cancel from "@salesforce/label/c.Cancel";
import Error from "@salesforce/label/c.Error";
import Loading from "@salesforce/label/c.Loading";
import files from "@salesforce/label/c.Maximum_Files_Warning";
import Maximum_file_limit_reached from "@salesforce/label/c.Maximum_file_limit_reached";
import No_Files_Selected from "@salesforce/label/c.No_Files_Selected";
import No_files_found from "@salesforce/label/c.No_files_found";
import Owned_By_Me from "@salesforce/label/c.Owned_By_Me";
import Please_select_upto from "@salesforce/label/c.Please_select_upto";
import Recent_Files from "@salesforce/label/c.Recent_Files";
import Search_Files from "@salesforce/label/c.Search_Files";
import Select_Files from "@salesforce/label/c.Select_Files";
import Warning from "@salesforce/label/c.Warning";
import files_selected from "@salesforce/label/c.files_selected";
import of from "@salesforce/label/c.of";
import Associate_Existing_File_Description from "@salesforce/label/c.Associate_Existing_File_Description";
import filetranzcustomstyle from "@salesforce/resourceUrl/filetranzcustomstyle";
import { loadStyle } from "lightning/platformResourceLoader";
const FILE_LIMIT = "File_Limit";

export default class AddFiles extends LightningElement {
	@track recordId;
	@api arrSelectedFiles;
	@api objectName;
	@track state = {
		bolShowRecent: true,
		bolNoFiles: false,
		bolIsLoading: true,
		bolNoFilesFound:false
	};
	@track data = {
		strSelectedTab: "recent",
		strSearchKey: "",
		arrOwnedFiles: [],
		arrRecentFiles: [],
		arrUploadFiles: [],
		setSelectedFiles: new Set(),
		intFilesSelected: 0,
		intAllowFilesToUpload: 0
	};
	@track myArray = [];

	CUSTOM_LABELS = {
		Select_Files,
		Recent_Files,
		Cancel,
		files_selected,
		of,
		Owned_By_Me,
		Add_Files,
		No_files_found,
		No_Files_Selected,
		Please_select_upto,
		files,
		Error,
		Search_Files,
		Maximum_file_limit_reached,
		Warning,
		Loading,
		Associate_Existing_File_Description
	};


	
	@wire(CurrentPageReference)
	getPageReferenceParameters(currentPageReference) {
		if (currentPageReference) {
			this.recordId = currentPageReference.attributes.recordId;
		}
	}
	connectedCallback() {
		window.addEventListener("scroll", this.handleScroll);
		this.data.intFilesSelected = this.arrSelectedFiles.length;
		this.getExternalFiles();
		loadStyle(this, filetranzcustomstyle);
		// Get configuration details
		getConfigurations({ lstConfigurationType: ["File Configuration"] })
			.then((result) => {
				this.data.intAllowFilesToUpload = Number(result[FILE_LIMIT]);
			})
			.catch((error) => {
				this.showNotification(Error, error.message, "error");
			});
	}

	getExternalFiles() {
		// To get External Files
		getExternalFiles({ strRecordId: this.recordId, strSearchKey: this.data.strSearchKey })
			.then((result) => {
				if (result.length > 0) {
					this.data.arrOwnedFiles = result;
					this.myArray = [...this.data.arrOwnedFiles];
					
					// Update bolDisable based on intFilesSelected
					if (this.data.intFilesSelected >= this.data.intAllowFilesToUpload) {
						for (let i = 0; i < this.data.arrOwnedFiles.length; i++) {
							this.data.arrOwnedFiles[i].bolDisable = true;
						}
					} else {
						for (let i = 0; i < this.data.arrOwnedFiles.length; i++) {
							this.data.arrOwnedFiles[i].bolDisable = false;
						}
					}
					this.data.arrRecentFiles = this.data.arrOwnedFiles.slice(0, 10);
					this.state.bolIsLoading = false;
					this.state.bolNoFilesFound = false;
				} else {
					this.data.arrOwnedFiles = [];
					this.data.arrRecentFiles = [];
					this.state.bolNoFiles = false;
					this.state.bolNoFilesFound = true;
					this.state.bolIsLoading = false;
				}
			})
			.catch((error) => {
				this.state.bolIsLoading = false;
				this.showNotification(Error, error.message, "error");
			});
	}

	// To handle tab switch logics
	handleSelect(event) {
		this.state.bolIsLoading = true;
		this.data.strSearchKey = "";
		this.getExternalFiles();
		
		if (this.data.strSelectedTab !== event.detail.name) {
			this.data.setSelectedFiles = new Set();
			this.data.intFilesSelected = this.data.setSelectedFiles.size + this.arrSelectedFiles.length;
			
			this.data.strSelectedTab = event.detail.name;
			if (this.data.strSelectedTab === "recent") {
				this.state.bolShowRecent = true;
				for (let i = 0; i < this.data.arrRecentFiles.length; i++) {
					this.data.arrRecentFiles[i].bolSelected = false;
					this.data.arrRecentFiles[i].bolDisable = false;
				}
			} else {
				this.state.bolShowRecent = false;
				for (let i = 0; i < this.data.arrOwnedFiles.length; i++) {
					this.data.arrOwnedFiles[i].bolSelected = false;
					this.data.arrOwnedFiles[i].bolDisable = false;
				}
			}
		}
		this.state.bolIsLoading = false;
	}
	
	// To handle file selection logics --->  //This is Fine
	handlecheck(event) {
		
		for (let i = 0; i < this.data.arrOwnedFiles.length; i++) {
			if (event.currentTarget.dataset.name === this.data.arrOwnedFiles[i].strName) {
				this.data.arrOwnedFiles[i].bolSelected = event.target.checked;
				break;
			}
		}

		if (event.target.checked === true) {
			this.data.setSelectedFiles.add(event.currentTarget.dataset.name);
		} else {
			this.data.setSelectedFiles.delete(event.currentTarget.dataset.name);
		}
		this.data.intFilesSelected = this.data.setSelectedFiles.size;
		
		if (this.data.intFilesSelected >= this.data.intAllowFilesToUpload) {
			for (let i = 0; i < this.data.arrOwnedFiles.length; i++) {
				if (this.data.setSelectedFiles.has(this.data.arrOwnedFiles[i].strName)) {
					this.data.arrOwnedFiles[i].bolDisable = false;
				} else {
					this.data.arrOwnedFiles[i].bolDisable = true;
				}
			}
			this.showNotification(Warning, Maximum_file_limit_reached + "!", "warning");
		} else {
			for (let i = 0; i < this.data.arrOwnedFiles.length; i++) {
				this.data.arrOwnedFiles[i].bolDisable = false;
			}
		}
	}


	// To close the popup
	handleCancel() {
		const custEvent = new CustomEvent("closepopup");
		this.dispatchEvent(custEvent);
	}

	// To handle search files functionality
	handleSearch(event) {
		let tempArray = [];
		let tempRecentFilesArray = [];
		let recentFileArray = this.myArray.slice(0, 10);
		this.data.strSearchKey = event.detail.value;
		if (this.data.strSearchKey !== "") {
			if (this.data.strSelectedTab === "recent"){
				tempRecentFilesArray = recentFileArray.filter((file) => {
					return file.strFileName.toLowerCase().includes(this.data.strSearchKey.toLowerCase());
				});
			} else{
				tempArray = this.myArray.filter((file) => {
					return file.strFileName.toLowerCase().includes(this.data.strSearchKey.toLowerCase());
				});
			}
			this.data.arrOwnedFiles = tempArray;
			this.data.arrRecentFiles = tempRecentFilesArray;
		} else{
			tempArray = this.myArray;
			this.data.arrOwnedFiles = tempArray;
			this.data.arrRecentFiles = tempArray.slice(0, 10);
		}

	}

	// To handle Add File - Submit button logic
	handleAddFile() {
		if (this.data.intFilesSelected === 0) {
			this.showNotification(Error, No_Files_Selected, "error");
		} else {
			const arrSelectedFileNames = Array.from(this.data.setSelectedFiles);
			if (arrSelectedFileNames.length > this.data.intAllowFilesToUpload) {
				this.showNotification(Error, Please_select_upto + " " + this.data.intAllowFilesToUpload + " " + files + "!", "error");
			} else {
				let arrSelectedFiles = [];
				for (let i = 0; i < arrSelectedFileNames.length; i++) {
					for (let j = 0; i < this.data.arrOwnedFiles.length; j++) {
						if (this.data.arrOwnedFiles[j].strName.toLowerCase().includes(arrSelectedFileNames[i].toLowerCase())) {
							let objAddFile = {
								name: this.data.arrOwnedFiles[j].strFileName,
								id: this.data.arrOwnedFiles[j].strId,
								bolExistingFile: true,
								LastModifiedDate: this.data.arrOwnedFiles[j].lastModifiedDate,
								type: this.data.arrOwnedFiles[j].strFileType,
								size: this.data.arrOwnedFiles[j].strSize
							};
							this.data.arrUploadFiles.push(objAddFile);
							arrSelectedFiles.push(objAddFile);
							break;
						}
					}
				}
				if (this.arrSelectedFiles.length + arrSelectedFiles.length > this.data.intAllowFilesToUpload) {
					this.showNotification(Error, Please_select_upto + " " + this.data.intAllowFilesToUpload + " " + files + "!", "error");
				} else {
					const custEvent = new CustomEvent("addfiles", {
						detail: {
							arrSelectedFiles: arrSelectedFiles
						}
					});
					this.dispatchEvent(custEvent);
				}
			}
		}
	}

	// Generic Toast Notification Method
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