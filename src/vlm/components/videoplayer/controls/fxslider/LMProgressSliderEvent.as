package vlm.components.videoplayer.controls.fxslider
{
	import flash.events.Event;
	
	import mx.events.SliderEvent;
	
	public class LMProgressSliderEvent extends SliderEvent
	{
		public static var SELECTEDREGIONCHANGE:String = "selectedregionchange";
		public static var SUBMITCUTCLICK:String = "submitbuttonclick";
		public static var LEFTBRACKETMOVETOPLAYHEADREQUEST:String = "leftbracketmovetoplayheadrequest";
		public static var RIGHTBRACKETMOVETOPLAYHEADREQUEST:String = "rightbracketmovetoplayheadrequest";
		
		
		public var _valueLeft:Number;
		public var _valueRight:Number;
		public var _lastThumbSelected:int;
		public var _minVal:Number;
		public var _maxVal:Number
		
	    public function LMProgressSliderEvent(type:String, 
	    					valLeft:Number = NaN, valRight:Number = NaN,
	    					lastThumbIdx:int = -1,
	    					minVal:Number=NaN, maxVal:Number=NaN,
	    					bubbles:Boolean = true,
                            cancelable:Boolean = false,                           
                            triggerEvent:Event = null,
                            clickTarget:String = null, keyCode:int = -1):void
		{
			super(type, bubbles, cancelable, thumbIndex, value, triggerEvent, clickTarget, keyCode);
			this._valueLeft = valLeft;
			this._valueRight = valRight;
			this._lastThumbSelected = lastThumbIdx;
			this._minVal = minVal;
			this._maxVal = maxVal;
		}

	}
}
