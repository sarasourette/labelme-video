//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.events
{
	import flash.events.Event;

	public class LMXMLEvent extends Event
	{
		public static var XMLOBJECTSREADY:String = "xmlobjectsready";
		public static var XMLPERCENTOBJECTSPROCESSED:String = "percentobjectprocessed";
		
		public static var XMLPOLYGONSPROCESSDPROGRESS:String = "xmlpolygonsprocessedprogress";
		public static var XMLDOWNLOADED:String = "xmldownloaded";
		
		public var _totalPolygons:uint;
		public var _processedPolygons:uint;
		
		public var _totalObjects:uint;
		public var _processedObjects:uint;
		
		public var _stabilizationPresent:Boolean;
		public var _percentObjectsProcessed:int;
		
		public function LMXMLEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false, lmTarget:Object=null):void
		{
			super(type, bubbles, cancelable);	
		}	
	}
}
