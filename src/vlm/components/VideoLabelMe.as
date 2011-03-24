//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Point;
	import flash.net.*;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import mx.charts.events.LegendMouseEvent;
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.List;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.events.VideoEvent;
	import mx.managers.CursorManager;
	import mx.managers.ToolTipManager;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import preload.InitPreloader;
	import preload.PercentagePreloader;
	
	import vlm.components.annotator.Annotator;
	import vlm.events.LMAnnotationEvent;

	import vlm.core.LMEventAnnotationItem;
	import vlm.core.LMObjectAnnotationItem;
	import vlm.core.LMPolygon;
	import vlm.components.annotator.LMPolygonSprite;
	import vlm.core.LMXMLAnnotation;
	import vlm.events.LMXMLEvent;
	import vlm.core.PolygonSpriteState;
	import vlm.MTData;
	import vlm.components.videoplayer.controls.fxslider.LMProgressSliderEvent;
	import vlm.events.LMEvent;
	import vlm.events.LMEventsEvent;
	import vlm.util.LMJSUtil;
	import vlm.components.videoplayer.controls.FXVideo;
	import vlm.components.videoplayer.controls.LMAnnotationControlBar;
	
	public class VideoLabelMe extends UIComponent
	{
		private var _lmAnnotation:LMXMLAnnotation;
		private var _annotator:Annotator;
		private var _videoPlayer:FXVideo;
		private var _lmObjList:LMObjectsList;
		private var _lmEventList:LMEventsList;
		private var _annotationControlBar:LMAnnotationControlBar;
		private var _topMenu:TopMenu;
		private var _listSelected:Boolean= false;
		//		private var _preloaderWindow:CustomPreloader;
		private var _preloader:InitPreloader;
		private var _savePreloader:PercentagePreloader;
		
		private var _currFrame:int;
		private var _state:String;
		private var _heldId:int;
		private var _eventHeldId:int;
		private var _objDict:Dictionary;
		private var _objFrameInfoDict:Dictionary;
		private var _eventDict:Dictionary;
		private var _eventFrameInfoDictionary:Dictionary;
		private var _lockId:int;
		private var _selectedId:int;
		private var _selectedEventId:int;
		private var _highlightedId:int;
		private var _lastOId:int;
		private var _actions:String;
		
		private var _winScaleX:Number;
		private var _winScaleY:Number;
		
		
		private var _mtData:MTData;
		
		public var _videoFolder:String;
		public var _videoFileName:String;
		private var _xmlLink:String;
		private var _framesLink:String;
		
		//display components
		private var _videoAnnotatorBox:VBox;
		private var _videoDisplayCanvas:Canvas;
		private var _hbox1:HBox;
		private var _mainCanvas:Canvas;
		private var _vBox1:VBox;
		private var _hbox2:HBox;
		
		//event annotation helper variables
		private var _evtStartFrame:int;
		private var _evtEndFrame:int;
		
		//queue to hold the points of the currently selected object that have been modified
		private var _modPointIds:Array;
		private var _selectedSprite:LMPolygonSprite;
		private var _flushing:Boolean;
		private var _spriteState:String;
		//style information
		private var lmObjectStyleName:String;
		
		//video state information
		private var metadataReceived:Boolean = false;
		private var _xmlLoaded:Boolean = false;
		private var _videoLoaded:Boolean = false;
		
		private var _binMode:Boolean = true;
		private var _binAnnotName:String = "";
		private static  var VIDEOSBASEHREF:String = "http://labelme.csail.mit.edu/LabelMeVideo/VLMVideos/"
		private static  var XMLBASEHREF:String = "http://labelme.csail.mit.edu/LabelMeVideo/VLMAnnotations/"
		private static  var FRAMEBASEHREF:String = "http://labelme.csail.mit.edu/LabelMeVideo/VLMFrames/"
		
		private var _fileRootName:String;
		private var _fileRef:FileReference;
		
		private var _vlmFilter:FileFilter = new FileFilter("VLM annotations", "*.vlm");
		
		private var _initPoly:LMPolygon;
		private var _polyStr:String;
		private var _polyFieldStr:String;
		private var _annotatorReady:Boolean;
		
		
		public function VideoLabelMe(actions:String="v", annotationMode:String="poly", mtData:MTData=null, binMode:Boolean=false, 
									 folder:String="video_sun_database/s/street", filename:String="sun_velxcjbuvrypwba.flv", polyStr:String="", polyFieldStr:String="")
		{
			super();
			this._binMode = binMode;
			this._actions = actions;
			if(this._actions == "v")
				this._spriteState = PolygonSpriteState.VIEWONLY;
			else
				this._spriteState = PolygonSpriteState.ALL;
			
			//Alert.show("folder " + folder  + " filename " + filename);
			//xml 
			var xmlName:String = filename;
			//the Mechanical turk data 
			this._mtData = mtData;
			this._preloader = new InitPreloader();
			this._savePreloader = new PercentagePreloader();
			this._binMode = binMode;
			var idx:int = xmlName.indexOf(".");
			if(idx!=-1){
				
				this._fileRootName = xmlName.substr(0, idx);
				var rootName:String = folder + "/" + _fileRootName;
				
				xmlName = rootName + ".xml";
				this._framesLink = FRAMEBASEHREF + "/" + rootName;
				
			}
			else {
				Alert.show("error on input string");
				this._framesLink = "";
				this._fileRootName = filename;
			}
			_xmlLink = XMLBASEHREF + xmlName;
			
			_lmAnnotation = new LMXMLAnnotation(filename, xmlName, 1.0, folder, 0, 0, null, this._spriteState);
			if(!binMode)
			{
				this._lmAnnotation.downloadLMXMLAnnotation();
			}
			else
				this._xmlLoaded = true;
			//top menu
			_topMenu = new TopMenu();
			
			//annotator
			_annotator = new Annotator(this._spriteState, annotationMode);
			
			//video player
			_videoPlayer = new FXVideo();	
			_videoPlayer.addEventListener(LMEvent.VIDEOREADY, onMetaDataReceived)
			_videoPlayer.addEventListener(VideoEvent.READY, onVideoReady);
			_videoPlayer.addEventListener(ProgressEvent.PROGRESS, onVideoProgress);
			_videoPlayer.addEventListener(LMProgressSliderEvent.LEFTBRACKETMOVETOPLAYHEADREQUEST, onLeftBracketMoveToPlayheadRequest);
			_videoPlayer.addEventListener(LMProgressSliderEvent.RIGHTBRACKETMOVETOPLAYHEADREQUEST, onRightBracketMoveToPlayheadRequest);
			
			
			//objects list
			_lmObjList = new LMObjectsList();
			
			//events list
			_lmEventList = new LMEventsList();
			
			//annotation preloader
			_videoFolder = folder;
			_videoFileName = filename;
			_videoPlayer.source = VIDEOSBASEHREF + "/" + folder + "/" +filename;
			_videoPlayer.autoPlay = false;
			//Alert.show("in constructor : " + _videoPlayer.source);
			//other variables 
			_currFrame = 1;
			_state = State.NOTHING;
			_heldId = -1;
			_eventHeldId = -1;
			_objDict = new Dictionary();
			_objFrameInfoDict = new Dictionary();
			_eventDict = new Dictionary();
			_eventFrameInfoDictionary = new Dictionary();
			_lockId = -1;
			_selectedId = -1;
			_highlightedId = -1;
			
			//keeping a queue of the modified points
			_modPointIds = new Array();
			_selectedSprite = null;
			_flushing = false;
			
			_fileRef = new FileReference();
			
			//listen for when they select a file
			
			
			//tooltip manager. Enables the display of tool tip tags on displayobjects
			ToolTipManager.enabled = true;
			
			_lastOId = -1;
			
			//parse polygon string if it is not empty. This denotes how we should add an object at the desired frame
			_polyStr = polyStr;
			this._annotatorReady = false;
			this._polyFieldStr = polyFieldStr;
			
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			_mainCanvas = new Canvas();
			this.addChild(_mainCanvas);
			
			_videoAnnotatorBox = new VBox();
			_videoDisplayCanvas = new Canvas();
			_hbox1 = new HBox();
			_vBox1 = new VBox();
			_hbox2 = new HBox();
			
			_mainCanvas.addChild(this._videoAnnotatorBox);
			
			_videoAnnotatorBox.addChild(this._topMenu);
			_videoAnnotatorBox.addChild(_hbox1);
			_hbox1.addChild(this._videoDisplayCanvas);
			
			
			_vBox1.addChild(_hbox2);
			_hbox2.addChild(this._lmObjList);
			_hbox2.addChild(this._lmEventList);
			_hbox1.addChild(_vBox1);
			
			_videoDisplayCanvas.addChild(_videoPlayer);
			_videoDisplayCanvas.addChild(_annotator);
			
			_lmAnnotation.addEventListener(LMEvent.LISTCHANGE, onObjListChange);
			_lmAnnotation.addEventListener(LMEvent.EVENTLISTCHANGE, onEventListChange);
			_lmAnnotation.addEventListener(LMAnnotationEvent.DONECUTTINGFRAMES, onDoneCuttingFrames);
			_lmAnnotation.addEventListener(FaultEvent.FAULT, onFaultXMLLoad);	
			_lmAnnotation.addEventListener(LMXMLEvent.XMLDOWNLOADED, onLoadedXML);
			_lmAnnotation.addEventListener(LMEvent.COMMITFAIL, onCommitFail);
			_lmAnnotation.addEventListener(LMEvent.COMMITSUCCESS, onCommitSuccess);
			_lmAnnotation.addEventListener(LMAnnotationEvent.ANNOTATIONPACKAGINGPROGRESS, onAnnotationPackagingProgress);
			_lmAnnotation.addEventListener(LMXMLEvent.XMLPERCENTOBJECTSPROCESSED, onSaveProgressUpdate);
			_lmAnnotation.addEventListener(LMXMLEvent.XMLOBJECTSREADY, onObjectsProcessed);
			_lmAnnotation.addEventListener(LMXMLEvent.XMLPOLYGONSPROCESSDPROGRESS, onXMLPolygonsProcessed);
			
			//	this.addEventListener(MouseEvent.MOUSE_MOVE, onAnnotationHover);
			_annotator.addEventListener(MouseEvent.CLICK, onAnnotatorCanvasClick);
			_annotator.addEventListener(LMAnnotationEvent.CREATEOBJECT, onCreateObject);
			//		_annotator.addEventListener(LMEvent.POLYGONCHANGE, onPolyChange);
			_annotator.addEventListener(LMEvent.POLYSELECTED, onPolySelected);
			_annotator.addEventListener(LMEvent.POLYHIGHLIGHTED, onPolyHighlighted);
			_annotator.addEventListener(LMEvent.POLYUNHIGHLIGHTED, onPolyUnHighlighted);
			_annotator.addEventListener(LMEvent.POLYHOLD, onPolyHold);
			_annotator.addEventListener(LMEvent.POLYUNHOLD, onPolyUnhold);
			
			_annotator.addEventListener(LMAnnotationEvent.ANNOTATENEWFRAME, onAnnotateNewFrame);
			_annotator.addEventListener(LMAnnotationEvent.DELETEOBJECTANNOTATION, onDeleteObject);
			_annotator.addEventListener(LMAnnotationEvent.RENAMEOBJECT, onRenameObject);
			_annotator.addEventListener(LMAnnotationEvent.POINTCHANGE, onAnnotationPointChange);
			_annotator.addEventListener(LMAnnotationEvent.POLYTRANSLATE, onAnnotationTranslate);
			_annotator.addEventListener(LMAnnotationEvent.POLYSCALE, onAnnotationScale);
			_annotator.addEventListener(LMAnnotationEvent.CANCELANNOTATIONCREATION, onCancelObjectCreation);
			_annotator.addEventListener(LMAnnotationEvent.SPRITECLICK, onAnnnotationSpriteClick);
			_annotator.addEventListener(LMEventsEvent.CANCELEVENTCREATION, onCancelEventAnnotation);
			_annotator.addEventListener(LMEventsEvent.EVENTCHANGED, onEventChangedInAnnotator);
			_annotator.addEventListener(LMEventsEvent.ADDNEWLINK, onNewLinkAdded);
			_annotator.addEventListener(LMEventsEvent.SELECTEVENTREQUEST, onEventSelect);
			
			var list:List = _lmObjList.getSourceList();
			list.addEventListener(ListEvent.ITEM_CLICK, onListSelect);
			_lmObjList.addEventListener(LMAnnotationEvent.DELETEOBJECTANNOTATION, onDeleteObject);
			list.addEventListener(LMAnnotationEvent.RENAMEOBJECT, onRenameObject);
			
			_lmEventList.addEventListener(LMEventsEvent.SHOWEVENTS, onShowEventsRequest);
			_lmEventList.addEventListener(LMEventsEvent.HIDEEVENTS, onHideEventsRequest);
			
			
			_lmObjList.addEventListener(LMEvent.SHOWOBJECTS, onShowObjectsRequest);
			_lmObjList.addEventListener(LMEvent.HIDEOBJECTS, onHideObjectsRequest);
			
			
			_lmEventList.addEventListener(LMEventsEvent.ADDEVENTCLICK, onAddEventClick);
			var eventsList:List = _lmEventList.source as List;
			eventsList.addEventListener(ListEvent.ITEM_CLICK, onEventListSelect);
			
			_annotator.addEventListener(LMEventsEvent.SAVENEWEVENTCLICK, onSaveNewClick);
			_annotator.addEventListener(LMEventsEvent.DELETECLICK, onEventAnnotatorDeleteClick);
			
			_videoPlayer.addEventListener(VideoEvent.PLAYHEAD_UPDATE, onFrameChange);
			_videoPlayer.playheadUpdateInterval = 20;
			_videoPlayer.addEventListener(LMEvent.DELETEPOLYSOUTSIDERANGE, onDeletePolysOutOfRange);
			_videoPlayer.addEventListener(LMEvent.KEYFRAMESELECTED, onKeyFrameSelected);
			
			_topMenu.addEventListener(FlexEvent.CREATION_COMPLETE, onTopMenuCreationComplete);
			
			this.addChild(_preloader);
			hideAnnotationSlider();
			
			_topMenu.addEventListener(LMEvent.SAVEANNOTATIONSREQUEST, onSaveAnnotationsRequest);
			_topMenu.addEventListener(LMEvent.ERASEREQUEST, onEraseRequest);
			_topMenu.addEventListener(LMEvent.OPENANNOTATIONSREQUEST, onOpenAnnotationsRequest);
			
			
			//events for enabling and disabling event annotation
			_topMenu.addEventListener(LMEvent.ENABLEEVENTANNOTATION, onEnableEventAnnotation);
			_topMenu.addEventListener(LMEvent.DISABLEEVENTANNOTATION, onDisableEventAnnotation);
			
			
			_topMenu.setXMLLink( this._xmlLink);
			_topMenu.setFrameLink(this._framesLink);
			if(this._actions == "v")
				_topMenu.annotationModeLabel.text = "View only mode. If the video doesn't appear, click Refresh.";
			this.addEventListener(FlexEvent.UPDATE_COMPLETE, onUpdateComplete)
			
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			
			this.lmObjectStyleName = getStyle("LMObjListScrollBarStyleName");
			
			//	this._lmObjList.setStyle("styleName", lmObjectStyleName);
			if(this._mtData && this._mtData._mtMode)
			{
				_topMenu.enableMTMode(this._mtData);
			}
			if(this._spriteState == PolygonSpriteState.VIEWONLY){
				this._topMenu.disableSave();
				this._topMenu.disableErase();
				
			}
			updateSizeProperties2();
			
			
		}
		
		override protected function measure():void
		{
			super.measure();
			this.percentHeight = 100;
			this.percentWidth = 100;
			updateSizeProperties3();
			
		}
		
		private function updateSizeProperties3():void
		{
			_mainCanvas.percentHeight = 100;
			_mainCanvas.percentWidth = 100;
			
			_videoAnnotatorBox.percentHeight = 100;
			_videoAnnotatorBox.percentWidth = 100;
			
			_videoPlayer.minWidth = 640;
			_videoPlayer.minHeight = 480;
		}
		
		private function updateSizeProperties2():void
		{
			var scale:Number = 1;
			var MINVIDEOVIEWWIDTH:int = 640;
			if(this.width*0.6 < _videoPlayer.videoWidth)
			{	
				var effectiveWidth:int =  (this.width - this._lmObjList.width - this._lmEventList.width)*0.9;
				if(effectiveWidth < MINVIDEOVIEWWIDTH)
				{	
					_videoPlayer.width = MINVIDEOVIEWWIDTH;
					scale = _videoPlayer.width/ _videoPlayer.videoWidth;
					_videoPlayer.height = _videoPlayer.videoHeight*scale;
				}
				else
				{
					_videoPlayer.width = effectiveWidth;
					scale = _videoPlayer.width/ _videoPlayer.videoWidth;
					_videoPlayer.height = _videoPlayer.videoHeight*scale;
				}
			}
			else
			{
				var effectiveWidth:int =  (this.width - this._lmObjList.width - this._lmEventList.width)*0.7;
				_videoPlayer.width = effectiveWidth;
				scale = _videoPlayer.width/ _videoPlayer.videoWidth;
				_videoPlayer.height = _videoPlayer.videoHeight*scale;
				
				//scale the video up
				//_videoPlayer.width = _videoPlayer.videoWidth;
				//_videoPlayer.height = _videoPlayer.videoHeight;
			}
			this._winScaleX = this._videoPlayer.width/this._videoPlayer.videoWidth;	
			this._winScaleY = this._videoPlayer.height/this._videoPlayer.videoHeight;	
			
			
			_annotator.width =  _videoPlayer.width;
			_annotator.height = _videoPlayer.height;
			if(_videoPlayer.width >0 && this._videoPlayer.videoWidth>0) 
			{
				_annotatorReady = true;
				VLMCheckIfReady();
			}
			this._annotator.setScaleX(_winScaleX);
			this._annotator.setScaleY(_winScaleY);
			
			_videoDisplayCanvas.width = _annotator.width;
			_videoDisplayCanvas.height = _videoPlayer.getRealHeight();
			
			_mainCanvas.width = _videoAnnotatorBox.width + 10;
			_mainCanvas.height = _videoAnnotatorBox.height + 10;
			
			
			this._annotator.setScale(_winScaleX, _winScaleY);
			
		}
		
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			this._mainCanvas.setActualSize(unscaledWidth, unscaledHeight);
		}
		
		//getters and setters
		
		
		////////////////////event handlers
		private function onUpdateComplete(evt:FlexEvent):void
		{
		}
		
		private function commitReady():void
		{
		}
		
		
		private function constructMTSubmitURL(assignmentId:String, sandboxMode:Boolean):String
		{
			var url:String = "";
			if(sandboxMode)
			{	
				url = "http://workersandbox.mturk.com/mturk/externalSubmit?bacon=sure&assignmentId=" +assignmentId;
			}
			else
			{
				url = "http://www.mturk.com/mturk/externalSubmit?bacon=sure&assignmentId=" +assignmentId;
			}		
			return url;
		}
		
		private function constructMTForm(assignmentId:String, sandboxMode:Boolean):String
		{
			var form:String = "";
			if(sandboxMode)
			{	
				form = "<html><body><form id=\"mturk_form\" method=\"post\" action=\"http://workersandbox.mturk.com/mturk/externalSubmit\"><input type=\"hidden\" name=\"bacon\" value=\"0\">"
					+ "<input type=\"hidden\" name=\"assignmentId\" value=\""+assignmentId +"\"> </form>"
					+ "<script>document.forms[0].submit();</script>  </body></html>";
			}
			else
			{
				form = "<html><body><form id=\"mturk_form\" method=\"post\" action=\"http://www.mturk.com/mturk/externalSubmit\"><input type=\"hidden\" name=\"bacon\" value=\"0\">"
					+ "<input type=\"hidden\" name=\"assignmentId\" value=\""+assignmentId +"\"> </form>"
					+ "<script>document.forms[0].submit();</script>  </body></html>";
				
			}		
			return form;
		}
		
		
		private function commit():void
		{
			trace("attempting commit");
			
			this._lmAnnotation.commit();
			
			//now tell MT that we're done by redirecting to the mt link + the assignment id
			if(this._mtData && this._mtData._mtMode)
			{
				var url:String = this.constructMTSubmitURL(this._mtData._assignmentId,  (this._mtData._sandboxMode== "" || this._mtData._sandboxMode=="0"));
				//Alert.show("redirecting to " + url);
				LMJSUtil.jsRedirectToUrl(url);
			}
			
			trace("done commiting");
			
		}
		
		public function httpResult(event:ResultEvent):void {
			Alert.show("post successful" + event.result.toString());
			trace(event.result.toString());
			
			LMJSUtil.jsRenderHtml(event.result.toString());
		}
		
		
		public function httpFault(event:FaultEvent):void {
			var faultstring:String = event.fault.faultString;
			Alert.show("fault posting" + faultstring);
		}

		/* top menu handlers */
		private function onSaveAnnotationsRequest(evt:LMEvent):void
		{
			CursorManager.setBusyCursor();
			this.addChild(this._savePreloader);
			
			if(this._binMode)
			{
				var outputBytes:ByteArray = new ByteArray();
				this._lmAnnotation.writeExternal(outputBytes);
				_fileRef = new FileReference();
				_fileRef.save(outputBytes, this._fileRootName + ".vlm");
				_fileRef.addEventListener(Event.COMPLETE, onCompleteBinarySave);
				_fileRef.addEventListener(ProgressEvent.PROGRESS, onProgressUpdateBinarySave);
				_fileRef.addEventListener(IOErrorEvent.IO_ERROR, onErrorBinarySave);
				
				CursorManager.removeBusyCursor();
				
			}
			else
			{
				commit();		
			}
			
		}
		
		private function onFileSelect(evt:Event):void
		{
			
			
			//listen for when the file has loaded
			this._fileRef.addEventListener(Event.COMPLETE, onLoadComplete);
			
			//listen for any errors reading the file
			_fileRef.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			
			//load the content of the file
			// TODO: Does not work.
			_fileRef.load();
			//	_fileRef.save(outputBytes);
			CursorManager.removeBusyCursor();
			
		}
		
		private function onLoadComplete(evt:Event):void
		{
			var done:Boolean = true;
			this._lmAnnotation.readExternal(evt.target.data);
			
		}
		
		private function onLoadError(evt:Event):void
		{
			Alert.show("problem reading binary file");
		}
		
		
		
		private function onFileBrowseCancel(evt:Event):void
		{
			CursorManager.removeBusyCursor();
		}
		
		
		private function onOpenAnnotationsRequest(evt:Event):void
		{
			_fileRef.addEventListener(Event.SELECT, onFileSelect);
			_fileRef.addEventListener(Event.CANCEL, onFileBrowseCancel);
			
			
			//pops up the filereference and lets the user pull out a file
			_fileRef.browse([_vlmFilter]);
			
			//then it reads it
			//	var annotByteArray:ByteArray = _fileRef.data;
			//	annotByteArray.position = 0;
			//	this._lmAnnotation.readExternal(annotByteArray);
			
		}
		
		private function onEraseRequest(evt:LMEvent):void
		{
			switch(_state)
			{
				case State.ANNOTATING:
					if(!_annotator.undo())
					{
						//no point to undo in annotation, we need to go to the nothing state
						_state = State.NOTHING;
						this._topMenu.statusLabel.text = "ready";
					}
					break;
				
				case State.POLYSELECTED:
					_lmAnnotation.deleteObject(this._heldId);
					this._selectedId = -1;
					this.hideAnnotationSlider();
					
					commitReady();
					break;
				
				case State.EVENTSELECTED:
					var item:LMEventAnnotationItem = LMEventAnnotationItem(this._lmEventList.source.selectedItem);
					if(item)
						this.deleteEventAnnotation(item.eid);
					break;
				
				default: 
					break;	
			}
		}
		
		private function onEnableEventAnnotation(evt:LMEvent):void
		{
			this._lmEventList.visible = true;		
		}
		
		private function onDisableEventAnnotation(evt:LMEvent):void
		{
			this._lmEventList.visible = false;
			//_topMenu.removeEventAnnotationComponent();
		}
		
		/* video event handlers functions */
		private function onVideoReady(evt:VideoEvent):void
		{
			
			this.removeEventListener(VideoEvent.READY,onVideoReady);
			this.invalidateProperties();
			_currFrame = VideoLabelMe.time2Frame(_videoPlayer.playheadTime, _videoPlayer.fps);
		}
		
		private function onVideoProgress(event:ProgressEvent):void
		{
			var loadProgress:int = Math.floor(event.bytesLoaded/event.bytesTotal*100);
			//	this._preloaderWindow.updateVideoLoadProgress(loadProgress);	
			this._preloader.updateVideoLoadProgress(loadProgress);
			if(loadProgress >=100)
			{
				_videoLoaded = true;
				VLMCheckIfReady();
			}
		}
		
		private function onLeftBracketMoveToPlayheadRequest(e:LMProgressSliderEvent):void
		{
			
			_videoPlayer.setLeftBracketBoundary(this._currFrame);
		}
		
		private function onRightBracketMoveToPlayheadRequest(e:LMProgressSliderEvent):void
		{
			_videoPlayer.setRightBracketBoundary(this._currFrame);	
		}
		private function onMetaDataReceived(evt:LMEvent):void
		{
			_annotator.setTimeInfo(_videoPlayer.totalTime, _videoPlayer.fps);
			_lmAnnotation.totalTime = _videoPlayer.totalTime;
			_lmAnnotation.fps = _videoPlayer.fps;
			_lmAnnotation.numFrames = VideoLabelMe.time2Frame(_videoPlayer.totalTime, _videoPlayer.fps);
			_videoPlayer.setAnnotationSlider(0, VideoLabelMe.time2Frame(_videoPlayer.totalTime, _videoPlayer.fps));
			
			metadataReceived = true;
			
			this.invalidateProperties();
			this.invalidateDisplayList();	
			this.invalidateSize();
			
		}
		
		private function onTopMenuCreationComplete(evt:Event):void
		{
			
			_topMenu.openButton.visible = _binMode;
		}
		private function onCancelObjectCreation(evt:LMAnnotationEvent):void
		{
			if(this._state == State.ANNOTATING)
			{
				_state = this.transitionState(_state, LMAction.FINISHPOLYGON);
			}
			
		}
		private function onCancelEventAnnotation(evt:LMEventsEvent):void
		{
			if(this._state == State.ANNOTATINGEVENT)
			{
				_state = this.transitionState(_state, LMAction.FINISHANNOTATINGEVENT);
				
			}
		}
		
		
		
		private function onNewLinkAdded(evt:LMEventsEvent):void
		{
			if(this._state == State.ANNOTATINGEVENT || this._state == State.EVENTSELECTED)
			{
				//get the new time boundaries
				var oId:int = evt._objectId;
				if(oId)
				{
					var objInfo:LMObjectAnnotationItem = _objFrameInfoDict[String(oId)];
					_evtStartFrame = (_evtStartFrame==-1 || _evtStartFrame < objInfo.startFrame || _evtStartFrame<0) ? objInfo.startFrame : _evtStartFrame;
					_evtEndFrame = (_evtEndFrame==-1 || _evtEndFrame > objInfo.endFrame || _evtEndFrame<0) ? objInfo.endFrame : _evtEndFrame;
					_annotator.updateEventFrames(_evtStartFrame, _evtEndFrame);
					_videoPlayer.setLeftBrightBracketBoundaries(_evtStartFrame, _evtEndFrame);
					
					//	this._lmAnnotation.adjustEventFrames(this._selectedEventId, _evtStartFrame, _evtEndFrame);
				}
			}
		}
		
		private function onEventSelectRequest(evt:LMEventsEvent):void
		{
			
		}
		
		//called when the annotation toolbar timeline is edited
		private function onDeletePolysOutOfRange(evt:LMEvent):void
		{	
			if(this._state == State.POLYSELECTED)
			{
				if(_heldId!= -1)
				{
					trace("starting to cut");
					CursorManager.setBusyCursor();	
					this.flushOutAnnotationQueue()
					_lmAnnotation.removeComplementFrameAnnotations(_heldId, evt.startFrame, evt.endFrame);
					this.skipToFrame(evt.frame);
				}
			}
			else if(this._state == State.ANNOTATINGEVENT || this._state == State.EVENTSELECTED)
			{
				
				_evtStartFrame = evt.startFrame >=0 ? evt.startFrame : 0;
				_evtEndFrame = evt.endFrame >=0 ? evt.endFrame : 0;
				this.skipToFrame(evt.frame);
				_annotator.updateEventFrames(_evtStartFrame, _evtEndFrame);
				
				//this._lmAnnotation.adjustEventFrames(this._selectedEventId, _evtStartFrame, _evtEndFrame);
			}
		}
		
		private function onKeyFrameSelected(event:LMEvent):void
		{
			var f:int = event.frame;
			if(!isNaN(f) && f >=0)
			{
				//seek to the frame
				this.skipToFrame(f);
				trace("seeking to frame " + f);
			}	
		}
		
		
		
		private function onCompleteBinarySave(event:Event):void
		{
			Alert.show("Annotations saved");
			
			commitCleanup();	
			
			_fileRef.removeEventListener(Event.COMPLETE, onCompleteBinarySave);
			_fileRef.removeEventListener(ProgressEvent.PROGRESS, onProgressUpdateBinarySave);
			_fileRef.removeEventListener(IOErrorEvent.IO_ERROR, onErrorBinarySave);
		}
		
		private function commitCleanup():void
		{
			this.removeChild(this._savePreloader);
			CursorManager.removeBusyCursor();	
			
		}
		
		/* lmxmlannotation event handlers functions */
		private function onCommitSuccess(event:LMEvent):void
		{
			Alert.show("Annotations saved");
			commitCleanup();
		}
		
		private function onErrorBinarySave(event:IOErrorEvent):void
		{	
			Alert.show("Annotations failed to save");
			this.commitCleanup();
			
			_fileRef.removeEventListener(Event.COMPLETE, onCompleteBinarySave);
			_fileRef.removeEventListener(ProgressEvent.PROGRESS, onProgressUpdateBinarySave);
			_fileRef.removeEventListener(IOErrorEvent.IO_ERROR, onErrorBinarySave);
		}
		private function onCommitFail(event:LMEvent):void
		{
			Alert.show("Annotations failed to save");
			this.commitCleanup();
		}
		
		private function onAnnotationPackagingProgress(evt:LMAnnotationEvent):void
		{
			this._topMenu.polyHit.text = "" + evt._packagingProgress;
		}
		
		
		private function onProgressUpdateBinarySave(event:ProgressEvent):void
		{
			var percent:int = int(Number(event.bytesLoaded)/event.bytesTotal) * 100;
			this._savePreloader.updatePercentBottom(percent);	
		}
		
		private function onObjectsProcessed(evt:LMXMLEvent):void
		{
			
			this._savePreloader.updateMessageTop("Uploading XML...");	
			this._savePreloader.updatePercentTop(100);
			this._savePreloader.updatePercentBottom(100);
			
		}
		
		private function onXMLPolygonsProcessed(evt:LMXMLEvent):void
		{
			var str:String = evt._processedPolygons + " polygons out of " + evt._totalPolygons;
			this._savePreloader.updateMessageBottom(str);
			this._savePreloader.updatePercentBottom(Math.floor(100* evt._processedPolygons/evt._totalPolygons)); 
		}
		
		private function onSaveProgressUpdate(evt:LMXMLEvent):void
		{
			//_savePreloader.show();
			var str:String = evt._processedObjects + " objects out of " + evt._totalObjects;
			this._savePreloader.updateMessageTop(str);
			this._savePreloader.updatePercentTop(evt._percentObjectsProcessed);
			
		}
		
		
		
		private function onLoadedXML(event:LMXMLEvent):void
		{
			var polys:Array = _lmAnnotation.getPolygons(_currFrame);
			var events:Array = _lmAnnotation.getEvents(_currFrame);
			
			_annotator.annotateNewFrame(_currFrame, polys, events);
			_annotator.invalidateDisplayList();
			
			var str:String = "";
			if(event._stabilizationPresent)
				str = "Loaded annotations";
			else
				str = "Loaded annotations; no stabilization found";
			this._preloader.updateXMLString(str);
			//				this._preloader.updateXMLProgress(100);
			
			_xmlLoaded = true;
			VLMCheckIfReady();
			updateObjectList();
			updateEventList();
			
			
		}
		
		private function VLMCheckIfReady():Boolean
		{
			var ready:Boolean = (_xmlLoaded && _videoLoaded && _annotatorReady);
			try
			{
				if(ready)
				{
					this.removeChild(_preloader);
					this.drawInitialPolygon();
				}
			}
			catch(err:Error)
			{
				trace(err);
			}
			return ready;
		}
		
		private function onFaultXMLLoad(event:FaultEvent):void
		{
			this._preloader.updateXMLString("You will annotate a new file");
			
			_xmlLoaded = true;
			VLMCheckIfReady();
		}
		
		private function onDoneCuttingFrames(event:LMAnnotationEvent):void
		{
			//do something about filling the collor
			//			if(_heldId == event._id)
			this.annotateNewFrame(_currFrame);
			trace("done cutting frames");
			CursorManager.removeBusyCursor();
			//		updateObjectList();	
			this.commitReady();
		}
		
		private function showEventAnnotationSlider(createdFrame:int=-1):void
		{
			//update the data for the annotation slider
			_videoPlayer.showAnnotationSlider();
			var f:ArrayCollection = new ArrayCollection();
			if(createdFrame>=0)
			{
				f.addItem(createdFrame);
			}
			_videoPlayer.showHighlightFrames(f);
			
			trace("showing annotation slider for  event ");
		}
		
		private function hideEventAnnotationSlider():void
		{
			_videoPlayer.hideAnnotationSlider();	
		}
		
		private function showAnnotationSlider(objectId:int):void
		{
			_videoPlayer.showAnnotationSlider();
			this._videoPlayer.enableSubmitCutButton();
			var a:ArrayCollection = this._lmAnnotation.getManuallyLabeledFrames(objectId);
			_videoPlayer.showHighlightFrames(a);	
			trace("showing annotation slider keyframes for " + objectId);
		}
		
		private function hideAnnotationSlider():void
		{
			_videoPlayer.hideAnnotationSlider();
			this._videoPlayer.disableSubmitCutButton();
			trace("hiding annotation slider");
		}
		
		/* annotator event handlers */
		
		private function onPolyHold(evt:LMEvent):void
		{
			_heldId = evt.selectedId;
			if(_lockId == -1)
			{	
				_lockId = evt.selectedId;
				
				showAnnotationSlider(_lockId);			
			}	
		}
		
		private function onPolyUnhold(evt:LMEvent):void
		{
			_heldId = -1;	
			_lockId = -1;
		}
		
		private function onCreateObject(evt:LMAnnotationEvent):void
		{
			this.createObject(evt._name, evt._startFrame, evt._endFrame, evt._createdFrame, evt._polygon, evt._moving, evt._action);
		}
		
		private function createObject(name:String, startFrame:int, endFrame:int, createdFrame:int, poly:LMPolygon, moving:String, action:String)
		{
			//for now, event creators are anonymous. This will change when we add user profiles
			var oId:uint = _lmAnnotation.addObject(name,0, 0, "anonymous",
				startFrame, endFrame, createdFrame,poly, moving, action,true);
			this._annotator._annotCanvas.addEventListener(FlexEvent.UPDATE_COMPLETE, onAnnotatedFrame)
			_lastOId = oId;
			
			poly.objectId = oId;
			
			
			_annotator.setObjectId(oId);
			commitReady();
			_state = this.transitionState(_state, LMAction.FINISHPOLYGON);
			
			enableSave();
			
			
			//wait until the object is rendered and then select
			
		}
		
		//selects the last created annotation. This function is tied to the creation of an event
		private function onAnnotatedFrame(evt:FlexEvent):void
		{
			if(this._lastOId != -1)
				this.selectAnnotation(this._lastOId);	
			this._annotator._annotCanvas.removeEventListener(FlexEvent.UPDATE_COMPLETE, onAnnotatedFrame);
			
		}
		
		private function onPolyChange(evt:LMEvent):void
		{
			var l:List = _lmObjList.source as List;
			
			var s:LMPolygonSprite = evt.LMTarget() as LMPolygonSprite;
			selectAnnotation(s.lMPolygon.objectId);
			//updateAnnotationControlBar(s);
		}
		
		
		private function onPolyUnHighlighted(evt:LMEvent):void
		{
			this._highlightedId = -1
		}
		
		private function onPolyHighlighted(evt:LMEvent):void
		{
			this._highlightedId = evt.selectedId;	
		}
		
		private function onPolySelected(evt:LMEvent):void
		{
			selectAnnotation(evt.selectedId);			
		}
		
		private function drawInitialPolygon():void
		{
			if(_polyStr!="")
			{
				var a:Array = _polyStr.split(",");
				var f:int = int(a[a.length-1]);
				this.skipToFrame(f);
			}
			
		}
		
		private function finishDrawingInitialPolygon():void
		{
			var a:Array = _polyStr.split(",");
			var f:int = int(a[a.length-1]);
			var x:Array = new Array();
			var y:Array = new Array();
			var nPoints:int = (a.length - 1)/2;
			
			for (var i:int =0; i< nPoints; i++)
			{
				
				x.push(Number(a[i])*this._winScaleX);
				y.push(Number(a[i+nPoints])*this._winScaleY);
			}
			var name:String = "";
			var motion:String ="";
			var action:String = "";
			
			if(this._polyFieldStr != "")
			{
				var b:Array = this._polyFieldStr.split(",");
				if(b.length == 3)
				{
					name = b[0];
					if (b[1] == "1")
						motion = "true";
					else
						motion = "false";
					action = b[2];
				}
			}
			
			
			_annotator.drawUnfinishedPolygon(x, y, name, motion, action);
			
			
		}
		
		
		
		private function onEventSelect(evt:LMEventsEvent)
		{
			if(evt && evt._evtItem)
				selectEventAnnotation(evt._evtItem.eid);	
		}
		
		private function selectEventAnnotation(eventId:int):void
		{
			var success:Boolean = selectEvent(eventId);
			if(this._lmEventList && success)
			{
				var list:ExposedList = this._lmEventList.source;
				list.selectedIndex = this._eventDict[String(eventId)];
				list.scrollToIndex(this._eventDict[String(eventId)]);
			}
		}
		
		private function onEventListSelect(evt:ListEvent):void
		{
			var list:ExposedList = evt.target as ExposedList;
			_state = this.transitionState(_state, LMAction.SELECTEVENT);
			if(list.selectedItem)// && _state == State.EVENTSELECTED)
			{
				
				var eventId:int = list.selectedItem.eid;
				
				
				var evtItem:LMEventAnnotationItem = LMEventAnnotationItem(list.selectedItem);
				selectEvent(eventId);
				
				trace("selecting event annotation : " + eventId);
				_listSelected = true;
				
			}
		}
		
		
		
		private function onListSelect(evt:ListEvent):void
		{
			var list:ExposedList = evt.target as ExposedList;
			if(list.selectedItem)
			{
				var objectId:int = list.selectedItem.id;
				
				var startFrame:int = list.selectedItem.startFrame;
				var endFrame:int = list.selectedItem.endFrame;
				if(_currFrame < startFrame || _currFrame >endFrame) 
				{	
					skipToFrame(startFrame);
				}
				else
				{
					var polySprite:LMPolygonSprite = selectAnnotation(objectId);
					if(polySprite)
					{
						showObjectCallout(polySprite);
						trace("selecting annotation : " + objectId);
					}
				}
				_selectedId = objectId;
				_listSelected = true;
				
			}
		}
		
		private function onShowObjectsRequest(evt:LMEvent):void
		{
			_annotator.showObjects();	
		}
		
		private function onHideObjectsRequest(evt:LMEvent):void
		{
			_annotator.hideObjects();
		}
		private function onShowEventsRequest(evt:LMEventsEvent):void
		{
			_annotator.showEvents();
		}
		private function onHideEventsRequest(evt:LMEventsEvent):void
		{
			_annotator.hideEvents();
		}
		
		//event handlers for Events list
		
		private function onAddEventClick(evt:LMEventsEvent):void
		{
			//show event annotator. For now, i'm just setting to visible, but we should reset it
			_state = this.transitionState(_state, LMAction.ANNOTATEEVENT);
			if(State.ANNOTATINGEVENT == _state)
			{
				_annotator.startAnnotatingNewEvent(); //evt._eid, LMEventCallout.TEXTINPUTMODE, int(_annotator.width/2) -400, int(_annotator.height/2));		
			}
			this._evtStartFrame = -1;
			this._evtEndFrame = -1;
			//we have to adjust the slider to a new event
			showEventAnnotationSlider();
			var endFrame:int = VideoLabelMe.time2Frame(this._videoPlayer.totalTime, _videoPlayer.fps);
			this._videoPlayer.setLeftBrightBracketBoundaries(0, endFrame);
			
			this.invalidateDisplayList();
			
		}
		
		private function onSaveNewClick(evt:LMEventsEvent):void
		{		
			//same function called for new and existing objects
			var evId:uint = _lmAnnotation.updateEventAnnotation(evt._evtItem);
			
			_state = this.transitionState(_state, LMAction.FINISHANNOTATINGEVENT);
			enableSave();
		}
		
		
		private function onEventAnnotatorDeleteClick(evt:LMEventsEvent):void
		{
			deleteEventAnnotation(evt._evtItem.eid);
			
		}
		
		private function deleteEventAnnotation(eid:int):void
		{
			if(State.EVENTSELECTED == _state && eid >=0)
			{
				//delete the event in the xml 
				this._lmAnnotation.deleteEvent(eid);	
			}
			_state = this.transitionState(_state, LMAction.FINISHANNOTATINGEVENT);
			enableSave();
			//			closeEventPanel();
			//			this.clearArrows();	
		}
	
		private function checkHighlight(pt:Point):LMPolygonSprite
		{
			var polyS:LMPolygonSprite = _annotator.polyHitTest(pt);
			if(polyS)
			{	
				this._topMenu.polyHit.text = polyS.lMPolygon.objectId.toString();
				polyS.onAnnotationHover(null);
			}
			else
			{	
				this._topMenu.polyHit.text = "";
			}
			return polyS;	
		}
		
		private function showObjectCallout(polySprite:LMPolygonSprite):void
		{
			if(polySprite && polySprite.lMPolygon.objectId != -1)
			{
				var pt:Point = polySprite.getDisplayPoint(0);
				var obj:LMObjectAnnotationItem = _objFrameInfoDict[String(polySprite.lMPolygon.objectId )] as LMObjectAnnotationItem;
				_annotator.displayCallout(polySprite.lMPolygon.objectId, obj.name, obj.moving, obj.action, pt.x, pt.y);	
			}
		}
		
	
		
		private function selectEvent(id:int):Boolean
		{
			if(id == -1 )//|| _lockId !=-1 )
				return false;
			
			_state = this.transitionState(_state, LMAction.SELECTEVENT);
			if(State.EVENTSELECTED == _state)
			{
				this._eventHeldId = id;
				if(_eventHeldId !=-1)
				{
					this._selectedId = -1;
					var evtInfo:LMEventAnnotationItem = this._eventFrameInfoDictionary[String(id)];
					if(evtInfo)
					{	
						_videoPlayer.setLeftBrightBracketBoundaries(evtInfo.startFrame, evtInfo.endFrame);
						showEventAnnotationSlider(evtInfo.createdFrame);
						this.skipToFrame(evtInfo.startFrame);
					}
					else
						showEventAnnotationSlider();
					_annotator.unselectAllEvents();
					if(id !=-1)
					{
						_annotator.selectEvent(evtInfo);
						_selectedEventId = id;
						return true
					}
				}
				return false;
			}
			return false;
			
		}
		
		
		private function selectAnnotation(objectId:int):LMPolygonSprite
		{
			var polySprite:LMPolygonSprite = selectPolygon(objectId);
			if( polySprite && _lmObjList)
			{
				var list:ExposedList = _lmObjList.source as ExposedList;
				list.selectedIndex = this._objDict[String(objectId)];
				list.scrollToIndex(this._objDict[String(objectId)]);
			}
			return polySprite;
		}
		
		private function selectPolygon(id:int):LMPolygonSprite
		{	
			if(id == -1 || _lockId !=-1 )// && id != _lockId)
				return null;
			
			_state = this.transitionState(_state, LMAction.CLICKPOLYGON);
			if(State.POLYSELECTED == _state)
			{
				_heldId = id;
				if(_heldId !=-1)
				{
					
					showAnnotationSlider(_heldId);
					
					var objInfo:LMObjectAnnotationItem = _objFrameInfoDict[String(id)];
					if(objInfo)
						_videoPlayer.setLeftBrightBracketBoundaries(objInfo.startFrame, objInfo.endFrame);
					
					_annotator.unselectAllPolys();
					if(id !=-1)
					{
						var polySprite:LMPolygonSprite = _annotator.selectPolyById(id, onPolySelected, id);
						if(polySprite)
							this._selectedId = id;
						
						return polySprite;
					}
				}
				return null;
			}
			return null;
		}
		
		private function skipToFrame(frameNo:int):void
		{
			_videoPlayer.seek(frameNo);	
		}
		
		
		public function onAnnotatorCanvasClick(evt:MouseEvent):void
		{
			clickOnCanvas(evt.stageX, evt.stageY);	
		}
		
		//assumes the coordinates given are global
		public function clickOnCanvas(x:Number, y:Number):void
		{
			//	if(evt.target != this._annotator._annotCanvas)
			//		return;
			
			_state = this.transitionState(_state, LMAction.CLICKOUT);
			if(State.ANNOTATING == _state)
			{	
				if(_actions == "v")
				{
					
				}
				else if(_annotator.clickOnCanvas(x, y,_heldId))
				{	
					//transition to NOTHING state
				}
				_annotator.invalidateDisplayList();
			}
		}
		
		private function onAnnotationHover(evt:MouseEvent):void
		{
			this._topMenu.xLabel.text = ""  + evt.stageX;
			this._topMenu.yLabel.text = "" + evt.stageY;
			trace("from VideoLabelMe: x : " + evt.localX +"   y :  " +  evt.localY);
		}
		
		private function onAnnotationTranslate(event:LMAnnotationEvent):void
		{
			var sTime:Number = getTimer();
			
			CursorManager.setBusyCursor();
			var sprite:LMPolygonSprite = event.target as LMPolygonSprite;
			
			var points:Array = sprite.getControlPointIds()
			
			//put the changed points in the queue which will be added to the xml when the object is unselected
			this._selectedSprite = sprite;
			for(var i:int = 0; i <sprite.numPoints; i++)
				_modPointIds.push(i);
			
			var eTime:Number = getTimer();
			trace("time taken to annotate : " + String(eTime - sTime) +" ms");
			commitReady();
			CursorManager.removeBusyCursor();
			
		}
		
		private function onAnnnotationSpriteClick(event:LMAnnotationEvent):void
		{
			//we get the global coordinates from the lmannotation event,so no need to transform
			
			if(event.target == this._selectedSprite)
				return;
			
			if(_state == State.NOTHING || _state == State.ANNOTATING || _state == State.POLYSELECTED)
				this.clickOnCanvas(event._anchorX, event._anchorY);	
			
		}
		
		private function onAnnotationScale(event:LMAnnotationEvent):void
		{
			var sprite:LMPolygonSprite = event.target as LMPolygonSprite;
			
			var points:Array = sprite.getControlPointIds()
			CursorManager.setBusyCursor();
			//queue up the points for propagation in xml after the polygon is unselected
			this._selectedSprite = sprite;
			for(var i:int = 0; i <sprite.numPoints; i++)
				_modPointIds.push(i);
			
			commitReady();
			CursorManager.removeBusyCursor();
		}
		
		private function onAnnotateNewFrame(event:LMAnnotationEvent):void
		{
			this.annotateNewFrame(event._id);
			
		}
		
		private function onDeleteObject(event:LMAnnotationEvent):void
		{
			_lmAnnotation.deleteObject(event._id);
			this._selectedId = -1;
			this.hideAnnotationSlider();
			commitReady();
		}
		
		private function onRenameObject(event:LMAnnotationEvent):void
		{
			_lmAnnotation.renameObject(event._id, event._name, event._moving, event._action);	
			commitReady();
			updateObjectList();	
		}
		
		private function onAnnotationPointChange(event:LMAnnotationEvent):void
		{
			//put the changed points in the queue which will be called when the object is unselected
			var id:int = _modPointIds.indexOf(event._id);
			if(id == -1)
				_modPointIds.push(event._id);
			
			trace("pushing " + event._id + " total points: " + this._modPointIds.length)
			
			var sprite:LMPolygonSprite = event.target as LMPolygonSprite;
			if(sprite)
				this._selectedSprite = sprite;		
			
			var sprite:LMPolygonSprite = event.target as LMPolygonSprite;
			
			
			commitReady();
			CursorManager.removeBusyCursor();
			
			
		}
		
		private function onObjListChange(evt:Event):void
		{
			updateObjectList();	
			annotateNewFrame(_currFrame);
		}
		
		private function onEventListChange(evt:LMEvent):void
		{
			this.updateEventList();
			annotateNewFrame(_currFrame);
		}
		
		
		private function onFrameChange(evt:VideoEvent):void
		{
			_currFrame = VideoLabelMe.time2Frame(_videoPlayer.playheadTime, _videoPlayer.fps);
			trace("VLM:current frame : " + _currFrame);
			
			annotateNewFrame(_currFrame);
			if(this._polyStr !="")
			{	
				this.finishDrawingInitialPolygon();
				this._polyStr = "";
			}
			if(State.EVENTSELECTED == _state)
			{
			}
			else if(State.ANNOTATINGEVENT == _state)
			{
			}
			else
				this.resetState();
			
			
		}
		
		private function onEventChangedInAnnotator(evt:LMEventsEvent):void
		{
			if(evt._evtItem)
			{
				var evtItem:LMEventAnnotationItem = evt._evtItem;
				//save the new evtItem
				this._lmAnnotation.updateEventAnnotation(evtItem, true);
				enableSave();
			}
		}
		
		private function annotateNewFrame(frameNo:int):void
		{		
			trace("annotating new frame " + frameNo);
			
			//wait after the ui has been updated and then select the annotation
			_annotator.addEventListener(FlexEvent.UPDATE_COMPLETE, onAnnotatorUpdateComplete);
			
			this.flushOutAnnotationQueue();
			var polygons:Array = _lmAnnotation.getPolygons(frameNo);
			var events:Array = _lmAnnotation.getEvents(frameNo);
			
			_annotator.annotateNewFrame(frameNo, polygons, events);
		}
		
		//commits to xml the annoation of the last polygon that has been annotated
		private function flushOutAnnotationQueue():void
		{
			//flush out the queue of polygons that haven't been propagated
			if(!_flushing)
			{
				_flushing = true;
				if(_selectedSprite && _modPointIds.length>0)
				{
					_lmAnnotation.addPointChangeAnnotation(this._selectedSprite.lMPolygon.objectId, _selectedSprite.lMPolygon, this._modPointIds);
					_selectedSprite = null;
					_modPointIds = new Array();
					trace("saving changes in the xml : " + _modPointIds.length);
				}
				//now flush out events
				
				_flushing = false;
			}	
		}
		
		private function onAnnotatorUpdateComplete(evt:FlexEvent):void
		{
			if(this._selectedId>=0)
			{
				var polySprite:LMPolygonSprite = selectAnnotation(this._selectedId);
				//		trace("selecting annotation : " + polySprite.lMPolygon.objectId);
				
			}
			_annotator.removeEventListener(FlexEvent.UPDATE_COMPLETE, onAnnotatorUpdateComplete);
		}
		
		/////////////////////////callers
		/* lmxmlannotation */
		public function removeComplementFrameAnnotations(objectId:int, startFrame:int, endFrame:int):void
		{
			CursorManager.setBusyCursor();
			_lmAnnotation.removeComplementFrameAnnotations(objectId, startFrame, endFrame);
			commitReady();
			
			//_lmAnnotation.commit();
		}
		
		/* annotator */
		
		
		//annoation cursor
		[Embed(source="assets/cur2052.png")]
		public static const annotationCursor:Class;
		
		//translation cursor
		[Embed(source="assets/cur2038.png")]
		public static const translationCursor:Class;
		
		//rotation cursor
		[Embed(source="assets/cur2032.png")]
		public static const rotationCursor:Class;
		
		
		//other helper functions
		private function transitionState(source:String, action:String):String
		{
			var finalState:String = State.transition(source, action, this._actions);
			if(State.POLYSELECTED == source && State.POLYSELECTED != finalState && _selectedSprite && _modPointIds.length>0)
				this.flushOutAnnotationQueue();
			
			switch(finalState)
			{
				case State.NOTHING:
					hideAnnotationSlider();  		
					this._selectedId =-1;	
					_annotator.unselectAllPolys();
					_annotator.closeAndClearEvent();
					this._topMenu.statusLabel.text = "ready";
					enableSave();
					break;
				
				case State.ANNOTATING:
					this._topMenu.statusLabel.text = "annotating...";
					this._topMenu.disableSave();
					_annotator.unhighlightAllPolys();
					_annotator.closeAndClearEvent();
					break;
				
				case State.POLYSELECTED:
					this._topMenu.statusLabel.text = "polygon selected";
					enableSave();
					_annotator.closeAndClearEvent();
					break;
				
				case State.ANNOTATINGEVENT:
					this._topMenu.disableSave();
					_annotator.unselectAllPolys();
					this._topMenu.statusLabel.text = "annotating event";
					break;
				
				case State.EVENTSELECTED:
					hideAnnotationSlider();
					enableSave();
					_annotator.unselectAllPolys();
					this._topMenu.statusLabel.text = "event selected";
					break;
			}
			return finalState;
		}
		
		private function resetState():void
		{
			_state = State.NOTHING;
			this._topMenu.statusLabel.text = "ready";
			
		}
		
		
		private function makeEventDictionary(list:ArrayCollection):void
		{
			var d:Dictionary = new Dictionary();
			_eventFrameInfoDictionary = new Dictionary();
			for(var i:int = 0 ; i < list.length; i++)
			{
				var key:String = String(list[i].eid);	
				d[key] = i;
				_eventFrameInfoDictionary[key] = list[i];
			}
			this._eventDict = d;
			
			
		}
		
		private function makeObjDictionary(list:ArrayCollection):void
		{
			var d:Dictionary = new Dictionary();
			_objFrameInfoDict = new Dictionary();
			for(var i:int = 0 ; i < list.length; i++)
			{
				var key:String = String(list[i].id);	
				d[key] = i;
				_objFrameInfoDict[key] = list[i];
			}
			_objDict = d;
			
		}
		
		private function enableSave():void
		{
			if(this._spriteState != PolygonSpriteState.VIEWONLY)
				this._topMenu.enableSave();
		}
		
		private function updateObjectList():void
		{
			
			var l:List = _lmObjList.source as List;
			var objData:ArrayCollection = _lmAnnotation.getObjectAnnotations();
			l.dataProvider = objData
			makeObjDictionary(objData);
			this.invalidateSize();
			
		}
		
		private function updateEventList():void
		{
			var l:List = this._lmEventList.source as List;
			var evtData:Dictionary = _lmAnnotation.getEventAnnotations();
			
			//convert the dictionary into an arraycollection
			var a:ArrayCollection = new ArrayCollection();
			//loop through all the objects in the xml file and check for the ones
			// that are in the actual frame
			for each (var event:LMEventAnnotationItem in evtData)
			{
				if(event)
					a.addItem(event);	
			}
			
			makeEventDictionary(a);
			l.dataProvider = a;
			
			this.invalidateSize();
		}
		
		
		/* static functions */
		
		public static function time2Frame(t:Number, fps:Number):int
		{
			return Math.ceil(Number(t) * Number(fps) );
		}
		
		public static function frame2Time(f:int, fps:Number):Number
		{
			return Number(f)/fps;
		}
	}
}

