//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.videoplayer.controls.fxvideo
{
	public class SubmitCutButton extends LMButton
	{
		public function SubmitCutButton()
		{
			super();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			this.label = "cut";
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);	
		}

	}
}
