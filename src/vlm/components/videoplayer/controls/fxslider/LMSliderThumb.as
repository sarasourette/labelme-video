//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.videoplayer.controls.fxslider
{
import mx.controls.Button;
import mx.core.mx_internal;

use namespace mx_internal;

public class LMSliderThumb extends Button
{
	public function LMSliderThumb()
	{
		super();
		
		stickyHighlighting = true;
	}
	
	override protected function measure():void
	{
		super.measure();

		measuredWidth = 9;
		measuredHeight = 9;
	}
}
}
