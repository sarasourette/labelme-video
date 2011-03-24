//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.core
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	import vlm.events.LMXMLEvent;
	import vlm.events.LMAnnotationEvent;
	
	[RemoteClass(alias="LMAnnotator.LMObject")]
	public class LMObject extends EventDispatcher implements IExternalizable
	{
		private var _rootXML:XML;
		private var _polygons:Dictionary;
		private var _frames:Array;
		
		//publicly accesible instance variables
		public var id:int;
		public var createdFrame:int;
		public var keyFrames:ArrayCollection;
		public var name:String;
		public var moving:String;
		public var action:String;
		public var userName:String;
		public var verified:int;
		private var _startFrame:int;
		private var _endFrame:int;
		
		private var _minStartFrame:int;
		private var _maxEndFrame:int;
		public var _objXML:XML;
		public var _objXMLString:String;
		private var _savedIndex:int;
		private var _allowedTime:Number;
		private var _startTime:Number;
		
		// ENTER_FRAME events dispatched by a composed DisplayObject
		// instance; one can be used for all RenderGradient instances
		private static var _enterFrameDispatcher:Shape = new Shape();
			
		//TODO handle soft deletes. Currently the code doesn't check if the object has been soft deleted
		
		public function LMObject(rootXML:XML=null, polygons:Dictionary=null, keyFrames:ArrayCollection=null, id:int=-1, startFrame:int=-1, endFrame:int=-1, name:String="", moving:String="", action:String="", userName:String="anonymous", verified:int=0, scaleX:Number=1, scaleY:Number=1):void
		{
			this._rootXML = rootXML;
			if(!rootXML)
				this._rootXML = LMXMLAnnotation.makeXMLNode("object", "");
				
			this._polygons = polygons;
			if(!polygons)
				this._polygons = new Dictionary();
			
			this.keyFrames = keyFrames;
			if(!keyFrames)
				this.keyFrames = new ArrayCollection();
			this.id = id;	
			this._startFrame = startFrame;
			this._endFrame = endFrame;
			this.name = name;
			this.moving = moving;
			this.action = action;
			this.userName = userName;
			this.verified = verified;
			this._minStartFrame = -1;
			this._maxEndFrame = int.MAX_VALUE;
		}
	

		public function initialize(xml:XML, spriteState:String):void
		{
			_rootXML = xml;
			var polys:XMLList = _rootXML.polygon;
			_startFrame = xml.startFrame;
			_endFrame = xml.endFrame;
			var lmp1:LMPolygon = null;
			var oId:int = xml.id;
			var maxF:int = 0;
			var f:int = _startFrame;
			for each (var p:XML in polys)
			{
				var lmp:LMPolygon = new LMPolygon();
				lmp.initializeWithXML(p, spriteState, oId);
				lmp.frame = f;
				f = f+1;
				this._polygons[lmp.frame] = lmp;
				if(lmp.frame > maxF)
					maxF = lmp.frame;
					
				// check if the polygon has a labeled point ( which makes it a keyframe)
				// if so, put it in the array of keyframes
				var labeledPoints:int = lmp.labeled;
				if(labeledPoints)
					this.keyFrames.addItem(lmp.frame);

			}		
			this._endFrame = maxF;
			this._minStartFrame = this._startFrame;
			this._maxEndFrame = this._endFrame;
			this.id = _rootXML.id;
			var node:XMLList = _rootXML.id;
		
			this.createdFrame = _rootXML.createdFrame;
						
			//these are the fields that change and for which the xml fields will have to be refresed when getting the xml
			this.name = _rootXML.name;
			
			//variables that might or might not be in the XML. 
			// this includes the variables that have been progressively added in time to the xml... (pretty much all)
			if(_rootXML.moving!=undefined)
			{	
				this.moving = String(_rootXML.moving); 
			}
			else
				this.moving = "";
			
			if(_rootXML.action!=undefined)
			{
				this.action = String(_rootXML.action);
			}
			else
				this.action = "";
			
			if(_rootXML.verified!=undefined)
			{
				this.verified = int(_rootXML.verified);
			}
			else
				this.verified = 0;
			
					
		}
		
		//checks if the object is contained in the particular frame, if yes, returns the polygon, if not, returns null
		public function getPolyAtFrame(f:int):LMPolygon
		{
			//this assumes that objects appear within a contigous chunk of time (no holes in the time)
			if(f>=this._startFrame && f<=this._endFrame)
			{
				var lmp:LMPolygon = LMPolygon(this._polygons[f]);
				lmp.startFrame = this._startFrame;
				lmp.endFrame = this._endFrame;
				return lmp;
			}	
			return null; 
		}
		
		public function processXMLString():void
		{
			_objXMLString = this.getXMLString();
			var evt:Event = new Event(Event.COMPLETE);
			dispatchEvent(evt);
		}	
		
		
		//async version of getXML. Will dispatch an event when it's done
		public function processXML():void
		{
			var fps:Number = 12;
			_startTime = getTimer();
			_allowedTime = 1000/fps; //- renderTime - otherScriptsTime;
		
			_savedIndex = this._startFrame;;
			_objXML = LMXMLAnnotation.makeXMLNode("object", "");
			_objXML.appendChild(LMXMLAnnotation.makeXMLNode("name", this.name));
			_objXML.appendChild(LMXMLAnnotation.makeXMLNode("moving", this.moving));
			_objXML.appendChild(LMXMLAnnotation.makeXMLNode("action", this.action));
			_objXML.appendChild(LMXMLAnnotation.makeXMLNode("verified", this.verified.toString()));
			_objXML.appendChild(LMXMLAnnotation.makeXMLNode("id", this.id.toString()));
			_objXML.appendChild(LMXMLAnnotation.makeXMLNode("createdFrame", this.createdFrame.toString()));
			_objXML.appendChild(LMXMLAnnotation.makeXMLNode("startFrame", this._startFrame.toString()));
			_objXML.appendChild(LMXMLAnnotation.makeXMLNode("endFrame", this._endFrame.toString()));
			
			processXMLLoopHandler();	
		}
		
		private function processXMLLoopHandler(evt:Event=null):void
		{
			
			for (var i:int=_savedIndex; i <= this._endFrame; i++){
				var lmp:LMPolygon = LMPolygon(_polygons[i]);
				_objXML.appendChild(lmp.getXML());	
			}
			var i:int = this._endFrame;
			
			var e:LMXMLEvent = new LMXMLEvent(LMXMLEvent.XMLPOLYGONSPROCESSDPROGRESS);
			e._processedPolygons = i;
			e._totalPolygons = this._endFrame - this._startFrame + 1;
			dispatchEvent(e);
			_enterFrameDispatcher.removeEventListener(Event.ENTER_FRAME, processXMLLoopHandler);
			var evt:Event = new Event(Event.COMPLETE);
			dispatchEvent(evt);
		}
		
		
		public function getXMLString():String
		{
		 	var str:String = "<object><name>"+name+"</name><moving>"+moving+"</moving><action>"+ action+
				"</action><verified>"+verified+"</verified><id>"+id+"</id><createdFrame>"+createdFrame+ 
				"</createdFrame><startFrame>"+ _startFrame+"</startFrame><endFrame>"+_endFrame+"</endFrame>";
				
			for(var i:int= this._startFrame; i <= this._endFrame; i++)
			{
				var lmp:LMPolygon = LMPolygon(_polygons[i]);
				str+=lmp.getXMLString();
			
			}
			str+="</object>";
			return str;
		}
		
		//returns the xml version of the object.
		//CAUTION: check for the new start and end frames, which might not coincide with the lmpolygons that we have, so we have to index
		public function getXML():XML
		{
			//append the header fields to the xml
			var xml:XML = LMXMLAnnotation.makeXMLNode("object", "");
			
			xml.appendChild(LMXMLAnnotation.makeXMLNode("name", this.name));
			xml.appendChild(LMXMLAnnotation.makeXMLNode("moving", this.moving));
			xml.appendChild(LMXMLAnnotation.makeXMLNode("action", this.action));
			xml.appendChild(LMXMLAnnotation.makeXMLNode("verified", this.verified.toString()));
			xml.appendChild(LMXMLAnnotation.makeXMLNode("id", this.id.toString()));
			xml.appendChild(LMXMLAnnotation.makeXMLNode("createdFrame", this.createdFrame.toString()));
			xml.appendChild(LMXMLAnnotation.makeXMLNode("startFrame", this._startFrame.toString()));
			xml.appendChild(LMXMLAnnotation.makeXMLNode("endFrame", this._endFrame.toString()));
			
			//append the polygons to the xml
			var iter:int = 0;
			for(var i:int= this._startFrame; i <= this._endFrame; i++)
			{
				var lmp:LMPolygon = LMPolygon(_polygons[i]);
				xml.appendChild(lmp.getXML());
				iter++;
				if (iter > 1000 || i>=_endFrame)
				{
					var evt:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.ANNOTATIONPACKAGINGPROGRESS)
					evt._packagingProgress = iter;
				
					dispatchEvent(evt);
					iter = 0;
				}
			}
			return xml;
		}
		
		public function getPoly(f:int):LMPolygon
		{
			var lmp:LMPolygon=  LMPolygon(this._polygons[f]);
			if(lmp)
			{
				lmp.startFrame = this._startFrame;
				lmp.endFrame = this._endFrame;
			}	
			return lmp;
		}
		
		public function setPoly(lmp:LMPolygon):void
		{
			if(lmp)// && lmp.frame!=1)
			{
				this._polygons[lmp.frame] = lmp;
				//if any of the points in the polygon is labeled, mark this as a keyframe
				var labeled:int = lmp.labeled;
				
					if(labeled == 1)
					{
						//to maintain the keyframes array sorted, figure out where in the arraycollection this fits
						if(keyFrames[keyFrames.length-1] < lmp.frame)
							keyFrames.addItem(lmp.frame)
						else
						{
							for(var i:int = 0; i < this.keyFrames.length; i++)
							{
								if(this.keyFrames[i] > lmp.frame)
								{
									this.keyFrames.addItemAt(lmp.frame, i);
									break;
								}
							}
						}
					}
				
			}
				
		}
		
		//finds the closest keyframe from a base frame (excluding it)
		// returns the keyframe number or if doens't exist, returns -1
		public function getClosestKeyFrame(frameNo:int, toLeft:Boolean):int
		{
			var i:int;
			var kf:int;
			var candKf:int = -1; 
			
			if(toLeft)
			{
				for(i = 0; i<this.keyFrames.length && this.keyFrames[i] < frameNo; i++)	
				{
					kf = candKf;
					candKf = this.keyFrames[i];
				}
			}
			else
			{
				for(i = keyFrames.length-1; i>=0 && this.keyFrames[i] > frameNo ; i--)
				{
					kf = candKf;
					candKf = this.keyFrames[i];	
				}
			}
				
			kf = candKf;
			return kf;
		}
		
		// returns the closest manually labeled polygon from a base frame (excluding it if it is the case).
		public function getClosestKeyFramePoly(frameNo:int, toLeft:Boolean):LMPolygon
		{
			var kf:int = this.getClosestKeyFrame(frameNo, toLeft);
			if(kf>=0)
				return this._polygons[kf];
			return null;
		}
		
		
		//getters and setters
		
		public function get startFrame():int
		{
			return this._startFrame;
		}
		
		public function set startFrame(f:int):void
		{
			if(f >= this._minStartFrame && f <=this._maxEndFrame)
				this._startFrame = f;
		}
		public function get endFrame():int
		{
			return this._endFrame;
		}
		
		public function set endFrame(f:int):void
		{
			if(f >= this._minStartFrame && f <= this._maxEndFrame)
				this._endFrame = f;
		}	//serialization functions
		
		public function readExternal(input:IDataInput):void
		{
			this.name = input.readUTF();
			this.action = input.readUTF();
			this.verified = input.readInt();
			this.id = input.readInt();
			this.createdFrame = input.readInt();
			this._startFrame = input.readInt();
			this._endFrame = input.readInt();
			this._polygons = input.readObject() as Dictionary;
			this.keyFrames = input.readObject() as ArrayCollection;
		}
		
		public function writeExternal(output:IDataOutput):void
		{
			output.writeUTF(this.name);
			output.writeUTF(this.action);
			output.writeInt(this.verified);
			output.writeInt(this.id);
			output.writeInt(this.createdFrame);
			output.writeInt(this._startFrame);
			output.writeInt(this._endFrame);
			output.writeObject(this._polygons) as Dictionary;
			output.writeObject(this.keyFrames);
			
		}
	}
}
