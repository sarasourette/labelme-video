//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.events
{
	import vlm.core.LMEventAnnotationItem;
	
	import flash.events.Event;
	import flash.utils.Dictionary;

	public class LMEventsEvent extends Event
	{
		public static const ADDEVENTCLICK:String = "addeventclick";
		public static const SAVENEWEVENTCLICK:String = "saveneweventclick";
		public static const DELETECLICK:String = "deleteclick";
		public static const ADDNEWLINK:String = "addnewlink";
		public static const SENTENCERENDERED:String = "sentencerendered";
		public static const CLOSEEVENTVIEW:String = "closeeventview";
		
		public static const SELECTEVENTREQUEST:String = "selecteventrequest";
		
		public static const STARTFRAMECHANGE:String = "startframechange";
		public static const ENDFRAMECHANGE:String = "endframechange";
		public static const SHOWEVENTS:String = "showevents";
		public static const HIDEEVENTS:String = "hideevents";
		public static const CANCELEVENTCREATION:String = "canceleventcreation";
		public static const EVENTCHANGED:String = "eventchanged";
		
		//for link selections
		public var _stageStartX:int;
		public var _stageStartY:int;
		public var _tokenIdx:int;
		//the id of the object the new link generated
		public var _objectId:uint;
			
		
		public var _evtItem:LMEventAnnotationItem;
		
		public function LMEventsEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_evtItem = null;
			_objectId = NaN;
		}
		
	}
}
