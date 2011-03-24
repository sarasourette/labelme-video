//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.videoplayer.controls
{
	import mx.controls.HSlider;

	public class TimelineSlider extends HSlider
	{
		private var _totalTime:Number; //time in seconds
		
		public function TimelineSlider()
		{
			super();
			this.thumbCount = 2;
			this.setStyle("showTrackHighlight", true);
			
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			this.getThumbAt(0).id = "0";
			this.getThumbAt(1).id = "1";
       }

		
	}
}
