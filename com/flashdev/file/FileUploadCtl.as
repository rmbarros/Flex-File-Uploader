			/*
				
			Written by:
			Dustin Andrew
			dustin@flash-dev.com
			www.flash-dev.com
			
			FileUpload
			
			Panel component for uploading files.
			(Icons from http://www.famfamfam.com)
			
			LAST UPDATED:
			12/15/06
			
			*/
			
			import mx.controls.*;
			import mx.managers.*;
            import mx.events.*;
			import flash.events.*;
			import flash.net.*;
			import nl.demonsters.debugger.MonsterDebugger;
			
			private var _strUploadUrl:String;
			private var _refAddFiles:FileReferenceList;	
			private var _refUploadFile:FileReference;
			private var _arrUploadFiles:Array;
			private var _numCurrentUpload:Number = 0;			
			
			[Bindable]
			public var skinClass:Class;
			
			// Set uploadUrl
			public function set uploadUrl(strUploadUrl:String):void {
				_strUploadUrl = strUploadUrl;
			}
			
			// Initalize
			private function initCom():void {
				_arrUploadFiles = new Array();				
				enableUI();
				uploadCheck();
			}
			
			// Called to add file(s) for upload
			private function addFiles():void {
				_refAddFiles = new FileReferenceList();
				_refAddFiles.addEventListener(Event.SELECT, onSelectFile);
				_refAddFiles.browse();
			}
			
			// Called when a file is selected
			private function onSelectFile(event:Event):void {
				var arrFoundList:Array = new Array();
				// Get list of files from fileList, make list of files already on upload list
				for (var i:Number = 0; i < _arrUploadFiles.length; i++) {
					for (var j:Number = 0; j < _refAddFiles.fileList.length; j++) {
						if (_arrUploadFiles[i].name == _refAddFiles.fileList[j].name) {
							arrFoundList.push(_refAddFiles.fileList[j].name);
							_refAddFiles.fileList.splice(j, 1);
							j--;
						}
					}
				}
				if (_refAddFiles.fileList.length >= 1) {				
					for (var k:Number = 0; k < _refAddFiles.fileList.length; k++) {
						_arrUploadFiles.push({
							name:_refAddFiles.fileList[k].name,
							size:formatFileSize(_refAddFiles.fileList[k].size),
							file:_refAddFiles.fileList[k]});
					}
					listFiles.dataProvider = _arrUploadFiles;
					listFiles.selectedIndex = _arrUploadFiles.length - 1;
				}				
				if (arrFoundList.length >= 1) {
					Alert.show("The file(s): \n\n• " + arrFoundList.join("\n• ") + "\n\n...are already on the upload list. Please change the filename(s) or pick a different file.", "File(s) already on list");
				}
				updateProgBar();
				scrollFiles();
				uploadCheck();
			}
			
			// Called to format number to file size
			private function formatFileSize(numSize:Number):String {
				var strReturn:String;
				numSize = Number(numSize / 1000);
				strReturn = String(numSize.toFixed(1) + " KB");
				if (numSize > 1000) {
					numSize = numSize / 1000;
					strReturn = String(numSize.toFixed(1) + " MB");
					if (numSize > 1000) {
						numSize = numSize / 1000;
						strReturn = String(numSize.toFixed(1) + " GB");
					}
				}				
				return strReturn;
			}
			
			// Called to remove selected file(s) for upload
			private function removeFiles():void {
				var arrSelected:Array = listFiles.selectedIndices;
				if (arrSelected.length >= 1) {
					for (var i:Number = 0; i < arrSelected.length; i++) {
						_arrUploadFiles[Number(arrSelected[i])] = null;
					}
					for (var j:Number = 0; j < _arrUploadFiles.length; j++) {
						if (_arrUploadFiles[j] == null) {
							_arrUploadFiles.splice(j, 1);
							j--;
						}
					}
					listFiles.dataProvider = _arrUploadFiles;
					listFiles.selectedIndex = 0;					
				}
				updateProgBar();
				scrollFiles();
				uploadCheck();
			}
			
			// Called to check if there is at least one file to upload
			private function uploadCheck():void {
				if (_arrUploadFiles.length == 0) {
					btnUpload.enabled = false;
					listFiles.verticalScrollPolicy = "off";
				} else {
					btnUpload.enabled = true;
					listFiles.verticalScrollPolicy = "on";
				}
			}
			
			// Disable UI control
			private function disableUI():void {
				btnAdd.enabled = false;
				btnRemove.enabled = false;
				btnUpload.enabled = false;
				btnCancel.enabled = true;
				listFiles.enabled = false;
				listFiles.verticalScrollPolicy = "off";
			}
			
			// Enable UI control
			private function enableUI():void {
				btnAdd.enabled = true;
				btnRemove.enabled = true;
				btnUpload.enabled = true;
				btnCancel.enabled = false;
				listFiles.enabled = true;
				listFiles.verticalScrollPolicy = "on";
			}
			
			// Scroll listFiles to selected row
			private function scrollFiles():void {
				listFiles.verticalScrollPosition = listFiles.selectedIndex;
				listFiles.validateNow();
			}
			
			// Called to upload file based on current upload number
			private function startUpload():void {
				MonsterDebugger.trace(this, "startUpload");
				if (_arrUploadFiles.length > 0) {
					
					MonsterDebugger.trace(this, _arrUploadFiles.length);
					
					disableUI();
					
					listFiles.selectedIndex = _numCurrentUpload;
					scrollFiles();
					
					// Variables to send along with upload
					var sendVars:URLVariables = new URLVariables();
					sendVars.action = "upload";
					
					var request:URLRequest = new URLRequest();
					request.data = sendVars;
				    request.url = _strUploadUrl;
					MonsterDebugger.trace(this, _strUploadUrl);
				    request.method = URLRequestMethod.POST;
				    _refUploadFile = new FileReference();
				    _refUploadFile = listFiles.selectedItem.file;
				    _refUploadFile.addEventListener(ProgressEvent.PROGRESS, onUploadProgress);
				   	_refUploadFile.addEventListener(Event.COMPLETE, onUploadComplete);
				    _refUploadFile.addEventListener(IOErrorEvent.IO_ERROR, onUploadIoError);
				  	_refUploadFile.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onUploadSecurityError);
				   _refUploadFile.upload(request, "file", false);
				   
				   _refUploadFile.addEventListener(Event.OPEN, function(evt:Event):void { MonsterDebugger.trace(this, evt) } );
				    _refUploadFile.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, function(evt:DataEvent):void { MonsterDebugger.trace(this, evt) } );
					 _refUploadFile.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(evt:HTTPStatusEvent):void{MonsterDebugger.trace(this, evt)});

 
					
					MonsterDebugger.trace(this, "started");
					
				}
			}
			
			// Cancel and clear eventlisteners on last upload
			private function clearUpload():void {
				_refUploadFile.removeEventListener(ProgressEvent.PROGRESS, onUploadProgress);
				_refUploadFile.removeEventListener(Event.COMPLETE, onUploadComplete);
				_refUploadFile.removeEventListener(IOErrorEvent.IO_ERROR, onUploadIoError);
				_refUploadFile.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onUploadSecurityError);
				_refUploadFile.cancel();
				_numCurrentUpload = 0;
				updateProgBar();
				enableUI();
			}
			
			// Called on upload cancel
			private function onUploadCanceled():void {
				clearUpload();
				dispatchEvent(new Event("uploadCancel"));
			}
			
			// Get upload progress
			private function onUploadProgress(event:ProgressEvent):void {
				MonsterDebugger.trace(this, "ProgressEvent");
				var numPerc:Number = Math.round((event.bytesLoaded / event.bytesTotal) * 100);
				updateProgBar(numPerc);
				var evt:ProgressEvent = new ProgressEvent("uploadProgress", false, false, event.bytesLoaded, event.bytesTotal);
				dispatchEvent(evt);
				MonsterDebugger.trace(this, numPerc);
			}
			
			// Update progBar
			private function updateProgBar(numPerc:Number = 0):void {
				var strLabel:String = (_numCurrentUpload + 1) + "/" + _arrUploadFiles.length;
				strLabel = (_numCurrentUpload + 1 <= _arrUploadFiles.length && numPerc > 0 && numPerc < 100) ? numPerc + "% - " + strLabel : strLabel;
				strLabel = (_numCurrentUpload + 1 == _arrUploadFiles.length && numPerc == 100) ? "Upload Complete - " + strLabel : strLabel;
				strLabel = (_arrUploadFiles.length == 0) ? "" : strLabel;
				progBar.label = strLabel;
				progBar.setProgress(numPerc, 100);
				progBar.validateNow();
			}
			
			// Called on upload complete
			private function onUploadComplete(event:Event):void {
				_numCurrentUpload++;				
				if (_numCurrentUpload < _arrUploadFiles.length) {
					startUpload();
				} else {
					enableUI();
					clearUpload();
					dispatchEvent(new Event("uploadComplete"));
				}
			}
			
			// Called on upload io error
			private function onUploadIoError(event:IOErrorEvent):void {
				clearUpload();
				var evt:IOErrorEvent = new IOErrorEvent("uploadIoError", false, false, event.text);
				dispatchEvent(evt);
			}
			
			// Called on upload security error
			private function onUploadSecurityError(event:SecurityErrorEvent):void {
				clearUpload();
				var evt:SecurityErrorEvent = new SecurityErrorEvent("uploadSecurityError", false, false, event.text);
				dispatchEvent(evt);
			}
			
			// Change view state
			private function changeView():void {
				currentState = (currentState == "mini") ? "" : "mini";
			}