class State
{
	public static var NOTHING:String = "nothing";
	public static var POLYSELECTED:String = "polyselected";
	public static var ANNOTATING:String = "annotating";
	public static var ANNOTATINGEVENT:String = "annotatingevent";
	public static var EVENTSELECTED:String = "eventselected";
	
	public static function transition(source:String, action:String, actionsList:String):String
	{
		//all the transition rules here	
		var finalState:String = null;
		switch(source)
		{
			case State.NOTHING:
				switch(action)
				{
					case LMAction.CLICKOUT:
						finalState = State.ANNOTATING;
						break;
					
					case LMAction.CLICKPOLYGON:
						finalState = State.POLYSELECTED;	
						break;
					
					case LMAction.ANNOTATEEVENT:
						finalState = State.ANNOTATINGEVENT;
						break;
					
					case LMAction.SELECTEVENT:
						finalState = State.EVENTSELECTED;
						
						break;
					
					case LMAction.FINISHANNOTATINGEVENT:
					case LMAction.FINISHPOLYGON:
					default:
						break;
				}	
				break;
			
			case State.POLYSELECTED:
				switch(action)
				{
					case LMAction.CLICKOUT:
						finalState = State.NOTHING;
						break;
					
					case LMAction.CLICKPOLYGON:
						//	if(actionsList !="v")
						finalState = State.POLYSELECTED;
						break;
					
					case LMAction.ANNOTATEEVENT:
						finalState = State.ANNOTATINGEVENT;
						break;
					
					case LMAction.SELECTEVENT:
						finalState = State.EVENTSELECTED;
						
					case LMAction.FINISHANNOTATINGEVENT:
					case LMAction.FINISHPOLYGON:
					default:
						break;
				}	
				break;
			
			case State.EVENTSELECTED:
				switch(action)
				{
					case LMAction.ANNOTATEEVENT:
						finalState = State.ANNOTATINGEVENT;
						break;
					
					case LMAction.CLICKOUT:
						finalState = State.NOTHING;
						break;
					
					case LMAction.CLICKPOLYGON:
						if(actionsList !="v")
							finalState = State.POLYSELECTED;
						break;
					
					case LMAction.SELECTEVENT:
						finalState = State.EVENTSELECTED;
						break;
					
					case LMAction.FINISHANNOTATINGEVENT:
					case LMAction.FINISHPOLYGON:
					default:
						break;
				}
				break;
			
			case State.ANNOTATING:
				switch(action)
				{
					case LMAction.CLICKOUT:
					case LMAction.CLICKPOLYGON:
					case LMAction.ANNOTATEEVENT:
					case LMAction.FINISHANNOTATINGEVENT:
					case LMAction.SELECTEVENT:
						finalState = State.ANNOTATING;
						break;
					
					case LMAction.FINISHPOLYGON:
						finalState = State.NOTHING;
						break;
					
					default:
						break;
				}
				break;
			
			case State.ANNOTATINGEVENT:
				switch(action)
				{
					case LMAction.ANNOTATEEVENT:
					case LMAction.CLICKOUT:
					case LMAction.CLICKPOLYGON:
					case LMAction.FINISHPOLYGON:
					case LMAction.SELECTEVENT:
						finalState = State.ANNOTATINGEVENT;
						break;
					
					case LMAction.FINISHANNOTATINGEVENT:
						finalState = State.NOTHING;
						break;
					
					default:
						break;
				}
				break;
		}
		if(!finalState)
			finalState = State.NOTHING;
		
		
		trace("start state  = " + source +  " transition : " + action + " end state: " + finalState); 
		return finalState;
		//return State.NOTHING;
	}
}

final class LMAction
{
	public static var CLICKOUT:String = "clickout";
	public static var CLICKPOLYGON:String = "clickpolygon";
	public static var FINISHPOLYGON:String = "finishpolygon";
	public static var ANNOTATEEVENT:String = "addevent";
	public static var SELECTEVENT:String = "selectevent";
	public static var FINISHANNOTATINGEVENT:String = "finishannotatingevent";
}
