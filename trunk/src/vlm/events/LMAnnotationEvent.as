//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.events
{
	import flash.events.Event;
	import vlm.core.LMPolygon;

	public class LMAnnotationEvent extends Event
	{
		public static const POINTCHANGE:String = "pointchange";
		public static const POLYTRANSLATE:String = "polytranslate";
		public static const POLYSCALE:String = "polyscale";
	
		public static const CREATEOBJECT:String = "createobject";
		public static const ANNOTATENEWFRAME:String = "annotatenewframe";
		public static const DELETEOBJECTANNOTATION:String = "deleteobjectannotation";
		public static const RENAMEOBJECT:String = "renameobject";
		
		public static const RESIZEOBJECTSTART:String = "resizeobjectstart";
		public static const RESIZEOBJECT:String = "resizeobject";
		public static const RESIZEOBJECTEND:String = "resizeobjectend";
				
		public static const CANCELANNOTATIONCREATION:String = "cancelannotationcreation";
		public static const DONECUTTINGFRAMES:String = "donecuttingframes";
		
		public static const SPRITECLICK:String = "spriteclick";
		
		public static const ANNOTATIONPACKAGINGPROGRESS = "annotationpackagingprogress";
		
		
		public var _id:int;
		public var _polygon:LMPolygon;
		public var _startFrame:int;
		public var _endFrame:int
		public var _name:String;
		public var _createdFrame:int;
		public var _moving:String;
		public var _action:String;
		public var _packagingProgress:int; // packaging progress in percentage
		
		
		//variables for scaling or rotation
		public var _width:int;
		public var _height:int;
		public var _oldX:int;
		public var _oldY:int;
		public var _newX:int;
		public var _newY:int;
		public var _anchorX:int;
		public var _anchorY:int;	
		 
		public var _rotating:Boolean;
		
		
		public function LMAnnotationEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false, id:int=-1, 
										poly:LMPolygon=null, startFrame:int=-1, endFrame:int=-1,
										name:String="", createdFrame:int =-1)
		{
			super(type, bubbles, cancelable);
			_id = id;
			_polygon = poly;
			_startFrame = startFrame;
			_endFrame = endFrame;
			_name = name;
			_createdFrame = createdFrame;
			
			_rotating = false;
		}	
	}
}
