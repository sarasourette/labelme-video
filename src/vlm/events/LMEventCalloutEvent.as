//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.events
{
	import flash.events.Event;
	
	public class LMEventCalloutEvent extends Event
	{
		public static const CHANGE:String = "CHANGE";
		
		public function LMEventCalloutEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
