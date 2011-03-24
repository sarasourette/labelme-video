//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.events
{
	import flash.events.Event;
	
	public class LMEvent extends Event
	{
		public static var LISTCHANGE:String = "change";
		public static var EVENTLISTCHANGE:String = "eventlistchange";
		public static var POLYGONCHANGE:String = "annotationedit";
		public static var DELETEANNOTATION:String = "deleteannotation";
		public static var OBJECTRENAME:String = "objectrename";
		public static var ANNOTATIONSLOADED:String = "annotationsloaded";
		public static var VIDEOREADY:String = "videoReady";
		public static var CURRENTFRAMEREQUEST:String = "currentframerequest";
		public static var DELETEPOLYSOUTSIDERANGE:String = "deletepolysoutsiderange";
		public static var POLYSELECTED:String = "polyselected";
		public static var POLYHOLD:String = "polyhold"
		public static var POLYUNHOLD:String = "polyunhold";
		public static var POLYHIGHLIGHTED:String = "polyhighlighted";
		public static var POLYUNHIGHLIGHTED:String = "polyunhighlighted";
		
		public static var ENTERNOTHINGSTATE:String = "enternothingstate";
		public static var ENTERPOLYSELECTSTATE:String = "enterpolyselectstate";
		public static var ENTERANNOTATIONSTATE:String = "enterannotationstate";
		
		//type of CURRENTFRAMEREQUEST
		public static var STARTFRAMETYPE:String = "startframetype";
		public static var ENDTFRAMETYPE:String = "endframetype";
		
		public static var ERASEREQUEST:String = "eraserequest";
		public static var SAVEANNOTATIONSREQUEST:String = "saveannotationsrequest";
		public static var OPENANNOTATIONSREQUEST:String = "openannotationsrequest";
		public static var COMMITSUCCESS:String = "commitsuccess";
		public static var COMMITFAIL:String = "commitfail";
		
		public static var ENABLEEVENTANNOTATION:String = "enableeventannotation";
		public static var DISABLEEVENTANNOTATION:String = "disableeventannotation";
		
		
		public static const SHOWOBJECTS:String = "showobjects";
		public static const HIDEOBJECTS:String = "hideobjects";
		
		
		public static var VIDEOLOADED:String = "videoloaded";
		//event to request the seek to a particular frame
		public static var KEYFRAMESELECTED:String = "seektoframe";
		
		
		//event to request to show tracks
		public static var SHOWTRACKS:String = "show tracks";
		
		//event to hide tracks
		public static var HIDETRACKS:String = "hide tracks";
		
		public static var DONECOMMITINGPROPERTIES = "Done committing properties";
		
		private var lmTarget:Object;
		// instance variables describing an annotation
		private var _id:int;
		private var _name:String;
		private var _frameType:String;
		private var _startFrame:int;
		private var _endFrame:int;
		
		//instance variable for the frame seek event
		private var _frame:int;
		
		private var _selectedId:int;
		
		public function LMEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false, lmTarget:Object=null):void
		{
			super(type, bubbles, cancelable);	
			this.lmTarget = lmTarget;
			_id = -1
			_name = null;
			_frameType = "";
			_startFrame = -1;
			_endFrame = -1;
			_frame = -1;
		}
		
		public function LMTarget():Object{
			return lmTarget;
		}
		
		public function setAnnotationInfo(id:int, name:String):void
		{
			_id = id;
			_name = name;
		}
		
		public function get id():int
		{
			return _id;
		}
		
		public function get name():String
		{
			return _name;	
		}
		
		public function set frameType(s:String):void
		{
			_frameType = s;
		}
		
		public function get frameType():String
		{
			return _frameType;	
		}
		
		public function get startFrame():int
		{
			return _startFrame;
		}
		
		public function set startFrame(i:int):void
		{
			_startFrame = i;	
		}
		
		public function get endFrame():int
		{
			return _endFrame;
		}
		
		public function set endFrame(i:int):void
		{
			_endFrame = i;	
		}
		
		public function get selectedId():int
		{
			return _selectedId;
		}
		
		public function set selectedId(s:int):void
		{
			_selectedId = s;	
		}
		
		public function get frame():int
		{
			return _frame;
		}
		
		public function set frame(i:int):void
		{
			_frame = i;	
		}
	}
}
