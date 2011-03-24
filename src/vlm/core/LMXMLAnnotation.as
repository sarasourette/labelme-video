//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.core
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.xml.XMLNode;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.mxml.HTTPService;
	
	import vlm.events.LMEvent;
	import vlm.events.LMXMLEvent;
	import vlm.events.LMAnnotationEvent;
	import vlm.components.annotator.Annotator;
	
	//	import org.osmf.layout.AbsoluteLayoutFacet;
	
	
	[RemoteClass(alias="LMAnnotator.LMXMLAnnotation")]
	
	public class LMXMLAnnotation extends EventDispatcher implements IExternalizable
	{
		private var _annotation:XML;
		private var _headers:Dictionary;
		private var _nObjs:uint;
		private var _nEvts:uint;
		private var _serverPath:String;
		private var _annotName:String;
		private var _totalTime:int;
		private var _fps:Number;
		private var _folder:String;
		
		private var _stabMatrices:Array;
		private var _nFrameNode:XML;
		private var _lastEditedFrameNode:XML;
		private var _objects:Dictionary;
		private var _events:Dictionary;
		
		private var _downloadComplete:Boolean;
		private var _spriteState:String;
		private static var _urlBase:String = "http://labelme.csail.mit.edu/VideoLabelMe/VLMAnnotations";
		
		private var _processedFrames:int;
		private var _totalNFrames:int;
		
		private var _objectsProcessingXML:ArrayCollection;
		private var _totalObjectsToProcess:int;
		
		private var _objectsXMLString:String;
		private var _eventsXMLString:String;
		private var _annotationXMLString:String;
		
		public  var _myStartTime:Number = 0;
		public function LMXMLAnnotation(filename:String=null, annotName:String=null, v:Number=NaN, folder:String=null, 
										numFrames:uint=NaN, lastEditedFrame:uint=NaN,
										sourceData:Dictionary=null, spriteState:String=null):void
		{
			if(filename)
			{
				_nObjs = 0;
				_nEvts = 0;
				_totalTime = -1;
				_fps = -1;
				_annotName = annotName;
				_folder = folder;
				_headers = new Dictionary();
				var xml:XML;
				_annotation = makeXMLNode("annotation", "");
				
				xml = makeXMLNode("folder", folder);
				_headers["folder"] = xml;
				_annotation.appendChild(xml);
				
				xml = makeXMLNode("filename", filename);
				_headers["filename"] = xml;
				_annotation.appendChild(xml);
				
				_nFrameNode = makeXMLNode("numFrames", numFrames);
				_headers["numFrames"] = _nFrameNode;
				
				//todo i don't think we have anything that we use here...
				var s:XML = new XML("<source></source>")
				var type:XML= makeXMLNode("type", "video");
				s.appendChild(type);
				s.appendChild(makeXMLNode("sourceImage", "The MIT-CSAIL database of objects and scenes"));
				s.appendChild(makeXMLNode("sourceAnnotation", "VideoLabelMe Webtool"));
				
				_headers["source"] = s;
				
				if(sourceData)
					for (var key:Object in sourceData)
					{
						s.appendChild(new XML("<" + key + "> " + sourceData[key] + " </" + key +  ">"));
					}
				
				_annotation.appendChild(s);
				
				_stabMatrices = new Array();
				_objects = new Dictionary();
				_events = new Dictionary();
				
				_downloadComplete = false;
				this._spriteState = spriteState;
			}
			
			registerClassAlias("flash.geom.Matrix", flash.geom.Matrix);
			this._annotationXMLString = "";
		}
		
		public function set numFrames(nFrames:int):void
		{
			var newNode:XML = makeXMLNode("numFrames", nFrames);
			_annotation.insertChildBefore(this._nFrameNode, newNode);
			LMXMLAnnotation.xmlDeleteNode(this._nFrameNode);
			_nFrameNode = newNode;
		}
		
		
		public function set fps(f:int):void
		{
			_fps = f;
		}
		
		public function get fps():int
		{
			return _fps;
		}
		
		public function set totalTime(t:Number):void
		{
			_totalTime = t;
		}
		
		public function get totalTime():Number
		{
			return _totalTime;
		}
		
		public function onFaultLoad(event:FaultEvent):void
		{
			//Alert.show(String(event.fault));
			//do nothing, we just leave the default template
		}
		
		public function commitBinary():void
		{
			/*var httpS:HTTPService = new HTTPService();
			httpS = new HTTPService();
			
			httpS.url = "http://labelme1.csail.mit.edu/submit_video_annotation_binary.cgi";
			httpS.method = "POST";
			httpS.contentType = "application/xml";
			httpS.resultFormat = "xml";
			httpS.addEventListener(ResultEvent.RESULT, onHttpSubmitResult);
			httpS.addEventListener(FaultEvent.FAULT, onFaultSubmitResult);	
			httpS.headers["FILENAME"] = _annotName;
			*/
			var sendBytes:ByteArray = new ByteArray();
			this.writeExternal(sendBytes);
			sendBytes.position = 0;
			
			//	httpS.data = sendBytes
			
			var objXML:XML = new XML("objects");
			objXML.appendChild(sendBytes);
			
			var x:XML = new XML("<![CDATA[" + "Hi"+ "]]>");
			_annotation.appendChild(x);
			
			//	httpS.send(_annotation);	
		}
		
		public function commit():void
		{
			//generate the xml with the updated objects
			updateXMLObjects();
			updateXMLEvents();
			
			//update the xml string with the objects and the new events
			var annotStr:String = this._annotation.toXMLString();
			
			var tag:String = "<annotation>";
			var startId:int = annotStr.indexOf(tag) + tag.length;
			
			tag = "</annotation>";
			var endId:int = annotStr.indexOf(tag);
			_objectsXMLString = "";
			for each (var obj:LMObject in _objects)
			{
				_objectsXMLString+=obj.getXMLString();
			}
			
			this._annotationXMLString = annotStr.substring(0, endId) + this._objectsXMLString +  this._eventsXMLString+ "</annotation>";
			
			
			
			onXMLObjectsReady();
			
			//this.addEventListener(LMXMLEvent.XMLOBJECTSREADY, onXMLObjectsReady);
			
		}
		
		private function onXMLObjectsReady(evt:LMXMLEvent=null):void
		{
			var httpS:HTTPService = new HTTPService();
			httpS = new HTTPService();
			
			httpS.url = "http://labelme.csail.mit.edu/submit_video_annotation.cgi";
			httpS.method = "POST";
			httpS.contentType = "application/xml";
			httpS.resultFormat = "xml";
			httpS.addEventListener(ResultEvent.RESULT, onHttpSubmitResult);
			httpS.addEventListener(FaultEvent.FAULT, onFaultSubmitResult);	
			httpS.headers["FILENAME"] = _annotName;
			
			this.removeEventListener(LMXMLEvent.XMLOBJECTSREADY, onXMLObjectsReady);
			//	httpS.send(_annotation);
			httpS.send(_annotationXMLString);
		}
		
		public function onHttpSubmitResult(event:ResultEvent):void 
		{
			var result:Object = event.result;
			//Todo Do something with the result.
			trace("xml submission success");
			var e:LMEvent = new LMEvent(LMEvent.COMMITSUCCESS);
			dispatchEvent(e);
			
		}
		
		public function onFaultSubmitResult(event:FaultEvent):void
		{
			var faultstring:String = event.fault.faultString;
			//Alert.show(faultstring);
			trace("error submitting xml " + faultstring);
			var e:LMEvent =  new LMEvent(LMEvent.COMMITFAIL);
			dispatchEvent(e);
		}
		
		public function downloadLMXMLAnnotation():void
		{
			var httpS:HTTPService = new HTTPService();
			this._myStartTime = getTimer();
			
			httpS.url = _urlBase+"/" + _annotName+ "?randomstring=" + int(Math.random() *1000);
			//Alert.show("trying to fetch: " + httpS.url);
			//httpS.resultFormat = "xml";
			httpS.resultFormat = "e4x";
			//httpS.resultFormat = "text";
			httpS.requestTimeout = 300;
			httpS.headers= "Cache-Control: no-cache, must-revalidate";
			httpS.addEventListener(ResultEvent.RESULT, onCompleteDownload);
			httpS.addEventListener(FaultEvent.FAULT, onFaultDownload);
			
			httpS.send();
		}
		
		//adds headers to the xml if they don't exist
		private function addHeaders():void
		{
			var children:XMLList = _annotation.children();
			var childrenDict:Dictionary = new Dictionary();
			for each (var child:XML in children)
			{
				childrenDict[child.localName()] = true;	
			}
			
			for (var key:String in this._headers)
			{
				if(!childrenDict[key])
					_annotation.appendChild(_headers[key]);
			}	
		}
		
		
		public function onCompleteDownload(event:ResultEvent):void 
		{
			var endHttp:Number = getTimer();
			
			trace("time taken to download xml from server : " + String(endHttp - this._myStartTime) +" ms");
			
			var sTime:Number = getTimer();
			
			var mySTime:Number = getTimer();
			//var myStr:String = String(event.result);
			_annotation = XML(event.result);
			//var myXML:XMLNode = XMLNode(event.result);
			var myETime:Number = getTimer();
			trace("time taken to convert string to adobe's XML object : " + String(myETime - mySTime) +" ms");
			
			
			//	return;
			
			
			//if the annotation file lacks the stabilization fields, introduce them
			addHeaders();
			
			//read the camera parameters
			var mySTime:Number = getTimer();
			var stabPresent:Boolean = readStabilizationParams();
			var myETime:Number = getTimer();
			trace("time taken to parse stabilization : " + String(myETime - mySTime) +" ms");
			
			
			var maxEId:int = -1;
			var evtIds:XMLList = _annotation.event.eid;
			for each (var eid:int in evtIds)
			{
				if(eid > maxEId)
					maxEId = eid;
			}
			
			_nEvts = maxEId + 1;
			
			mySTime = getTimer();
			readObjects();
			myETime = getTimer();
			trace("time taken to parse objects : " +String(myETime - mySTime) +" ms");
			
			mySTime = getTimer();
			readEvents();
			myETime = getTimer();
			trace("time taken to parse events : " +String(myETime - mySTime) +" ms");
			
			this.clearObjectsAndEventsFromXML();
			var e:LMXMLEvent = new LMXMLEvent(LMXMLEvent.XMLDOWNLOADED);
			e._stabilizationPresent = stabPresent;
			dispatchEvent(e);
			//			this.dispatchEvent(new ResultEvent(ResultEvent.RESULT,true,false));
			var eTime:Number = getTimer();
			
			trace("time taken to parse xml : " + String(eTime - sTime) +" ms");
			var stop:Number = 1;	
		}
		
		
		private function readStabilizationParams():Boolean
		{
			var f:XMLList = _annotation.stabilization;
			trace(f.length());
			if(f && f.length()>0)
			{
				var stab:XML = XML(_annotation.stabilization);
				var frameInfo:XMLList = stab.fr;
				_stabMatrices = new Array();
				var A:Matrix =  new Matrix;
				if(frameInfo.length()>0)
				{
					A.identity(); 
					_stabMatrices.push(A);
					for (var i:int = 0; i <frameInfo.length(); i++)
					{	
						
						var M:Matrix = new Matrix(frameInfo[i].a, frameInfo[i].b,frameInfo[i].d, frameInfo[i].e, frameInfo[i].c, frameInfo[i].f);
						
						_stabMatrices.push(M);
					}
				}
				return true;
			}
			else
			{
				return false;
				//Alert.show("No stabilization parameters found."); 
			}	
		}
		
		private function readObjects():void
		{
			var objects:XMLList = _annotation.object;
			
			var maxId:int = 0;
			var i:int = 0;
			//for each object, create an array that has an LMPolygon with it
			for each(var obj:XML in objects)
			{
				i = i +1;
				
				//create the xml for all the polygons in the object list
				var lmO:LMObject = new LMObject();
				
				lmO.initialize(obj, this._spriteState);
				_objects[lmO.id] = lmO;
				if(lmO.id > maxId)
					maxId = lmO.id;
				
			}
			
			this._nObjs = maxId + 1;
			
		}
		
		private function readEvents():void
		{
			
			var deletes:XMLList = _annotation.event.deleted;
			var startFrames:XMLList = _annotation.event.startFrame;
			var endFrames:XMLList = _annotation.event.endFrame;
			var createdFrames:XMLList = _annotation.event.createdFrame;
			var sentences:XMLList = _annotation.event.sentence;
			var eids:XMLList = _annotation.event.eid;
			
			var events:XMLList = _annotation.event;
			
			for(var i:int = 0; i < eids.length(); i++)
			{
				
				var obj:Object = parseSentences(sentences[i]);
				var tokenLinks:Dictionary = obj.dictionary;
				var tokens:Array = obj.tokens;
				var username:String = events[i].username;
				var x:int = events[i].x;
				var y:int = events[i].y;
				var evt:LMEventAnnotationItem = new LMEventAnnotationItem(eids[i], startFrames[i], endFrames[i], createdFrames[i],
					tokenLinks, tokens, x, y, username);
				//	a.addItem(evt);
				_events[int(eids[i])] = evt;
				trace("storing event with id : " + eids[i]);
				
			}			
			
		}
		
		private function clearObjectsAndEventsFromXML():void
		{
			
			var objects:XMLList = _annotation.object;
			
			var mySTime:Number = getTimer();
			
			//erases all objects in the xml
			for each (var xmlObj:XML in objects)
			{
				LMXMLAnnotation.xmlDeleteNode(xmlObj);	
			}
			//erases all the events in the xml
			var events:XMLList = _annotation.event;
			
			for each (var xmlObj:XML in events)
			{
				LMXMLAnnotation.xmlDeleteNode(xmlObj);	
			}
			
		}
		
		// updates the xml with the objects in memory. 
		private function updateXMLObjects():void
		{
			//_annotation = new XML();
			//erases all the objects in the xml
			var objects:XMLList = _annotation.object;
			
			var mySTime:Number = getTimer();
			
			/*
			for each (var xmlObj:XML in objects)
			{
			LMXMLAnnotation.xmlDeleteNode(xmlObj);	
			}
			*/
			_totalNFrames = 0;
			for each (var obj:LMObject in _objects)
			{
				_totalNFrames += obj.endFrame - obj.startFrame + 1;
			}
			
			var myETime:Number = getTimer();
			trace("time taken to prep xml object : " + String(myETime - mySTime) +" ms");
			
			
			
			_processedFrames = 0;
			_objectsProcessingXML = new ArrayCollection();
			_totalObjectsToProcess = 0;
			//_objectsXMLString = "";
			for each (obj in _objects)
			{
				_objectsProcessingXML.addItem(obj);
				
				obj.addEventListener(Event.COMPLETE, onObjectXMLProcessed);
				obj.addEventListener(LMXMLEvent.XMLPOLYGONSPROCESSDPROGRESS, onXMLPolysProcessed);
				//this._annotation.appendChild(obj.getXML());	
				mySTime = getTimer();
				//_objectsXMLString+=obj.getXMLString();
				obj.processXMLString();
				//	obj.processXML();
				myETime = getTimer();
				trace("time taken to process an object: "+ String(myETime - mySTime) +" ms");
				this._totalObjectsToProcess++;
			}	
			var e:LMXMLEvent = new LMXMLEvent(LMXMLEvent.XMLPERCENTOBJECTSPROCESSED);
			e._totalObjects = this._totalObjectsToProcess;
			e._processedObjects = 0;
			
			e._percentObjectsProcessed = 0;
			dispatchEvent(e);
			
			
		}
		
		private function onXMLPolysProcessed(evt:LMXMLEvent):void
		{
			
			var e:LMXMLEvent = new LMXMLEvent(LMXMLEvent.XMLPOLYGONSPROCESSDPROGRESS);
			e._processedPolygons = evt._processedPolygons;
			e._totalPolygons = evt._totalPolygons;
			dispatchEvent(e);	
		}
		
		private function onObjectXMLProcessed(evt:Event):void
		{
			var obj:LMObject = evt.target as LMObject;
			//this._annotation.appendChild(obj._objXML);
			obj.removeEventListener(Event.COMPLETE, onObjectXMLProcessed);
			var idx:int = _objectsProcessingXML.getItemIndex(evt.target);
			_objectsProcessingXML.removeItemAt(idx);
			if(_objectsProcessingXML.length ==0)
			{
				//we are done updating all objects, so dispatch event
				dispatchEvent(new LMXMLEvent(LMXMLEvent.XMLOBJECTSREADY));
			}
			else
			{
				var e:LMXMLEvent = new LMXMLEvent(LMXMLEvent.XMLPERCENTOBJECTSPROCESSED);
				e._totalObjects = this._totalObjectsToProcess;
				e._processedObjects = this._totalObjectsToProcess - _objectsProcessingXML.length;
				
				e._percentObjectsProcessed = 100*(1 - Number(_objectsProcessingXML.length)/this._totalObjectsToProcess);
				dispatchEvent(e);
			}
			trace("object processed");
		}
		
		private function onObjectProgress(evt:LMAnnotationEvent):void
		{
			_processedFrames += evt._packagingProgress;
			var evt:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.ANNOTATIONPACKAGINGPROGRESS)
			evt._packagingProgress = _processedFrames / _totalNFrames;
			dispatchEvent(evt);
			
			evt.target.removeEventListener(LMAnnotationEvent.ANNOTATIONPACKAGINGPROGRESS, onObjectProgress);
			
			
		}
		// updates the xmal with the events in memory
		private function updateXMLEvents():void
		{
			this._eventsXMLString = "";
			//erases all the events in the xml
			var events:XMLList = _annotation.event;
			
			/*			for each (var xmlObj:XML in events)
			{
			LMXMLAnnotation.xmlDeleteNode(xmlObj);	
			}*/
			
			for each (var eventInfo:LMEventAnnotationItem in _events)
			{
				this._eventsXMLString +=eventInfo.getXMLString();
				//	this._annotation.appendChild(eventInfo.getXML());
			}
		}
		
		public function onFaultDownload(event:FaultEvent):void
		{
			dispatchEvent(event);
			trace("fault" + event.fault.message);
		}
		
		/*public function saveExistingEvent(eventId:uint, userName:String, deleted:int, startFrame:uint, endFrame:uint, createdFrame:uint,
		tokenDict:Dictionary, tokenNames:Array):void
		{
		//TODO we will have to change this framework to store events also in a dictionary to avoid lookups
		this.deleteEvent(eventId);
		addEventWithId(eventId, userName, deleted, startFrame, endFrame, createdFrame, tokenDict, tokenNames);
		}*/
		
		
		public function updateEventAnnotation(eventInfo:LMEventAnnotationItem, dispatchWhenDone:Boolean=true):uint
		{
			if(eventInfo.eid>=0)
			{
				_events[eventInfo.eid] = eventInfo;
				return eventInfo.eid;
			}
			else
			{
				//new event
				eventInfo.eid = _nEvts;
				_events[eventInfo.eid] = eventInfo;
				_nEvts++;
			}
			if(dispatchWhenDone)
			{
				var evt:LMEvent = new LMEvent(LMEvent.EVENTLISTCHANGE, true, true);
				this.dispatchEvent(evt);
			}
			return _nEvts-1;
		}
		/*
		
		//WARNING: BE super careful here. We need to make sure there's only one event with a unique id in the xml. so every time this function is called
		// we need to make sure that either an event with such id is removed or not. this function should be replaced by a new one that lets you edit the fields in place
		private function addEventWithId(eventId:uint, userName:String, deleted:int, startFrame:uint, endFrame:uint, createdFrame:uint,
		tokenDict:Dictionary, tokenNames:Array):uint
		{
		
		var evtXML:XML = makeXMLNode("event", "");
		evtXML.appendChild(makeXMLNode("username", userName));
		evtXML.appendChild(makeXMLNode("deleted", deleted));
		evtXML.appendChild(makeXMLNode("startFrame", startFrame));
		evtXML.appendChild(makeXMLNode("endFrame", endFrame));
		evtXML.appendChild(makeXMLNode("createdFrame", createdFrame));
		evtXML.appendChild(makeXMLNode("date", new Date()));
		evtXML.appendChild(makeXMLNode("eid", eventId));
		
		var sentenceXML:XML = makeXMLNode("sentence", "")
		
		for (var i:int = 0 ; i < tokenNames.length; i++)
		{	
		var wordXML:XML = makeXMLNode("word", "")
		wordXML.appendChild(makeXMLNode("text", tokenNames[i]));
		var arr:ArrayCollection = tokenDict[i];
		for each (var obId:String in arr)
		{
		wordXML.appendChild(makeXMLNode("id", obId));
		}	
		sentenceXML.appendChild(wordXML);	
		}
		
		evtXML.appendChild(sentenceXML);
		_annotation.appendChild(evtXML);
		var evt:LMEvent = new LMEvent(LMEvent.EVENTLISTCHANGE);
		this.dispatchEvent(evt);
		return eventId;			
		}
		*/
		/*public function addEvent(userName:String, deleted:int, startFrame:uint, endFrame:uint, createdFrame:uint,
		tokenDict:Dictionary, tokenNames:Array):uint
		{
		addEventWithId(_nEvts, userName, deleted, startFrame, endFrame, createdFrame, tokenDict, tokenNames);
		return _nEvts-1;
		}
		*/
		public function addObject(name:String, deleted:int, verified:int, userName:String,
								  startFrame:uint, endFrame:uint, createdFrame:uint,
								  poly:LMPolygon, moving:String, actionDescription:String, dispatch:Boolean=false, oId:int=-1):uint
		{
			
			var keyFrames = new ArrayCollection();
			keyFrames.addItem(createdFrame);
			if(oId <0)
			{	
				oId = _nObjs;
				_nObjs++;
			}
			var polys:Dictionary = propagateObjectAnnotation(oId, startFrame, endFrame, poly, oId);
			
			var obj:LMObject = new LMObject(LMXMLAnnotation.makeXMLNode("object", ""), polys, keyFrames, oId, startFrame, endFrame, name, moving, actionDescription, userName, verified);
			_objects[obj.id] = obj; 
			
			if(dispatch)
			{
				var evt:LMEvent = new LMEvent(LMEvent.LISTCHANGE, true, true);
				this.dispatchEvent(evt);
			}
			
			return oId;
		}
		
		
		//propagate copies of the same annotation across all frames
		private function propagateObjectAnnotation(objectId:int, startFrame:int, endFrame:int, poly:LMPolygon, oId:int):Dictionary
		{
			
			var sTime:Number = getTimer();
			
			var a:Dictionary = new Dictionary();
			var j:int = 0;
			//	var x:XMLList = XMLList(a);
			var A:Matrix = new Matrix();
			A.identity();
			var refFrame:int = poly.frame;
			
			var id:int = refFrame - startFrame;
			j = id + 1;
			for(var i:int = refFrame-1; i >= startFrame; i--)
			{
				var p:LMPolygon = poly.clone();
				
				if(this._stabMatrices.length >0)
				{
					var M:Matrix = Matrix(_stabMatrices[i]);
					
					M = M.clone();
					M.invert();
					A.concat(M);
					for(var k:int = 0; k < p.nPoints; k++)
					{
						var point:Point = new Point(p.getX(k), p.getY(k));	
						var newPoint:Point;
						newPoint = A.transformPoint(point);
						//if(k == 0)
						//	trace("k " + k + " oldx " + p.getX(k)  + " oldy " + p.getY(k) + "new x " + newPoint.x + " new y " + newPoint.y)
						p.setX(k, newPoint.x);
						p.setY(k, newPoint.y);
					}
				}
				p.frame = i;
				p.objectId = oId;
				a[p.frame] = p;
			}
			poly.objectId =oId;
			a[poly.frame] = poly;
			
			A = new Matrix();
			A.identity();
			for(i = refFrame + 1;  i<= endFrame; i++)
			{
				p = poly.clone();
				
				if ( i == endFrame){
					var stop:int = 1;		
				}
				if(this._stabMatrices.length >0)
				{
					var M:Matrix = Matrix(_stabMatrices[i]);
					
					M = M.clone();
					
					A.concat(M);
					for(k = 0; k < p.nPoints; k++)
					{
						point = new Point(p.getX(k), p.getY(k));
						newPoint= A.transformPoint(point);
						//		if(k == 0)
						//			trace("k " + k + " oldx " + p.getX(k)  + " oldy " + p.getY(k) + "new x " + newPoint.x + " new y " + newPoint.y)
						
						p.setX(k, newPoint.x);
						p.setY(k, newPoint.y);
					}
				}		
				p.frame = i;
				p.objectId = oId;
				a[p.frame] = p;
			} 
			var eTime:Number = getTimer();
			
			trace("time taken to propagate frames : " + String(eTime - sTime) +" ms");
			
			return a;
			//return null;
		}
		
		public function addPointChangeAnnotation(objectId:int, poly:LMPolygon, pIdxs:Array):void
		{
			var sTime:Number = getTimer();
			var obj:LMObject = _objects[objectId];
			
			if(!obj)
				return;
			
			obj.setPoly(poly);
			
			var leftPoly:LMPolygon = null;
			var rightPoly:LMPolygon = null;
			
			var leftPolyWrapper:LMPolygonWrapper = getClosestManuallyLabeledPoly(objectId, poly.frame, true);
			var rightPolyWrapper:LMPolygonWrapper = getClosestManuallyLabeledPoly(objectId, poly.frame, false);
			
			//if the polygon is from the created frame AND there are no other manually annotated points, 
			// delete the current object and propagate a new one.
			var createdFrame:int = obj.createdFrame;
			if(createdFrame == poly.frame && (!leftPolyWrapper || !leftPolyWrapper.manuallyLabeled) && (!rightPolyWrapper || !rightPolyWrapper.manuallyLabeled))
			{
				this.deleteObject(poly.objectId, false);
				this.addObject(obj.name, 0, obj.verified, obj.userName, obj.startFrame, obj.endFrame, obj.createdFrame, poly, obj.moving, obj.action,false,  poly.objectId);		
			}
			else
			{
				if(leftPolyWrapper)
					leftPoly = leftPolyWrapper.poly;
				
				if(rightPolyWrapper)
					rightPoly = rightPolyWrapper.poly;
				
				//look for the closest neighbors that have been manually annotated and interpolate between them
				var list:Array = null;
				var oldPolys:XMLList = null;
				
				var sf:int = poly.startFrame;
				var ef:int = poly.endFrame;
				
				if(leftPoly !=null)
				{
					if(!leftPolyWrapper.manuallyLabeled && rightPoly)
					{	
						//	list = linearlyInterpolateFrames(objectId, poly, rightPoly, leftPoly.frame,poly.frame, VLMParams.red);
						var clonePoly:LMPolygon = poly.clone();
						clonePoly.frame = leftPoly.frame;
						list = linearlyInterpolateFrames(objectId,  clonePoly, poly, leftPoly.frame, poly.frame, VLMParams.red);
						
					}
					else
						list = linearlyInterpolateFrames(objectId, leftPoly, poly, leftPoly.frame, poly.frame, VLMParams.red);	
					
					//insert the new nodes
					if(list !=null)
					{
						for(var i:int=0; i<list.length; i++)
							obj.setPoly(list[i]);
						
						//figure out what's missing and trim 
						
						if (leftPoly.frame  != list[0].frame)
							sf = list[0].frame
						else 
							sf = leftPoly.startFrame;
						
						if(poly.frame != list[list.length-1].frame)
							ef = list[list.length-1].frame
						else
							ef = poly.endFrame
						this.removeComplementFrameAnnotations(poly.objectId, sf, ef)
						
					}
				}
				if(rightPoly !=null)
				{
					if(!rightPolyWrapper.manuallyLabeled && leftPoly)
					{	//list = linearlyInterpolateFrames(objectId, leftPoly, poly, poly.frame, rightPoly.frame, VLMParams.green)
						var clonePoly:LMPolygon = poly.clone();
						clonePoly.frame = rightPoly.frame;
						
						list = linearlyInterpolateFrames(objectId,poly,clonePoly, poly.frame, rightPoly.frame, VLMParams.green)
						
					}
					else	
						list = linearlyInterpolateFrames(objectId, poly, rightPoly, poly.frame, rightPoly.frame, VLMParams.green);	
					
					//insert the new nodes
					if(list !=null)// && oldPolys != null)
					{
						for(var i:int=0; i<list.length; i++)
							obj.setPoly(list[i]);
						
						//figure out what's missing and trim 
						if(list.length >0)
						{
							if (poly.frame  != list[0].frame)
								sf = list[0].frame
							else 
								sf = sf;
							
							if(rightPoly.frame != list[list.length-1].frame)
								ef = list[list.length-1].frame
							else
								ef = ef;
						}
						this.removeComplementFrameAnnotations(poly.objectId, sf, ef)
					}
				}
				var eTime:Number = getTimer();
				trace("time taken to propagate frames : " + String(eTime - sTime) +" ms");
			}
		}
		
		private function deleteXMLList(list:XMLList):void
		{
			for(var i:int = 0; i < list.length(); i++)
			{
				LMXMLAnnotation.xmlDeleteNode(list[i]);
			}
		}
		
		private function getClosestManuallyLabeledPoly(objectId:int, baseFrame:int, toLeft:Boolean):LMPolygonWrapper
		{
			//toLeft indicates whether we're looking for the closest frame to the left
			var obj:LMObject = LMObject(_objects[objectId]);
			var keyFrame:int = obj.getClosestKeyFrame(baseFrame, toLeft);
			var neighborPoly:LMPolygon = null;
			var manuallyLabeled:Boolean;
			
			if(keyFrame>=0)
			{
				neighborPoly = obj.getPoly(keyFrame);
				manuallyLabeled = true;		
			}
			else
			{
				if(toLeft && baseFrame > obj.startFrame)
				{
					neighborPoly = obj.getPoly(obj.startFrame)
					manuallyLabeled = false;
				}
				else if(!toLeft && baseFrame < obj.endFrame)
				{
					neighborPoly = obj.getPoly(obj.endFrame)
					manuallyLabeled = false;
				}
			}
			
			if(neighborPoly)
			{
				var polyWrapper:LMPolygonWrapper = new LMPolygonWrapper;
				
				polyWrapper.manuallyLabeled = manuallyLabeled;
				polyWrapper.poly = neighborPoly;
				return polyWrapper;
			}
			return null;
		}
		
		private function getParents(list:XMLList):Array
		{
			var parents:Array = new Array();
			for each(var item:XML in list)
			{
				var exists:Boolean = false;
				
				for each (var p:XML in parents)
				{
					if(p == item)
					{
						exists = true;
						break;
					}	
				}
				if(!exists)
					parents.push(item.parent());	
			}	
			return parents;
		}
		
		//transforms the points in the polygon with the M matrix
		private function transformPoly(poly:LMPolygon, M:Matrix):LMPolygon
		{
			for (var i:int; i< poly.nPoints; i++)
			{
				var pt:Point = M.transformPoint(new Point(poly.getX(i), poly.getY(i)));
				poly.setX(i, pt.x);
				poly.setY(i, pt.y);
			}
			return poly;
		}
		
		// compute the mean for the values in the array. Assumes the array is of numbers
		private function mean(values:Array):Number
		{
			var s:Number = 0;
			for each(var v:Number in values)
			s +=v;
			return s/values.length;
		}
		
		
		private function sign(num:Number):Boolean
		{
			return (num>0);
		}
		
		//new function that considers scaling, rotation, and translation. 
		//returns the lmpolygons between f1 and f2 (including the edges)
		private function linearlyInterpolateFrames(objectId:int, startPoly:LMPolygon, endPoly:LMPolygon, f1:int, f2:int, color:uint):Array
		{
			trace("starting to interpolate points");
			var sTime:Number = getTimer();
			
			var endFrame:int = endPoly.frame;
			var startFrame:int = startPoly.frame;
			
			//number of frames (counting also the end and start frames)
			var nFrames:Number = endPoly.frame - startPoly.frame + 1;
			
			//todo handle for soft deletes!!!!!!!!!!!!!!
			var obj:LMObject = LMObject(_objects[objectId]);
			
			var stabilizedPolys:Dictionary = new Dictionary();
			var M:Matrix = new Matrix();
			M.identity();
			if(this._stabMatrices.length>0)
				M.concat(_stabMatrices[startPoly.frame]);
			
			stabilizedPolys[startPoly.frame] = startPoly;
			// put the stabilized matrices from the start poly to the right
			for(var t:int = startPoly.frame+1; t <= Math.max(f2, endPoly.frame); t++)
			{
				var lmp:LMPolygon = startPoly.clone();
				
				if(this._stabMatrices.length>0)
				{
					lmp = transformPoly(lmp, M);
					M.concat(_stabMatrices[t]);
				}
				stabilizedPolys[t] = lmp;
			}
			
			//now go from start to left.
			M.identity(); 
			for(var t:int = startPoly.frame-1; t >= Math.min(f1, startPoly.frame) ; t--)
			{
				var lmp:LMPolygon = startPoly.clone();
				
				if(this._stabMatrices.length>0)
				{
					M.concat(_stabMatrices[t+1]);
					M.invert();
					lmp = transformPoly(lmp, M);
				}
				stabilizedPolys[t] = lmp;
			}
			
			if(stabilizedPolys[startPoly.frame])
				LMPolygon(stabilizedPolys[startPoly.frame]).labeled = startPoly.labeled;
			if(stabilizedPolys[endPoly.frame])
				LMPolygon(stabilizedPolys[endPoly.frame]).labeled = endPoly.labeled;
			
			
			//the start polygon translated to the end frame after all the stabilization
			var polySE:LMPolygon = stabilizedPolys[startPoly.frame];
			
			//now calculate the scaling and rotation differences between the start and the end frames
			var scaling:Array = new Array();
			var rotation:Array = new Array();
			
			for(var n:int = 0; n < startPoly.nPoints - 1 ; n++)
			{
				var norm1:Number = Math.sqrt(Math.pow(endPoly.getX(n)-endPoly.getX(n+1),2) + Math.pow(endPoly.getY(n)-endPoly.getY(n+1),2));
				var norm2:Number = Math.sqrt(Math.pow(polySE.getX(n)-polySE.getX(n+1),2) + Math.pow(polySE.getY(n)-polySE.getY(n+1),2));
				scaling.push(norm1/norm2);
				
				var sign:Number = (endPoly.getY(n+1)-endPoly.getY(n) >= 0) ? 1 : -1 ;
				
				var rotE:Number = Math.acos(((endPoly.getX(n+1)-endPoly.getX(n)))/(norm1)) * sign ;
				
				sign = (polySE.getY(n+1)-polySE.getY(n) >= 0) ? 1 : -1 ;
				
				var rotSE:Number = Math.acos(((polySE.getX(n+1)-polySE.getX(n)))/(norm2)) * sign;
				
				var r1:Number = rotSE - rotE;
				var r2:Number = rotSE - rotE + 2*Math.PI;
				var r3:Number = rotSE - rotE - 2*Math.PI
				
				if(Math.abs(r1) < Math.abs(r2))
				{
					if(Math.abs(r3) < Math.abs(r1))
						r = r3;
					else
						r = r1;
				}
				else
				{
					if(Math.abs(r3) < Math.abs(r2))
						r = r3;
					else
						r = r2;
				}
				rotation.push(r);
			}
			
			//2) Find the scaling rotation, and translation
			// estaimation of scale
			var s:Number = 0;
			for each (var val:Number in scaling)
			s += val;	
			s = s / scaling.length;
			
			//estimation of rotation
			var an:Number = 0;
			for each (var r:Number in rotation)
			an += r;
			an = an / rotation.length;
			
			//estimation of translation. Calculate the centroid of the polygon in the end frame and the one in the start frame
			var centrXEnd:Number = 0;
			var centrYEnd:Number = 0;
			//centroid of the start polygon (stabilized)
			var centrXSE:Number = 0;
			var centrYSE:Number = 0;
			
			for(var i:int = 0 ; i < endPoly.nPoints; i++)
			{	
				centrXEnd += endPoly.getX(i);
				centrYEnd += endPoly.getY(i);
				centrXSE += polySE.getX(i);
				centrYSE += polySE.getY(i);	
			}
			
			centrXEnd /= endPoly.nPoints;
			centrYEnd /= endPoly.nPoints;
			centrXSE /= endPoly.nPoints;
			centrYSE /= endPoly.nPoints;
			
			//the translation estimate is the difference between the centroid of the polygon in the last frame and the one in the first frame
			var transX:Number = centrXEnd - centrXSE; 
			var transY:Number = centrYEnd - centrYSE;
			
			//get the vanishing point to compute the translation parameters
			var vPt:Point = LM3DInterpolation.getVanishingPoint(startPoly.xArray, startPoly.yArray, endPoly.xArray, endPoly.yArray);
			
			//parameters of the 3d line the centroid draws
			var a:Number, b:Number, c:Number, d:Number, e:Number, cx:Number, cy:Number;
			
			if(vPt)
			{
				//this.drawPoint(vPt.x, vPt.y, color);
				b = vPt.x;
				e = vPt.y;
				cy =  (centrYEnd - vPt.y) / (centrYSE - centrYEnd);
				cx =  (centrXEnd - vPt.x) / (centrXSE - centrXEnd);
				c =cx;
				a = c*centrXSE;
				d = c*centrYSE;
				//	trace("cy : " + cy + " cx : " + cx);
				if(Math.abs(cx - cy) > 0.3)
				{	
					trace('the object is not rigid enough, translating linearly in 2d');
					vPt = null;
				}	 
				else
				{
					
					//for debugging. checking that the parametrization is correct
					var centrStart:Point = new Point(a/c,d/c)
					var centrEnd:Point = new Point((a + b) / (c + 1) , (d + e) / (c + 1) )
					
					//		trace("estimated centroid at start poly : [" +  centrStart.x +" , "+ centrStart.y + "] actual start centroid : [ "  +  centrXSE +" , "+ centrYSE + "]"  )
					//		trace("estimated centroid at end poly : [" +  centrEnd.x +" , "+ centrEnd.y + "] actual end centroid : [ "  +  centrXEnd +" , "+ centrYEnd + "]"  )
					
					centrXSE = centrStart.x;
					centrYSE = centrStart.y;
					centrXEnd = centrEnd.x;
					centrYEnd = centrEnd.y;
					
					transX = centrXEnd - centrXSE; 
					transY = centrYEnd - centrYSE;
				}	
			}
			
			// 3) Find the residual
			var HSE:Matrix = new Matrix();
			HSE.identity(); 
			var T1:Matrix = new Matrix();
			T1.translate(-centrXSE, centrYSE);
			var R:Matrix = new Matrix();
			R.rotate(an);
			
			var S:Matrix = new Matrix();
			S.scale(s,s);
			var T2:Matrix = new Matrix();
			T2.translate(centrXSE, -centrYSE);
			
			var T3:Matrix = new Matrix();
			T3.translate(transX, -transY);
			
			HSE.concat(T1);
			HSE.concat(R);
			HSE.concat(S);
			HSE.concat(T2);
			HSE.concat(T3);
			
			//compute the residual. the difference between the estimate of the transformation of the start polygon to the end  and  the actual end
			var residual:Array = new Array();
			
			
			for(i = 0; i < endPoly.nPoints; i++)
			{
				var estim:Point = HSE.transformPoint(new Point(polySE.getX(i), -1*polySE.getY(i)));//(HSE.transformPoint(new Point(polySE.getX(i) - centrXSE, polySE.getY(i) - centrYSE)).add(new Point(centrXSE + transX, centrYSE + transY)) );
				estim.y = -1* estim.y;
				var res:Point= new Point(endPoly.getX(i), endPoly.getY(i)).subtract(estim);
				//	trace("annotated : [" +  endPoly.getX(i) + " , " + endPoly.getY(i) + "] . Estimated: [ "+ estim.x +" , " + estim.y +"]");
				residual.push(res);
			}
			
			centrXEnd += endPoly.getX(i);
			centrYEnd += endPoly.getY(i);
			centrXSE += polySE.getX(i);
			centrYSE += polySE.getY(i)
			
			//trace("annotated centroild : [" + centrXEnd +","+ centrYEnd +"]  original: [" + centrXSE +"," + centrYSE + "]" );
			
			
			//4) final interpolation
			var interpolatedPolys:Array = new Array();
			var endT:int = f2;
			var denom:Boolean = (c +(f1 - startFrame)/(nFrames-1))>0;
			var startFound:Boolean = false;
			
			//interpolatedPolys.push(startPoly); // we don't need to compute t = startframe
			for( t = f1; t <= f2; t++)
			{			
				var tt:Number = (t - startFrame)/(nFrames-1); // goes from 0 to 1 as t goes from 1 to Nframes	
				
				//we need to cut out the polygons that are getting behind the camera
				
				
				if(vPt && this.sign(c) != this.sign(c+tt))
					continue;
				
				var u:Number = c+ tt;
				
				//	trace("c + tt = " + u.toString()); 
				
				
				var Ht:Matrix = new Matrix( Math.pow(s,tt)*Math.cos(an*tt) , Math.pow(s, tt)*Math.sin(an*tt) , -1*Math.pow(s, tt) *Math.sin(an*tt) , Math.pow(s,tt)*Math.cos(an*tt));
				var centernX:Number = this.mean(LMPolygon(stabilizedPolys[t]).xArray);
				var centernY:Number = this.mean(LMPolygon(stabilizedPolys[t]).yArray);
				
				//camera motion [residual linear interpolation + 3D linear translation + homography]
				for(i = 0; i < endPoly.nPoints; i++)
				{
					var stabPoly:LMPolygon = stabilizedPolys[t] as LMPolygon;
					var homography:Point = Ht.transformPoint(new Point(stabPoly.getX(i) - centernX, -(stabPoly.getY(i) - centernY)));
					
					var translation:Point = new Point();
					
					//if there's vanishing point, do a linear interpolation in 3d, otherwise, do the normal one in 2d
					if(vPt)
					{
						translation.x =  (a + tt*b) / (c + tt);
						translation.y =  - (d + tt*e) / (c + tt);
						//		trace("tt = " + tt + "  translation [x, y] = [" + translation.x + " , " +  translation.y + "] max : [" + centrXEnd + " , " +  centrYEnd +"]"); 
					}
					else
					{
						translation = new Point(centernX + transX * tt, -centernY - transY *tt);
					}
					var res:Point = new Point(Point(residual[i]).x * tt, Point(residual[i]).y * tt);
					
					var newX:Number = homography.x + translation.x + res.x; 
					var newY:Number = -homography.y - translation.y + res.y;
					
					if(tt == 1)
						var voo:Number  = 0;
					
					//	trace("end annotated point : [ " +  endPoly.getX(i) + " , " + endPoly.getY(i) + "] new one : ["+ newX +" , " +  newY +"]" );
					
					stabPoly.setX(i, newX);
					stabPoly.setY(i, newY); 
				}
				stabPoly.frame = t;	
				
				interpolatedPolys.push(stabPoly);
			}
			var eTime:Number = getTimer();
			trace("time taken to interpolate frames : " + String(eTime - sTime) +" ms");
			
			return interpolatedPolys;
		}
		
		///the point pt is at endFrame
		private function unstabilizePoint(pt:Point, startFrame:int, endFrame:int):Point
		{
			var A:Matrix = new Matrix();
			var M:Matrix;
			A.identity();
			if(endFrame >startFrame)
			{
				for (var j:int = endFrame; j > startFrame ;j--)
				{
					M = this._stabMatrices[j].clone()
					M.invert();
					A.concat(M);	
				}
			}
			else
			{
				for(j = endFrame+1; j <= startFrame; j++)
				{
					M = this._stabMatrices[j].clone();
					A.concat(M);
				}
			}
			return A.transformPoint(pt);
		}
		
		private function stabilizePoint(pt:Point, startFrame:int, endFrame:int):Point
		{
			var A:Matrix = new Matrix();
			A.identity();
			if(startFrame < endFrame)
			{
				for(var j:int = startFrame+1; j<= endFrame; j++)
				{
					A.concat(this._stabMatrices[j].clone());
				}
			}
			else
			{
				for(j = startFrame -1 ; j >= endFrame ; j--)
				{
					var M:Matrix = this._stabMatrices[j].clone();
					M.invert();
					A.concat(M); 				
				}
			}
			return A.transformPoint(pt);
		}
		
		public function renameObject(i:int, newName:String, moving:String, action:String):void
		{
			
			var obj:LMObject = LMObject(_objects[i]);//_annotation.object.(id == i );
			if(!obj)
				return;
			
			obj.name = newName;
			obj.moving = moving;
			obj.action = action;
			
			var evt:LMEvent = new LMEvent(LMEvent.LISTCHANGE, true, true);
			this.dispatchEvent(evt);
		}
		
		public function deleteObject(i:int, dispatch:Boolean=true):LMObject
		{
			var obj:LMObject = LMObject(_objects[i]);
			if(obj)
			{
				//do a hard delete. we might want to explore if we want to do a soft deletion
				delete _objects[i];
				if(dispatch)
				{
					var evt:LMEvent = new LMEvent(LMEvent.LISTCHANGE, true, true);
					this.dispatchEvent(evt);
				}
			}	
			return obj;
		}
		
		public function deleteEvent(eid:uint, dispatch:Boolean=true):void
		{
			var evt:LMEventAnnotationItem = _events[eid];
			if(evt)
			{
				delete _events[eid];
				if(dispatch)
				{
					var event:LMEvent = new LMEvent(LMEvent.EVENTLISTCHANGE, true, true);
					this.dispatchEvent(event);
				}
			}
		}
	
		public static function xmlDeleteNode(xmlToDelete:XML):Boolean
		{
			
			var cn:XMLList = XMLList(xmlToDelete.parent()).children();
			if(cn[xmlToDelete.childIndex()] == xmlToDelete)
			{
				//trace ("deleting " + xmlToDelete.childIndex());
				delete cn[xmlToDelete.childIndex()];
				return true;
			}
			return false;
		}
		
		public function getPolygons(frameNo:int):Array
		{
			var a:Array = new Array();
			//loop through all the objects in the xml file and check for the ones
			// that are in the actual frame
			for each (var obj:LMObject in _objects)
			{
				var lmp:LMPolygon = obj.getPolyAtFrame(frameNo);
				if(lmp)
					a.push(lmp);	
			}
			return a;	
		}
		
		public function getPolygon(frameNo:int, objectId:int):LMPolygon
		{
			return LMObject(_objects[objectId]).getPolyAtFrame(frameNo);
		}
		
		public function getXML():String
		{
			return _annotation.toString();
		}
		
		public function getEvents(frameNo:int):Array
		{
			//iterate through all the events and assemble an array with all the events that happen within a range
			var a:Array = new Array();
			//loop through all the objects in the xml file and check for the ones
			// that are in the actual frame
			for each (var event:LMEventAnnotationItem in _events)
			{
				if(event && frameNo>=event.startFrame && frameNo <=event.endFrame)
					a.push(event);	
			}
			return a;	
		}
		
		
		public function getEventAnnotations():Dictionary
		{
			return _events;
		
		}
		
		//converts the sentence xml into a dictionary and a token list
		private function parseSentences(xml:XML):Object
		{
			var words:XMLList = xml.word;
			var dictionary:Dictionary = new Dictionary();
			var tokens:Array = new Array();
			for (var i:int=0; i< words.length(); i++)
			{
				var token:String = String(words[i].text);
				var ids:XMLList = words[i].id;
				var a:ArrayCollection = new ArrayCollection();
				for each (var id:int in ids)
				{
					a.addItem(id);
				}
				dictionary[i] = a;
				tokens.push(token);
			}
			var obj:Object = new Object;
			obj.dictionary = dictionary;
			obj.tokens = tokens;
			return obj;
		}
		
		//returns the annotaitons of all the objects for this xml
		public function getObjectAnnotations():ArrayCollection
		{
			
			var a:ArrayCollection = new ArrayCollection();
			for each(var obj:LMObject in _objects)
			{
				var annot:LMObjectAnnotationItem = new LMObjectAnnotationItem(obj.id, obj.name, obj.startFrame, obj.endFrame, obj.moving, obj.action);
				a.addItem(annot);
			}
			return a;
		}
		
		//takes the closes frame created for the object and propagates it in the indicated frames
		public function appendFrameAnnotations(objectId:int, startFrame:int, endFrame:int):void
		{
			trace("ERROR: unimplemented function");
		}
		
		//remvoe all the polygons outside the interval
		public function removeComplementFrameAnnotations(objectId:int, startFrame:int, endFrame:int):void
		{		
			var obj:LMObject = LMObject(_objects[objectId]);
			obj.startFrame = startFrame;
			obj.endFrame = endFrame;
			
			var evt:LMEvent = new LMEvent(LMEvent.LISTCHANGE, true, true);
			this.dispatchEvent(evt);
			dispatchDoneCut(objectId, obj.startFrame, obj.endFrame);
			
			trace("LMXMLAnnnotation:  new (start, end): " + startFrame + " , " + endFrame);
		}
		
		public function adjustEventFrames(eventId:int, startFrame:int=NaN, endFrame:int=NaN, createdFrame:int=NaN):Boolean
		{
			var evtInfo:LMEventAnnotationItem = LMEventAnnotationItem(_events[eventId]);
			if(!evtInfo)
				return false;
			
			if(!isNaN(startFrame))
				evtInfo.startFrame = startFrame;
			if(!isNaN(endFrame))
				evtInfo.endFrame = endFrame;
			if(!isNaN(createdFrame))
				evtInfo.createdFrame = createdFrame;
			_events[eventId] = evtInfo; //not sure if this line is necessary. try some experiments to check
			
			var evt:LMEvent = new LMEvent(LMEvent.EVENTLISTCHANGE, true, true);
			this.dispatchEvent(evt);
			dispatchDoneCut(eventId, evt.startFrame, evt.endFrame);
			
			return true;
		}
		//returns an array with the key frames (numbers) that have been manually labeled
		public function getManuallyLabeledFrames(objectId:int):ArrayCollection
		{
			var lmO:LMObject = LMObject(_objects[objectId]);
			if(lmO)
				return lmO.keyFrames;
			else
				return null;
		}
		
		public static function makeXMLNode(attrib:String, val:Object):XML
		{
			return new XML("<"+ attrib +">" + val.toString() + "</"+ attrib +">");		
		}
		
		private function dispatchDoneCut(id:int, sf:int, ef:int):void
		{
			var e:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.DONECUTTINGFRAMES, true, false, id,
				null, sf, ef);
			dispatchEvent(e); 
		}
		
		///debugging code: no production code should depend on this
		private function drawPoint(x:int, y:int, color:uint):void
		{
			//this._annotator.graphics.beginFill(color);
			//this._annotator.graphics.drawCircle(x, y, 5);
			//this._annotator.graphics.endFill();
		}
		
		
		public function readExternal(input:IDataInput):void
		{
			//"datainput does not contain bytes".
			var sTime:Number = getTimer();
			// headers are null.
			
			
			this._headers = input.readObject() as Dictionary;
			this._stabMatrices = input.readObject() as Array;
			this._objects = input.readObject() as Dictionary;
			
			this._events = input.readObject() as Dictionary;
			this._nObjs = input.readInt();
			this._nEvts = input.readInt();
			var eTime:Number = getTimer();
			
			
			trace("time taken to deserialize in bytes: " + String(eTime - sTime) +" ms");
			
			var e:LMXMLEvent = new LMXMLEvent(LMXMLEvent.XMLDOWNLOADED);
			var stabPresent:Boolean;
			if(_stabMatrices && _stabMatrices.length>0)
				stabPresent = true;
			else
				stabPresent = false;
			
			e._stabilizationPresent = stabPresent;
			dispatchEvent(e);
		}
		
		public function writeExternal(output:IDataOutput):void
		{
			var sTime:Number = getTimer();
			
			//	registerClassAlias("flash.geom.Matrix", flash.geom.Matrix);
			
			output.writeObject(_headers);
			output.writeObject(_stabMatrices);
			output.writeObject(_objects);
			
			output.writeObject(_events);
			output.writeInt(_nObjs);
			output.writeInt(_nEvts);
			
			var eTime:Number = getTimer();
			trace("time taken to serialize in bytes: " + String(eTime - sTime) +" ms");
			
		}
		
		
	}
}

import vlm.core.LMPolygon;

class LMPolygonWrapper
{
	public var poly:LMPolygon;
	public var manuallyLabeled:Boolean;	
}

