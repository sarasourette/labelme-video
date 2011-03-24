package vlm.skins { // Use unnamed package if this skin is not in its own package.
	// skins/CustomContainerBorderSkin.as
	
	// Import necessary classes here.
	import flash.display.Graphics;
	import mx.graphics.RectangularDropShadow;
	import mx.skins.RectangularBorder;
	
	public class RoundBorderSkin extends RectangularBorder {
		
		private var dropShadow:RectangularDropShadow;
		
		// Constructor.
		public function RoundBorderSkin() {
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, 
													  unscaledHeight:Number):void 
		{
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var cornerRadius:Number = getStyle("cornerRadius");
			var backgroundColor:int = getStyle("backgroundColor");
			var backgroundAlpha:Number = getStyle("backgroundAlpha");
			graphics.clear();
			
			// Background
			drawRoundRect(0, 0, unscaledWidth, unscaledHeight, 
				{tl: cornerRadius, tr:cornerRadius, bl: cornerRadius, br: cornerRadius}, 
				backgroundColor, backgroundAlpha);
			
			
			// Shadow
			if (!dropShadow)
				dropShadow = new RectangularDropShadow();
			
			dropShadow.distance = 8;
			dropShadow.angle = 45;
			dropShadow.color = 0;
			dropShadow.alpha = 0.4;
			dropShadow.tlRadius = cornerRadius;
			dropShadow.trRadius = cornerRadius;
			dropShadow.blRadius = cornerRadius;
			dropShadow.brRadius = cornerRadius;
			dropShadow.drawShadow(graphics, 0, 0, unscaledWidth, unscaledHeight);
		}
	}
}
