/*
 * Purpose : To display recycle bin of filetranz and to restore that data.
 * Author  : Nishanth
 */
import {NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {LightningElement,track,wire} from "lwc";
// Importing Apex Methods
import {refreshApex} from "@salesforce/apex";
import checkRelatedRecords from "@salesforce/apex/CommonUtilities.checkRelatedRecords";
import getDeletedExternalFiles from "@salesforce/apex/CommonUtilities.getDeletedExternalFiles";
import restoreExternalfile from "@salesforce/apex/CommonUtilities.restoreExternalfile";

//Importing Custom Labels
import ACTION from "@salesforce/label/c.ACTION";
import Error from "@salesforce/label/c.Error";
import File_Name from "@salesforce/label/c.File_Name";
import File_Type from "@salesforce/label/c.File_Type";
import Object_Name from "@salesforce/label/c.Object_Name";
import Parent_Record_Of_File from "@salesforce/label/c.Parent_Record_Of_File";
import Parent_record_is_already_deleted_The_file_cannot_be_restored from "@salesforce/label/c.Parent_record_is_already_deleted_The_file_cannot_be_restored";
import RecycleBin_Error_Msg from "@salesforce/label/c.RecycleBin_Error_Msg";
import RecycleBin_Success_Msg from "@salesforce/label/c.RecycleBin_Success_Msg";
import Recycle_Search_Button from "@salesforce/label/c.Recycle_Search_Button";
import RecyleBin_Datatable_Header from "@salesforce/label/c.RecyleBin_Datatable_Header";
import RecyleBin_External_No_Delete_Msg from "@salesforce/label/c.RecyleBin_External_No_Delete_Msg";
import RecyleBin_Title from "@salesforce/label/c.RecyleBin_Title";
import Restore from "@salesforce/label/c.Restore";
import Success from "@salesforce/label/c.Success";
import Warning from "@salesforce/label/c.Warning";
import filetranzcustomstyle from "@salesforce/resourceUrl/filetranzcustomstyle";
import {loadStyle} from "lightning/platformResourceLoader";

export default class RecycleBin extends NavigationMixin(LightningElement) {
    @track arrExtFileData = [];
    @track arrExternalFileId = [];
    @track arrCloneExtFileData;
    wiredDeletedExtFiles;
    bolDeletedFiles = false;
    @track bolAllChecked = false;
    strRecycleTitle = '';
    strSearchvalue = '';
    strSearch = '';
    strRestoreFiles = '';

    //Custom Labels
    @track CUSTOM_LABELS = {
        RecyleBin_Title,
        RecyleBin_Datatable_Header,
        Recycle_Search_Button,
        RecyleBin_External_No_Delete_Msg,
        RecycleBin_Success_Msg,
        RecycleBin_Error_Msg,
        File_Type,
        File_Name,
        Object_Name,
        Parent_Record_Of_File,
        Parent_record_is_already_deleted_The_file_cannot_be_restored,
        Restore,
        ACTION,
        Error,
        Success,
        Warning
    };

    get bolDisableRestore() {
        return this.arrExternalFileId.length > 0 ? false : true;
    }

    // To query recycle bin data
    @wire(getDeletedExternalFiles)
    wiredAllDeletedExtFiles(result) {
        this.wiredDeletedExtFiles = result;
        this.arrExtFileData = [];
        if (result.data) {
            let arrDelFileTemp = result.data;
            for (let i = 0; i < arrDelFileTemp.length; i++) {
                this.arrExtFileData.push({
                    Name: arrDelFileTemp[i].Name,
                    Id: arrDelFileTemp[i].Id,
                    File_Name__c: arrDelFileTemp[i].External_Files__r.File_Name__c,
                    Object_Type__c: arrDelFileTemp[i].Object_Type__c,
                    Related_To__c: arrDelFileTemp[i].Related_To__c,
                    File_Type__c: arrDelFileTemp[i].External_Files__r.File_Type__c,
                    bolSelectCheckbox: false
                });
            }
            this.arrCloneExtFileData = this.arrExtFileData;
            this.strRecycleTitle = this.CUSTOM_LABELS.RecyleBin_Title + "(" + this.arrExtFileData.length + ")";
            if (this.arrExtFileData.length == 0) {
                this.bolDeletedFiles = true;
            } else if (this.strSearchvalue != "") {
                this.getSearchResults();
            }
        } else if (result.error) {
            console.error("wiredallStorageConfig", result.error);
        }
    }

    connectedCallback() {
        let strDatatableTitle = RecyleBin_Datatable_Header.split(",");
        this.CUSTOM_LABELS.File_Name = strDatatableTitle[0];
        this.CUSTOM_LABELS.File_Type = strDatatableTitle[1];
        this.CUSTOM_LABELS.Object_Name = strDatatableTitle[2];
        this.CUSTOM_LABELS.Parent_Record_Of_File = strDatatableTitle[3];
        let strSearchButtonTitle = Recycle_Search_Button.split(",");
        this.strSearch = strSearchButtonTitle[0];
        this.strRestoreFiles = strSearchButtonTitle[1];
        refreshApex(this.wiredDeletedExtFiles);
        loadStyle(this, filetranzcustomstyle);
    }

    // To handle click action on Related To Id
    handleRelatedRowAction(event) {
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: event.currentTarget.dataset.strid,
                objectApiName: "Account",
                actionName: "view"
            }
        }).then((url) => {
            window.open(url, "_blank");
        });
    }

    // To handle selection logics
    handleSelect(event) {
        this.bolAllChecked = false; // Default to false
        let strExtfileId = event.currentTarget.dataset.id;

        let objExtFile = this.arrExtFileData.find((element) => element.Id == strExtfileId);
        if (event.detail.checked) {
            objExtFile.bolSelectCheckbox = true;
            this.arrExternalFileId.push(strExtfileId);
        } else {
            let intIndex = this.arrExternalFileId.findIndex((extFileId) => extFileId === strExtfileId);
            this.arrExternalFileId.splice(intIndex, 1);
            objExtFile.bolSelectCheckbox = false;
        }

        // Check if all checkboxes are now selected
        this.bolAllChecked = this.arrExtFileData.every((file) => file.bolSelectCheckbox);
    }

    // To handle restore deleted files
    handleRestoreExternalFiles(event) {
        let restoreType = event.currentTarget.dataset.restoretype;
        if (restoreType == "RowRestore") {
            let strExtfileId = event.currentTarget.dataset.id;
            this.arrExternalFileId = [];
            this.arrExternalFileId.push(strExtfileId);
        }

        if (this.arrExternalFileId.length > 0) {
            let externalFileMap = {};
            this.arrExternalFileId.forEach((item) => {
                let externalFile = this.arrExtFileData.find((element) => element.Id == item);
                if (!Object.prototype.hasOwnProperty.call(externalFileMap, externalFile.Object_Type__c)) {
                    externalFileMap[externalFile.Object_Type__c] = [];
                }
                externalFileMap[externalFile.Object_Type__c].push(externalFile.Related_To__c);
            });
            checkRelatedRecords({
                    externalKeyWithFileMap: externalFileMap
                })
                .then((result) => {
                    if (result == true) {
                        restoreExternalfile({
                                lstEFLids: this.arrExternalFileId
                            })
                            .then((result) => {
                                if (result === this.CUSTOM_LABELS.Success) {
                                    this.bolAllChecked = false;
                                    this.showNotification(result, this.CUSTOM_LABELS.RecycleBin_Success_Msg, result);
                                    refreshApex(this.wiredDeletedExtFiles);
                                    this.arrExternalFileId = [];
                                    this.strRecycleTitle = this.CUSTOM_LABELS.RecyleBin_Title + "(" + this.arrExtFileData.length + ")";
                                } else {
                                    this.showNotification(Error, result, "Error");
                                }
                            })
                            .catch((error) => {
                                this.showNotification(Error, error.message, "Error");
                            });
                    } else {
                        this.showNotification(Warning, Parent_record_is_already_deleted_The_file_cannot_be_restored, "warning");
                    }
                })
                .catch((error) => {
                    this.showNotification(Error, error.message, "Error");
                });
        } else {
            this.showNotification(Error, this.CUSTOM_LABELS.RecycleBin_Error_Msg, "Error");
        }
    }

    // To handle select all checkbox
    handleSelectAll(event) {
        let bolDetailEvent = event.detail.checked;
        this.arrExternalFileId = [];

        // Update all checkboxes based on the select-all state
        for (let i = 0; i < this.arrExtFileData.length; i++) {
            this.arrExtFileData[i].bolSelectCheckbox = bolDetailEvent;
            if (bolDetailEvent) {
                this.arrExternalFileId.push(this.arrExtFileData[i].Id);
            }
        }

        if (!bolDetailEvent) {
            this.arrExternalFileId = [];
        }
        // Update bolAllChecked to match the select-all checkbox state
        this.bolAllChecked = bolDetailEvent;

    }


    // Search logics
    handleSearch(event) {
        this.strSearchvalue = event.detail.value;
        this.getSearchResults();
    }

    getSearchResults() {
        this.arrExtFileData = this.arrCloneExtFileData;
        if (this.strSearchvalue !== "") {
            this.arrExtFileData = this.arrExtFileData.filter((current) => {
                return current.Name.toLowerCase().includes(this.strSearchvalue.toLowerCase()) || current.File_Name__c.toLowerCase().includes(this.strSearchvalue.toLowerCase()) || current.Object_Type__c.toLowerCase().includes(this.strSearchvalue.toLowerCase());
            });
        }
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