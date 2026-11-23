/*
 *
 * Purpose : To retrieve files from external system.
 * Author  : Giri
 *
 */
import { LightningElement, api, track } from "lwc";

// Importing Custom Labels
import ACTION from "@salesforce/label/c.ACTION";
import Delete from "@salesforce/label/c.Delete";
import Download from "@salesforce/label/c.Download";
import File_Name from "@salesforce/label/c.File_Name";
import File_Size from "@salesforce/label/c.File_Size";
import File_Type from "@salesforce/label/c.File_Type";
import Loading from "@salesforce/label/c.Loading";
import No_related_files_found from "@salesforce/label/c.No_related_files_found";
import View_All from "@salesforce/label/c.View_All";
import filetranzcustomstyle from "@salesforce/resourceUrl/filetranzcustomstyle";
import { loadStyle } from "lightning/platformResourceLoader";
import Confirm_Delete from "@salesforce/label/c.Confirm_Delete";
import Are_you_sure_you_want_to_delete_it from "@salesforce/label/c.Are_you_sure_you_want_to_delete_it";
import Yes from "@salesforce/label/c.Yes";
import No from "@salesforce/label/c.No";


// Importing Static Resources
import IMAGES from "@salesforce/resourceUrl/FTstaticResource";


export default class ViewFiles extends LightningElement {
	@api recordId;
	@api parentState;
	@api parentData;

	@track data = {
		arrTempFiles: [],
	};
	@track state;
	@track bolSpinner = false;
	@track bolDelete = false;
	@track strStraction = '';
	@track strInvokingscreen = '';
	@track strTargetId = '';
	@track strFileName = '';

	strFtIconUrl = IMAGES + "/FTstaticResource/ft_icon.svg"

	CUSTOM_LABELS = {
		File_Name,
		File_Size,
		File_Type,
		ACTION,
		Download,
		Delete,
		View_All,
		No_related_files_found,
		Loading,
		Confirm_Delete,
		Are_you_sure_you_want_to_delete_it,
		Yes,
		No
	};

	connectedCallback() {
		this.data.arrTempFiles = this.parentData.arrTempFiles;
		this.data.strTitle = this.parentData.strTitle;
		this.state = JSON.parse(JSON.stringify(this.parentState));
		loadStyle(this, filetranzcustomstyle);
	}

	// To open View All Screen
	handleViewAll() {
		this.dispatchEvent(new CustomEvent("handleviewallfile"));
	}

	// To dispatch event ot parent to handle file preview, download, delete actions.
	handlePrevDelDownload(event) {
		if(event.currentTarget.dataset.straction == 'Delete'){
			this.strStraction = event.currentTarget.dataset.straction;
			this.strInvokingscreen = event.currentTarget.dataset.invokingscreen;
			this.strTargetId = event.currentTarget.dataset.strid;
			this.strFileName = event.currentTarget.dataset.filename;			
			this.bolDelete = true
		}else{
			this.dispatchEvent(new CustomEvent("handleprevdeldownload", {
				detail: {
					strStraction: event.currentTarget.dataset.straction,
					strInvokingscreen: event.currentTarget.dataset.invokingscreen,
					strTargetId: event.currentTarget.dataset.strid,
					strFileName: event.currentTarget.dataset.filename
				}
			}));
		}
	}
	@api handleRefresh(){
        this.bolSpinner = true;

        setTimeout(() => {
            this.data.arrTempFiles = this.parentData.arrTempFiles;
            this.data.strTitle = this.parentData.strTitle;
            this.state = JSON.parse(JSON.stringify(this.parentState));
            this.bolSpinner = false;
			this.strStraction = '';
			this.strInvokingscreen = '';
			this.strTargetId = '';
			this.strFileName = '';
        }, 1000);
	}

	hideDeleteModal() {
		this.bolDelete = false;
	}

	handleConfirmDelete(){
		try {			
			this.dispatchEvent(new CustomEvent("handleprevdeldownload", {
				detail: {
					strStraction: this.strStraction,
					strInvokingscreen: this.strInvokingscreen,
					strTargetId: this.strTargetId,
					strFileName: this.strFileName
				}
			}));
			this.bolDelete = false;
			this.handleRefresh();
		} catch (error) {
			console.log('handleConfirmDelete : Error : ',error.message);			
		}

	}
}