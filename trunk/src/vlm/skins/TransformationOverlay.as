//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.skins
{
	
	import mx.skins.RectangularBorder;

	public class TransformationOverlay extends RectangularBorder
	{
		public function TransformationOverlay()
		{
			super();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void 
        {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
    		var cornerRadius:Number = getStyle("cornerRadius");
            var backgroundColor:int = getStyle("backgroundColor");
            var backgroundAlpha:Number = getStyle("backgroundAlpha");
            graphics.clear();

			drawRoundRect
            (
                0, 0, unscaledWidth, unscaledHeight, cornerRadius, 
                backgroundColor, backgroundAlpha
            );
           var color:uint = VLMParams.lightBlue;
           	
		      	
 			this.drawRectangle(0,0, unscaledWidth, unscaledHeight,color);
 			
 			
 			//draw the rotation tip line
 			//the inner color component of the rotation tip
 			this.graphics.lineStyle(0.5, color,1);
 			this.graphics.moveTo(unscaledWidth/2, 0);
 			this.graphics.lineTo(unscaledWidth/2, -30);
 			
        }
        
        private function drawRectangle(x:int, y:int, width:int, height:int, color:uint):void
        {
        	this.graphics.moveTo(x,y);
			this.graphics.lineStyle(0.5, color,1);
        	this.graphics.lineTo(x+width, y);
        	this.graphics.lineTo(x+width, y+height);
        	this.graphics.lineTo(x, y+height);
        	this.graphics.lineTo(x,y);
			
        }
        
        private function drawPoint(x:int,y:int, color:uint):void
        {
        	this.graphics.lineStyle(9, VLMParams.white,1);
       		this.graphics.drawRect(x,y,3,3);
       		
       		this.graphics.beginFill(color,1);
       		this.graphics.lineStyle(7, color, 1);
       		this.graphics.drawRect(x,y,1.5, 1.5);
       		this.graphics.endFill();
        }
	}
}
