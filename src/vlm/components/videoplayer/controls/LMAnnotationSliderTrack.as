//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.videoplayer.controls
{
	import mx.core.UIComponent;

	public class LMAnnotationSliderTrack extends UIComponent
	{
		public function LMAnnotationSliderTrack()
		{
			super();
		}
		
		override public function get height():Number{  
 	       return 20;  
		}
		
	    override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{  
		    super.updateDisplayList(unscaledWidth, unscaledHeight);  
		   	this.graphics.clear();
		    //create the line that represents the track  
		    this.graphics.moveTo(0,2);  
		    this.graphics.lineStyle(5,VLMParams.white);  
		    this.graphics.lineTo(unscaledWidth,2);  
        }    
		
	}
}
