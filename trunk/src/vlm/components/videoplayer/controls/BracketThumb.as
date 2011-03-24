//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.videoplayer.controls
{
	import mx.controls.sliderClasses.SliderThumb;
	
	public class BracketThumb extends SliderThumb
	{
		
		public function BracketThumb()
		{
			super();
			this.width = 0;
			this.height = 0;
			//set properties so that a hand appears on hover
			this.useHandCursor = true;
			this.buttonMode = true;
			this.mouseChildren = false;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{
        	var x:int = 0;
        	var y:int = -24;
        	var w:int = 5;
  			var h:int = 22 ;
	        
  			if(this.id == "0")
  			{
	  			super.updateDisplayList(unscaledWidth,unscaledHeight);
	            this.graphics.lineStyle(5,VLMParams.white);
	            this.graphics.moveTo(x+w,y+h);
	            this.graphics.lineTo(x+0,y+h);
	            this.graphics.lineTo(x+0,y+0);
	            this.graphics.lineTo(x+w,y+0);
	            
	            this.graphics.lineStyle(2,VLMParams.lightBlue);
	            this.graphics.moveTo(x+w,y+h);
	            this.graphics.lineTo(x+0,y+h);
	            this.graphics.lineTo(x+0,y+0);
	            this.graphics.lineTo(x+w,y+0);

				this.toolTip = "annotation start frame";
	    	}
            else
            {
            	super.updateDisplayList(unscaledWidth,unscaledHeight);
	            this.graphics.lineStyle(5,VLMParams.white);
	            this.graphics.moveTo(0+x,h+y);
	            this.graphics.lineTo(w+x,h+y);
	            this.graphics.lineTo(w+x,0+y);
	            this.graphics.lineTo(0+x,0+y);
	            
	            this.graphics.lineStyle(2,VLMParams.lightBlue);
	            this.graphics.moveTo(0+x,h+y);
	            this.graphics.lineTo(w+x,h+y);
	            this.graphics.lineTo(w+x,0+y);
	            this.graphics.lineTo(0+x,0+y);
	            
	            this.toolTip = "annotation end frame";
            }     
        }
	}
}
