//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.annotator
{
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.core.ClassFactory;
	import mx.core.SpriteAsset;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import vlm.components.EventDisplay;
	import vlm.components.LMTextFieldCallout;
	import vlm.components.VideoLabelMe;
	import vlm.events.LMEvent;
	import vlm.events.LMEventCalloutEvent;
	import vlm.events.LMEventsEvent;
	import vlm.events.LMAnnotationEvent;
	import vlm.components.LMEventCallout;
	import vlm.core.AnnotationMode;
	import vlm.core.LMEventAnnotationItem;
	import vlm.core.LMPolygon;
	import vlm.core.PolygonSpriteState;
	
	
	public class Annotator extends UIComponent
	{
		
		//videodisplay properties
		private var _totalTime:Number = 100;
		private var _fps:Number = 30;
		
		public var _annotCanvas:Canvas;
		public var _arrowsCanvas:Canvas;
		private var _xLabel:Label;
		private var _yLabel:Label;
		private var _x:Array;
		private var _y:Array;
		private var _nPoints:Number;
		private var _lastColor:uint;
		private var _polygons:Array;
		private var _events:Array;
		private var _eventCallout:LMEventCallout;
		private var _callout:LMTextFieldCallout;
		private var _callOutTextField:TextInput;
		private var _debugLog:TextArea;
		private var _currFrame:int;
		private var _lastFrame:int;
		private var _polySprites:Dictionary;
		private var _eventSprites:Dictionary;
		private var _oId:int;
		private var _polySelected:Boolean;
		private var _createAnnotationEvt:LMAnnotationEvent;
		private var _annotating:Boolean;
		private var _displayId:int;
		private var _selectedId:int;
		private var _spriteState:String;
		private var _displayEvents:Boolean;
		private var _displayObjects:Boolean;
		
		private var _cursorPt:Point;
		
		private var _scaleX:Number;
		private var _scaleY:Number;
		
		private var _polygonEnded:Boolean;
		private var _annotationMode:String;
		
		//variables for event annotator
		private var _startPt:Point;
		private var _tokenSource:int;
		private var _endPt:Point;
		private var _arrows:Array;
		
		private var box:LMEventCallout;
		// variable to keep track of whether the user should be inputting to the callbox
		private var _calloutFocused:Boolean;
		private var _eventCalloutFocused:Boolean;
		
		public static var _colorPicker:ColorPicker;
		
		public function Annotator(spriteState:String, annotationMode:String, polyStr:String="")
		{
			super();
			_annotCanvas = new Canvas();
			_arrowsCanvas = new Canvas();
			_nPoints = 0;
			_polygons = new Array();
			_events = new Array();
			this.startPolygon();
			
			_callout = new LMTextFieldCallout();
			
			_currFrame = -1;
			_lastFrame = -1;
			_polySprites = new Dictionary();
			_eventSprites = new Dictionary();
			_colorPicker = new ColorPicker();
			//videoPlayer information
			_totalTime = -1;
			_fps = -1;
			
			_colorPicker = new ColorPicker();
			_polySelected = false;
			_createAnnotationEvt = null;
			_annotating = true;
			_displayId = -1;
			_selectedId = -1;
			_calloutFocused = false;
			_eventCalloutFocused = false;
			this._spriteState = spriteState;
			_displayEvents = true;
			_displayObjects = true;
			//event annotator parameters
			//this._selectedEvtInfo = new LMEventAnnotationItem(-1, -1, -1, -1, new Dictionary(), new Array());
			_arrows = new Array();
			_annotationMode = annotationMode;
			
			_cursorPt = null;
			_polygonEnded = false;
			
		}
		
		override protected function createChildren():void
		{	
			_annotCanvas.addEventListener(MouseEvent.MOUSE_MOVE, onFirstPointHover);
			
			_eventCallout = new LMEventCallout();
			
			this._eventCallout.visible = false;
			
			this.addChild(_arrowsCanvas);
			
			this.addChild(_annotCanvas);
			this.addChild(_eventCallout);	
			
			_eventCallout.addEventListener(LMEventsEvent.ADDNEWLINK, onAddNewEventLink);
			_eventCallout.addEventListener(LMEventsEvent.SAVENEWEVENTCLICK, onSaveNewEventClick);
			_eventCallout.addEventListener(LMEventsEvent.DELETECLICK, onDeleteEventClick);
			_eventCallout.addEventListener(MouseEvent.CLICK, onEventCalloutClick);
			_arrowsCanvas.addEventListener(MouseEvent.CLICK, onArrowsCanvasClick);
			_eventCallout.addEventListener(FlexEvent.UPDATE_COMPLETE, onTokensRendered);
			_eventCallout.addEventListener(LMEventsEvent.SENTENCERENDERED, onSentenceRendered);
			_eventCallout.addEventListener(LMEventsEvent.CANCELEVENTCREATION, onCancelEventAnnotation);
			_eventCallout.addEventListener(LMEventCalloutEvent.CHANGE, onEventCalloutChange);
			
			_callout.width = 200; _callout.height = 170;      
			this.addChild(_callout);
			this._callout.addEventListener(KeyboardEvent.KEY_DOWN, onCalloutKeyPressed);
			var vb:VBox = _callout.getChildByName("contentVBox") as VBox;
			var hb:HBox = vb.getChildByName("buttonHBox") as HBox;
			var b:Button = hb.getChildByName("doneButton") as Button;
			b.addEventListener(MouseEvent.CLICK, onDoneButtonClick);
			var d:Button = hb.getChildByName("deleteButton") as Button;
			d.addEventListener(MouseEvent.CLICK, onDeleteButtonClick);
			_callOutTextField = vb.getChildByName("textInput") as TextInput;
			_callout.visible = false;
			//_eventCallout.visible= true;
			_callout.addEventListener(MouseEvent.CLICK, onCalloutClick);
			
			if(this._spriteState == PolygonSpriteState.VIEWONLY)
			{
				_callout.actionInput.editable = false;
				_callout.deleteButton.enabled = false;
				_callout.textInput.editable = false;
				_callout.staticType.enabled = false;
				_callout.movingType.enabled = false;
			}
			
		}	
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			_annotCanvas.clipContent = true;
			_annotCanvas.horizontalScrollPolicy = "off";
			_annotCanvas.verticalScrollPolicy ="off";
		}
		
		private function getTokenLinkCoordinates(evtItem:LMEventAnnotationItem):Dictionary
		{
			var tokenLinkCoordinates:Dictionary = new Dictionary()
			for (var key in evtItem.tokenLinks)
			{
				var tokenLink:ArrayCollection = evtItem.tokenLinks[key];
				if(tokenLink && tokenLink.length>0)
				{	
					//these are the ids that token[i] is linked to
					var objectsIds:ArrayCollection = ArrayCollection(tokenLink);
					var destinationPoints:ArrayCollection = new ArrayCollection();
					for (var i:int = 0; i < tokenLink.length; i++)
					{
						var objectId:int = int(tokenLink[i]);
						//now find the coordinates for the object in this frame
						var dstPt:Point = getPolySCoordinates(objectId);
						
						if(dstPt)
						{	
							dstPt = _annotCanvas.globalToLocal(dstPt);
							destinationPoints.addItem(dstPt);
						}
					}
					tokenLinkCoordinates[key] = destinationPoints;
				}
			}
			return tokenLinkCoordinates;
		}
		/**
		 * Sizes and positions the children of the component on the screen based on 
		 * all previous property and style settings, and draws any skins or graphic 
		 * elements used by the component. The parent container for the component 
		 * determines the size of the component itself.
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			_eventCallout.setActualSize(_eventCallout.measuredWidth, _eventCallout.measuredHeight);
			_annotCanvas.setActualSize(unscaledWidth,unscaledHeight);
			_arrowsCanvas.setActualSize(unscaledWidth, unscaledHeight);
			this.setActualSize(unscaledWidth, unscaledHeight);
			_annotCanvas.graphics.clear();	
			
			trace("on annotator updatedisplaylist");
			
			var pSsInFrame:Dictionary;
			pSsInFrame = new Dictionary();
			if(_displayObjects)
			{
				//	_arrowsCanvas.graphics.clear();
				
				for each(var p:LMPolygon in _polygons)
				{
					//if the object is already in the screen, update its location
					var pS:LMPolygonSprite = _polySprites[p.objectId];
					
					if(pS)
					{
						pS.lMPolygon = p;
						p.polySprite = pS;
						pS.draw(_scaleX, _scaleY);   				
					}
					else{
						
						pS = p.draw(_scaleX, _scaleY);
						pS.draw(_scaleX, _scaleY);
						pS.lMPolygon = p;
						_annotCanvas.addChild(pS);					
						_polySprites[pS.lMPolygon.objectId] = pS;
					}
					pSsInFrame[p.objectId] = true;
				}	
			}
			//now remove all the sprites that are notin the _polygons list
			for each(var s:LMPolygonSprite in _polySprites)
			{
				
				if(pSsInFrame[s.lMPolygon.objectId]== null || !_displayObjects)
				{
					if(s.parent == _annotCanvas)
						_annotCanvas.removeChild(s);
					delete _polySprites[s.lMPolygon.objectId];
				}
			}
			
			//draw last polygon
			_annotCanvas.graphics.lineStyle(5, _lastColor);
			
			
			for(var i:int = 0; i < _nPoints ; i++)
			{ 
				_annotCanvas.graphics.lineStyle(4, _lastColor);
				
				if(i == 0)
					_annotCanvas.graphics.moveTo(_x[i], _y[i]);
				else
					_annotCanvas.graphics.lineTo(_x[i], _y[i]); 
			}
			
			if(_nPoints>1 && this._polygonEnded )
			{
				_annotCanvas.graphics.lineTo(_x[0], _y[0]);	
			}
			
			
			trace("annotator: nPoints: "+ _nPoints);
			if(_nPoints >0 && _cursorPt && !this._polygonEnded)
			{
				_annotCanvas.graphics.lineStyle(4, _lastColor, 1);
				_annotCanvas.graphics.moveTo(_x[this._nPoints-1], _y[this._nPoints-1]);
				_annotCanvas.graphics.lineTo(_cursorPt.x, _cursorPt.y);
				
				if(this._annotationMode == AnnotationMode.BOX)
				{
					var newX:Array = new Array();
					var newY:Array = new Array();
					newX[0] = _x[0];
					newY[0] = _y[0];
					newX[1] = _x[0];
					if(_nPoints == 1)
					{
						newY[1] = _cursorPt.y;
						newX[2] = _cursorPt.x;
						newY[2] = _cursorPt.y;
						newX[3] = _cursorPt.x;
					}
					else
					{
						newY[1] = _y[1];
						newX[2] = _x[1];
						newY[2] = _y[1];
						newX[3] = _x[1];
						
					}
					newY[3] = _y[0];
					newX[4] = _x[0];
					newY[4] = _y[0];
					for(var i:int = 0; i < 5 ; i++)
					{ 
						_annotCanvas.graphics.lineStyle(2, _lastColor);
						
						if(i == 0)
							_annotCanvas.graphics.moveTo(newX[i], newY[i]);
						else
							_annotCanvas.graphics.lineTo(newX[i], newY[i]); 
					}
					
				}
			}
			
			for(var i:int = 0; i < _nPoints; i++)
			{
				//draw the first circle in red and bigger
				if(i == 0)
				{
					_annotCanvas.graphics.lineStyle(5, VLMParams.white);
					_annotCanvas.graphics.beginFill(VLMParams.white);
					_annotCanvas.graphics.drawCircle(_x[i], _y[i], 5);
					_annotCanvas.graphics.endFill();
					
					_annotCanvas.graphics.lineStyle(4, VLMParams.darkPink);
					_annotCanvas.graphics.beginFill(VLMParams.darkPink);
					_annotCanvas.graphics.drawCircle(_x[i], _y[i], 3);
					
				}
				_annotCanvas.graphics.endFill();
			}
			
			
			var evtInfo:LMEventAnnotationItem = _eventCallout._evtItem;
			if(_displayEvents)
			{
				//draw each of the events that already exist
				
				var eSsInFrame:Dictionary;
				eSsInFrame = new Dictionary();
				
				for each(var evtItem:LMEventAnnotationItem in _events)
				{
					//if the object is already in the screen, update its location
					var eS:EventDisplay = _eventSprites[evtItem.eid];
					if(evtItem.eid!=-1 && _eventCallout._evtItem && evtItem.eid == _eventCallout._evtItem.eid)
						continue;
					
					if(eS)
					{
						//update the location
						if(!isNaN(evtItem.x) &&evtItem.x>=0) 
							eS.x = evtItem.x * this._scaleX;
						
						if(!isNaN(evtItem.y) && evtItem.y>=0)
							eS.y = evtItem.y * this._scaleY;	
						eS._tokenLinkCoordinates = getTokenLinkCoordinates(evtItem);
						eS.setScale(this._scaleX, this._scaleY);
						eS.draw();
					}
					else
					{
						eS = new EventDisplay();
						eS.evtItem = evtItem;
						//create a dictionary with the links to the coordinates where we should draw the arrows
						
						eS._tokenLinkCoordinates = getTokenLinkCoordinates(evtItem);						 
						eS.x = int(evtItem.x * this._scaleX);
						eS.y = int(evtItem.y * this._scaleY);						 
						eS.setScale(this._scaleX, this._scaleY);
						_annotCanvas.addChild(eS);
						_eventSprites[evtItem.eid] = eS;
						eS.draw();
						
					}
					eSsInFrame[eS.evtItem.eid] = true;
				}	
				
				//now remove all the sprites that are notin the _polygons list
				for each(var eD:EventDisplay in _eventSprites)
				{
					if(eSsInFrame[eD.evtItem.eid]== null)
					{
						if(eD.parent == _annotCanvas)
							_annotCanvas.removeChild(eD);
						delete _eventSprites[eD.evtItem.eid];
					}
				}
				
			}
			
			//draw event arrows for the selected event
			if(evtInfo && evtInfo.tokens.length>0)
			{
				if(evtInfo.x >=0)
				{
					_eventCallout.x = int(evtInfo.x* this._scaleX);
					_eventCallout.y = int(evtInfo.y* this._scaleY);
				}
				else//place in the center
				{
					_eventCallout.x = 0;//this.width/2 - _eventCallout.width/2;
					_eventCallout.y = 0;//this.height/2 - _eventCallout.height/2;
				}
				
				var tokenId:int = 0;
				for each (var tokenLink:ArrayCollection in evtInfo.tokenLinks)	
				{
					if(tokenLink && tokenLink.length>0)
					{	
						//these are the ids that token[i] is linked to
						var objectsIds:ArrayCollection = ArrayCollection(tokenLink);
						//now we need to find the coordinates for the button source and the object sink
						var srcPt:Point;
						srcPt = this._eventCallout.getCoordinates(tokenId);
						
						if(srcPt)
						{	srcPt = _annotCanvas.globalToLocal(srcPt);
							
							for (var i:int = 0; i < tokenLink.length; i++)
							{
								var objectId:int = int(tokenLink[i]);
								//now find the coordinates for the object in this frame
								var dstPt:Point = getPolySCoordinates(objectId);
								
								if(dstPt)
								{	
									dstPt = _annotCanvas.globalToLocal(dstPt);
									
									_annotCanvas.graphics.lineStyle(12, VLMParams.white,1);
									_annotCanvas.graphics.moveTo(srcPt.x, srcPt.y);
									_annotCanvas.graphics.lineTo(dstPt.x, dstPt.y);
									//draw the second layer of the arrow
									_annotCanvas.graphics.lineStyle(10, VLMParams.darkPink,1);
									_annotCanvas.graphics.moveTo(srcPt.x, srcPt.y);
									_annotCanvas.graphics.lineTo(dstPt.x, dstPt.y);
									
								}
							}
						}
					}
					tokenId ++;
				}
			}
			
		}
		
		public function undo():Boolean
		{
			if(_nPoints >1)
			{
				_nPoints--;
				_x.pop();
				_y.pop();
				this.invalidateDisplayList();
				return true;
			}
			else if(_nPoints == 1)
			{
				_nPoints--;
				_x.pop();
				_y.pop();
				this.invalidateDisplayList();
				return false;
			}
			return false;
		}
		
		public function setTimeInfo(totalTime:Number, fps:Number):void
		{
			_totalTime = totalTime;
			_fps = fps;	
		}
		
		public function set debugLog(dl:TextArea):void
		{
			_debugLog = dl;
		}
		
		public function setObjectId(id:int):void
		{	
			//set by external source when object is created
			_oId = id;
		}
		
		public function setScale(scaleX:Number, scaleY:Number):void
		{
			_scaleX = scaleX;
			_scaleY = scaleY;
			_eventCallout.setScale(_scaleX, _scaleY);
			//			this._eventCallout._scaleX = _scaleX;
			//			this._eventCallout._scaleY = _scaleY;
			this.invalidateDisplayList();
		}
		
		public function hideEventCallout():void
		{
			
		}
		
		private function shapeEventCallout(x:int, y:int):void
		{
			//	_eventCallout.x = x ;//- _eventCallout.width;
			//	_eventCallout.y = y ;//- _eventCallout.height;
		}
		
		public function startAnnotatingNewEvent():void
		{
			this._eventCalloutFocused = true;
			
			_eventCallout.x = 10;
			_eventCallout.y = 10;
			_eventCallout.visible = true;
			_eventCallout.changeDisplayMode(LMEventCallout.TEXTINPUTMODE);	
			var endFrame:int = VideoLabelMe.time2Frame(_totalTime, _fps); //we are substracting -2 instead of -1 because ffmpeg is not producing the correct number of frames out
			endFrame = endFrame >=0 ? endFrame : 0;
			
			_eventCallout.reset(0, endFrame);
		}
		
		private function onEventCalloutChange(evt:LMEventCalloutEvent):void
		{
			//check the state of the event callout.
			switch(this._eventCallout._mode)
			{
				case LMEventCallout.EDITABLELINKERMODE:
					
				case LMEventCallout.READONLYLINKERMODE:
					
				case LMEventCallout.TEXTINPUTMODE:
					
			}
		}
		
		private function onCancelEventAnnotation(evt:LMEventsEvent):void
		{
			this.closeAndClearEvent();
		}
		
		public function drawUnfinishedPolygon(x:Array, y:Array, name:String, motion:String, action:String):void
		{
			_x = x;
			_y = y;		
			_nPoints = x.length;
			
			
			this.displayCallout(-1, name, motion, action, x[0], y[0]);
			_annotating = false;
			this.endPolygon();	
			this._polygonEnded = true;	
			//	this.invalidateDisplayList();
		}			
		
		public function displayCallout(objectId:int, name:String, motion:String, action:String, x:int, y:int):void
		{
			_displayId = objectId;
			_callout.textInput.text = name;
			if(!motion || motion == "")
			{
				_callout.staticType.selected = false;
				_callout.movingType.selected = false;
				
			}
			else if(motion == "false")
			{
				_callout.staticType.selected = true;
				_callout.movingType.selected = false;
			}
			else
			{	
				_callout.staticType.selected = false;
				_callout.movingType.selected = true;
			}
			_callout.actionInput.text = action;
			_callout.visible = true;
			
			if(x + _callout.width >this.width)
			{	
				if(y - _callout.height <=0 ) 
				{
					_callout.setStyle("borderStyle", "bottomLeftCallout");
					_callout.x = x - _callout.width;
					_callout.y = y;
				}
				else
				{
					_callout.setStyle("borderStyle", "topLeftCallout");
					_callout.x = x - _callout.width;
					_callout.y = y - _callout.height;
				}
			}
				
			else
			{
				if(y - _callout.height <=0 ) 
				{
					_callout.setStyle("borderStyle", "bottomRightCallout");
					_callout.x = x;
					_callout.y = y;
				}
				else
				{
					_callout.setStyle("borderStyle", "topRightCallout");
					_callout.x  = x;
					_callout.y = y - _callout.height;
				}
				
			}
			_callout.textInput.setFocus();
			_callout.setStartCoords(x, y);
			this._calloutFocused = true;
		}
		
		public function resetCallout():void
		{
			_callout.textInput.text = "";
			_callout.staticType.selected = true;
			_callout.movingType.selected = false;
			_callout.actionInput.text = "";
		}
		
		
		
		private function onCalloutClick(event:MouseEvent):void
		{
			event.stopPropagation();
		}
		
		private function onArrowsCanvasClick(evt:MouseEvent):void
		{
			trace("arrows canvas clicked");
		}
		private function onEventCalloutClick(evt:MouseEvent):void
		{
			evt.stopPropagation();		
		}
		
		
		
		private function resetAndHideCallout():void
		{
			this.resetCallout();
			_callout.visible = false;	
			this._calloutFocused = false;
		}
		
		private function onDoneButtonClick(event:MouseEvent):void
		{
			
			if(event)	
				event.stopPropagation();
			
			var objName:String = _callOutTextField.text;
			var motionType:String = "";
			if(this._callout.staticType.selected)
				motionType = "false";
			else if(this._callout.movingType.selected)
				motionType = "true";
			
			var actionDescription:String = this._callout.actionInput.text;
			
			this.resetAndHideCallout();
			this.invalidateDisplayList();
			
			if(_createAnnotationEvt)
			{
				_createAnnotationEvt._name = objName;
				_createAnnotationEvt._moving = motionType;
				_createAnnotationEvt._action = actionDescription;
				
				_createAnnotationEvt._createdFrame = this._currFrame;
				dispatchEvent(this._createAnnotationEvt);
				_createAnnotationEvt = null;
			}
			else
			{
				var renameEvent:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.RENAMEOBJECT);
				renameEvent._id = this._displayId;
				renameEvent._name = objName;
				renameEvent._moving = motionType;
				renameEvent._action = actionDescription;
				dispatchEvent(renameEvent);
				
			}
			var evt:LMEvent = new LMEvent(LMEvent.LISTCHANGE, true, true);
			this.dispatchEvent(evt);
			this.startPolygon();
			_annotating = true;
			
		}
		
		private function onDeleteButtonClick(event:MouseEvent):void
		{	
			if(_annotating)
			{
				deleteAnnotation(this._displayId);
				resetCallout();
			}	
			else
			{
				
				this.startPolygon();
				if(event)
					event.stopPropagation();
				//_polygons.pop();
				this.invalidateDisplayList();
				_annotating = true;
				var e:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.CANCELANNOTATIONCREATION);
				dispatchEvent(e);
			}
			this.resetAndHideCallout();
		}
		
		public function unhighlightAllPolys():void
		{
			for each (var poly:LMPolygonSprite in _polySprites)
			{
				poly.unhighlight();
			}
		}
		
		
		public function unselectAllPolys():void
		{
			this.resetAndHideCallout();
			
			for each (var poly:LMPolygonSprite in _polySprites)
			{
				poly.unselect();
			}
		}
		
		public function unselectAllEvents():void
		{
			this.resetAndHideCallout();
			//todo finish implementing me
		}
		
		private function requestAnnotateNewFrame(frameNo:Number):void
		{
			var e:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.ANNOTATENEWFRAME, true, false, frameNo);
			dispatchEvent(e);
		}
		
		private function requestDeleteObject(id:Number):void
		{
			var e:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.DELETEOBJECTANNOTATION, true, false,id);
			dispatchEvent(e);
		}
		
		public function frameUpdated(frame:Number):void
		{
			this._currFrame = frame;
		}
		
		public function annotateNewFrame(frameNo:Number, polygons:Array, events:Array, selectedId:int=-1):void 
		{
			_lastFrame = _currFrame;
			_currFrame = frameNo;
			_polygons = polygons;
			_events = events;
			
			
			/*if(_eventCallout && _eventCallout._evtItem && _eventCallout._evtItem.tokenLinks)
			initializeArrows();
			*/
			//hide the callout
			//	this._callout.visible = false;
			//trace("annotating new frame " + _currFrame + " with " + polygons.length +" polygons");
			//	this.startPolygon();
			this.invalidateDisplayList();
			//this.resetCallout();
			this._selectedId = selectedId;
			
			
		}
		
		public function selectPoly(polyS:LMPolygonSprite, onClickFn:Function, heldId:int):void
		{
			if(heldId ==-1)
				return;
			if(polyS)
			{
				//unselect all the other sprites
				unselectAllPolys();
				this.unhighlightAllPolys();
				//select this sprite 
				polyS.select(onClickFn);
			}
		}
		
		public function selectEvent(evtInfo:LMEventAnnotationItem):void
		{
			if(evtInfo)
			{
				this.clearArrows();
				//show the display thing
				_eventCallout.visible = true;
				_eventCallout._evtItem = evtInfo;
				_eventCallout.changeDisplayMode(LMEventCallout.EDITABLELINKERMODE);	
				_eventCallout.resetLinkerWithEvtItem(evtInfo);
				invalidateDisplayList();
			}
		}
		
		public function getPolySCoordinates(objectId:int):Point
		{
			//check if the polygon exists first
			if(_polySprites[objectId])
			{
				var polyS:LMPolygonSprite = LMPolygonSprite(_polySprites[objectId]);
				var pt:Point = polyS.getDisplayPoint(0);
				return this.localToGlobal(pt);
			}
			return null;
		}
		
		public function selectPolyById(id:int, onClickFn:Function, heldId:int):LMPolygonSprite
		{
			if(heldId ==-1)
				return null;
			selectPoly(_polySprites[id], onClickFn, heldId); 	
			return _polySprites[id];
		}
		
		public function highlightPolyById(id:int):Boolean
		{
			var polyS:LMPolygonSprite = _polySprites[id];	
			if(polyS)
			{
				//unselect all the other sprites
				this.unhighlightAllPolys();
				//select this sprite 
				polyS.highlight();
				return true;
			}
			return false;
		}
		
		public function unhighlightPoly(id:int):Boolean
		{
			var polyS:LMPolygonSprite = _polySprites[id];	
			if(polyS)
			{
				//unselect all the other sprites
				polyS.unhighlight();
				return true;
			}
			return false;
		}
		
		public function hideEvents():void
		{
			if(_displayEvents)
			{
				_displayEvents = false;
				//now remove all the sprites that are notin the _polygons list
				for each(var eD:EventDisplay in _eventSprites)
				{
					
					if(eD.parent == _annotCanvas)
						_annotCanvas.removeChild(eD);
					delete _eventSprites[eD.evtItem.eid];
					
				}
				invalidateDisplayList();
			}		
		}
		
		public function showObjects():void
		{
			if (!_displayObjects)
			{
				_displayObjects = true;
				this.invalidateDisplayList();
			}
		}
		
		public function hideObjects():void
		{
			if(_displayObjects)
			{
				_displayObjects = false;
				//now remove all the sprites that are notin the _polygons list
				for each(var pS:LMPolygonSprite in this._polySprites)
				{
					if(pS.parent == _annotCanvas)
						_annotCanvas.removeChild(pS);
					delete _polySprites[pS.lMPolygon.objectId];
					
				}
				invalidateDisplayList();
			}		
		}	
		
		public function showEvents():void
		{
			if(!_displayEvents)
			{
				_displayEvents = true;
				this.invalidateDisplayList();
			}
		}
		
		
		public function clickOnCanvas(xVal:int, yVal:int, heldId:int):Boolean
		{
			if(this._calloutFocused)
				return false;
			if(this._eventCalloutFocused)
				return false;
			
			unselectAllPolys();
			if(!_annotating) 
				return false;
			//we assume all our inputs are stage coordinates 
			var globalPt:Point = new Point(xVal, yVal);
			var localPt:Point = _annotCanvas.globalToLocal(globalPt);
			
			xVal = localPt.x; yVal = localPt.y;
			trace(_nPoints + ": x : " + xVal + " y :" + yVal);
			if(this._annotationMode == AnnotationMode.POLYGON)		
			{
				if(_nPoints >0 && Math.sqrt((xVal - _x[0]) * (xVal - _x[0]) + (yVal - _y[0])  * (yVal - _y[0])) <5)
				{
					_annotCanvas.graphics.drawCircle(_x[0], _y[0], 10);
					
					this.resetCallout();
					_callout.x  = xVal;
					_callout.y = yVal - _callout.height;
					this.displayCallout(-1, "", "", "", xVal, yVal);
					_annotating = false;
					this.endPolygon();	
					this._polygonEnded = true;
					//trace("Annotator: canvas click to close")
					return true;
				}
				else
				{
					//	Alert.show(String(event.localX) + String(event.localY));
					_x[_nPoints] = xVal;
					_y[_nPoints] = yVal;		
					_nPoints ++;
					_callout.visible = false;
					this._polygonEnded = false;
					//trace("Annotator: annotated new point");
					return  false;
				}
			}
			else if(this._annotationMode == AnnotationMode.BOX)
			{
				//only two cases, if it's the first point or the second one
				if(_nPoints == 0)
				{
					_x[_nPoints] = xVal;
					_y[_nPoints] = yVal;
					_nPoints++;
					this._polygonEnded = false;
					
					return false;
					
				}
				else if(_nPoints == 1)
				{
					_x[_nPoints] = xVal;
					_y[_nPoints] = yVal;		
					this.displayCallout(-1, "", "", "", xVal, yVal);
					this.endPolygon();
					this._polygonEnded = true;
					_annotating = false;
					return true;
				}
				else{
					Alert.show("error, number of points should not exceed 1");
				}
			}
			else
			{
				Alert.show("Error, mode unknown" + this._annotationMode);
			}
			
			
			this.invalidateDisplayList();
			return false;
		}
		
		private function onCalloutKeyPressed(evt:KeyboardEvent):void
		{
			switch(evt.keyCode) 
			{
				
				case Keyboard.ENTER:
					this.onDoneButtonClick(null);
					break;
				
				default:
					break;
			}
		}
		
		private function onFirstPointHover(event:MouseEvent):void
		{
			var globalPt:Point = new Point(event.stageX, event.stageY);
			this._cursorPt  = _annotCanvas.globalToLocal(globalPt);
			
			trace("moved on canvas... " + event.stageX + " " + event.stageY);
			//	if(_nPoints <=1)
			//		return;
			
			
			
			if(Math.sqrt((event.localX - _x[0]) * (event.localX - _x[0]) + (event.localY - _y[0])  * (event.localY - _y[0])) <5)
			{
				//draw outside color in white
				_annotCanvas.graphics.beginFill(VLMParams.white);
				_annotCanvas.graphics.lineStyle(7, VLMParams.white, 1);
				_annotCanvas.graphics.drawCircle(_x[0], _y[0], 7);	
				_annotCanvas.graphics.lineStyle(7, _lastColor, 1);
				_annotCanvas.graphics.endFill();
				
				//draw inside circle in color
				_annotCanvas.graphics.beginFill(_lastColor);
				_annotCanvas.graphics.drawCircle(_x[0], _y[0], 4);	
				_annotCanvas.graphics.endFill();
			}
			else
			{
				this.invalidateDisplayList();
			}
			
		}
		
		
		private function startPolygon():void
		{
			//			trace("Annotator: starting new polygon");
			_lastColor = getRandomColor();
			_nPoints = 0;
			_x = new Array();
			_y = new Array();
			_createAnnotationEvt = null;
		}
		
		private function endPolygon():void
		{
			var annot:LMPolygon = new LMPolygon();
			var labels:Array = new Array(_x.length);
			
			var startFrame:int = 0;
			
			var endFrame:int = VideoLabelMe.time2Frame(_totalTime, _fps); //we are substracting -2 instead of -1 because ffmpeg is not producing the correct number of frames out
			endFrame = endFrame >=0 ? endFrame : 0;
			
			
			if(this._annotationMode == AnnotationMode.BOX)
			{
				//draw the 4 corners
				var _newX:Array = new Array();
				var _newY:Array = new Array();
				_newX[0] = _x[0];
				_newY[0] = _y[0];
				_newX[1] = _x[0];
				_newY[1] = _y[1];
				_newX[2] = _x[1];
				_newY[2] = _y[1];
				_newX[3] = _x[1];
				_newY[3] = _y[0];
				_x = _newX;
				_y = _newY;
				_nPoints = 4;
			}
			
			
			annot.initializePoints(_x, _y, _lastColor, _currFrame, 1, this._scaleX, this._scaleY, this._spriteState);
			
			_createAnnotationEvt = new LMAnnotationEvent(LMAnnotationEvent.CREATEOBJECT,true,false,-1
				, annot, startFrame, endFrame,"", this._currFrame);
			
			//			trace("Annotator: ending polygon");													 
		}	
		
		public function setScaleX(s:Number):void{
			this._scaleX = s;
		}
		
		public function setScaleY(s:Number):void{
			this._scaleY = s;
		}
		
		public function deleteAnnotation(id:int):void
		{
			requestDeleteObject(id);
			requestAnnotateNewFrame(_currFrame);
			
			var evt:LMEvent = new LMEvent(LMEvent.LISTCHANGE, true, true);
			this.dispatchEvent(evt);
		}
		
		//checks if a point hit any of the polygons displayed currently
		public function polyHitTest(pt:Point):LMPolygonSprite
		{
			for each (var polyS:LMPolygonSprite in this._polySprites)
			{
				if(polyS.polySpriteHitTest(pt))
					return polyS;
			}
			return null;
		}
		
		public function updateEventFrames(startFrame:int, endFrame:int):void
		{
			this._eventCallout._evtItem.startFrame = startFrame;
			this._eventCallout._evtItem.endFrame = endFrame;
		}
		
		
		private function onSaveNewEventClick(evt:LMEventsEvent):void
		{
			//no need to redispatch, the same event should be bubbling up to videolabelme
			this.closeAndClearEvent();
		}
		
		private function onDeleteEventClick(evt:LMEventsEvent):void
		{
			//we don't have to dispatch the delete event again because	 it will bubble up anyway			
			this.closeAndClearEvent();
			
		}
		
		public function closeAndClearEvent():void
		{
			if(this._eventCallout.visible == true)
			{
				this._eventCallout.visible = false;
				var endFrame:int = VideoLabelMe.time2Frame(_totalTime, _fps); //we are substracting -2 instead of -1 because ffmpeg is not producing the correct number of frames out
				endFrame = endFrame >=0 ? endFrame : 0;
				
				_eventCallout.reset(0, endFrame);
				this.clearArrows();	
				_annotCanvas.removeEventListener(MouseEvent.MOUSE_MOVE, onArrowUpdate);
				_annotCanvas.removeEventListener(LMEvent.POLYSELECTED, onPolySelected);
				this._eventCalloutFocused = false;
				this.invalidateDisplayList();
			}
		}
		
		private function clearArrows():void
		{
			//	this._arrowsCanvas.graphics.clear();
			var a:UIComponent = _arrows.pop();
			while(a)
			{
				this._annotCanvas.removeChild(a);
				a = _arrows.pop();	
			}
			this._arrowsCanvas.graphics.clear();
			//invalidateDisplayList();
		}
		
		private function onSentenceRendered(evt:LMEventsEvent):void
		{
			//now show arrows 
			this.invalidateDisplayList();
		}
		//when adding a new link from the event annotation box
		// part of a group of functions to draw an arrow
		// Step 1: lock down the beginning 
		
		private function onAddNewEventLink(evt:LMEventsEvent):void
		{
			var pt:Point = new Point(evt._stageStartX, evt._stageStartY);
			this._startPt = _annotCanvas.globalToLocal(pt);
			evt.stopPropagation();
			this._tokenSource = evt._tokenIdx;
			_eventCallout._evtItem.createdFrame = this._currFrame;
			_annotCanvas.addEventListener(MouseEvent.MOUSE_MOVE, onArrowUpdate);
			//_arrowsCanvas.addEventListener(MouseEvent.MOUSE_MOVE, onArrowUpdate);
			
			//this.setChildIndex(_arrowsCanvas, this.numChildren -1);
			//this won't end up being on click... it will have to be on a hover of the annotator
			_annotCanvas.addEventListener(LMEvent.POLYSELECTED, onPolySelected);
			
		}
		
		//Step 2: update the arrow based on the position of the mouse
		private function onArrowUpdate(evt:MouseEvent):void
		{
			updateMouseTipArrow(evt.stageX, evt.stageY);
			
			var pt:Point = new Point(evt.stageX, evt.stageY)
		}
		
		//Step 3: Save the annotation of the arrow
		
		private function onPolySelected(evt:LMEvent):void
		{
			evt.stopPropagation();	
			//this.setChildIndex(this._eventCallout, this.numChildren-1);
			this._arrowsCanvas.graphics.clear();
			//updateMouseTipArrow(evt.stageX, evt.stageY);
			var polyS:LMPolygonSprite = LMPolygonSprite(evt.target); //checkHighlight(new Point(evt.stageX, evt.stageY));
			if(polyS)
			{
				_annotCanvas.removeEventListener(MouseEvent.MOUSE_MOVE, onArrowUpdate);
				_annotCanvas.removeEventListener(LMEvent.POLYSELECTED, onPolySelected);
				//	_annotCanvas.graphics.clear();
				//add a new link to the dictionary
				
				if(_eventCallout._evtItem.tokenLinks[_tokenSource])
				{
					var ids:ArrayCollection = ArrayCollection(_eventCallout._evtItem.tokenLinks[_tokenSource]);
					ids.addItem(evt.selectedId);
					_eventCallout._evtItem.tokenLinks[_tokenSource] = ids;
				}
				else
				{
					var a:ArrayCollection = new ArrayCollection();
					a.addItem(evt.selectedId);
					_eventCallout._evtItem.tokenLinks[_tokenSource] = a;
				}
			}
			
			//now tell videolabelme that we added a link to the event. this will update the start and end frames
			var e:LMEventsEvent = new LMEventsEvent(LMEventsEvent.ADDNEWLINK, true, true);
			e._objectId = evt.selectedId;
			dispatchEvent(e)
			this.invalidateDisplayList();				
			
		}
		
		
		private function onTokensRendered(evt:FlexEvent):void
		{
			invalidateDisplayList();
			this._eventCallout.tokensTile.removeEventListener(FlexEvent.UPDATE_COMPLETE, onTokensRendered);
		}
		
		
		//draw the arrow in the maincanvas
		private function updateMouseTipArrow(stageX:int, stageY:int):void
		{
			var pt:Point = new Point(stageX, stageY);
			_endPt = _annotCanvas.globalToLocal(pt);
			
			_arrowsCanvas.graphics.clear();
			//draw the queued arrows 
			//draw the latest one stuck to the mouse
			
			_arrowsCanvas.graphics.lineStyle(12, VLMParams.white,1);
			_arrowsCanvas.graphics.moveTo(_startPt.x, _startPt.y);
			_arrowsCanvas.graphics.lineTo(_endPt.x, _endPt.y);
			//draw the second layer of the arrow
			_arrowsCanvas.graphics.lineStyle(10, VLMParams.green,1);
			_arrowsCanvas.graphics.moveTo(_startPt.x, _startPt.y);
			_arrowsCanvas.graphics.lineTo(_endPt.x, _endPt.y);
			trace("updating arrow to "+ _endPt.x + " , " + _endPt.y); 
			
		}
		
		public static function getRandomColor():uint
		{
			var redBias:Number = 0xFF*Math.random();
			var greenBias:Number = 0xFF*Math.random();
			var blueBias:Number = 0xFF*Math.random();
			
			var m:Number = Math.max(redBias, greenBias, blueBias);
			
			var ct:ColorTransform = new ColorTransform(1,1,1,1,0xFF*redBias/m,0xFF*greenBias/m,0xFF*blueBias/m);
			
			return ct.color;
		}
		
		public static function getRandomYellowishColor():uint
		{
			var redBias:Number = 0xFF*Math.random(); 
			var greenBias:Number = redBias/2 + 0xFF*Math.random() * -1^Math.random();
			var blueBias:Number = 0;
			
			
			var m:Number = Math.max(redBias, greenBias, blueBias);
			
			var ct:ColorTransform = new ColorTransform(1,1,1,1,0xFF*redBias/m,0xFF*greenBias/m,0xFF*blueBias/m);
			
			return ct.color;
		}
		
	}
}

import flash.utils.Dictionary;
import vlm.components.annotator.Annotator;

class ColorPicker
{
	private var _colors:Dictionary;
	
	public function ColorPicker()
	{	
		_colors = new Dictionary;		
	}		
	
	public function getColor(id:int):uint
	{
		if(!_colors[id])
		{
			_colors[id] = Annotator.getRandomColor();	
		}
		return _colors[id];
	}
}
