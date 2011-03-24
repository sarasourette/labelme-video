package vlm.skins
{
	import flash.display.*;
	import flash.filters.DropShadowFilter;
	import mx.core.EdgeMetrics;
	import mx.graphics.RectangularDropShadow;
	import mx.skins.RectangularBorder;
	import mx.containers.Panel;
	import flash.geom.*;
	import flash.events.MouseEvent;
	import flash.utils.Timer;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import mx.core.UIComponent;

	/**
	 *  The skin for a Callout.
	 */
	public class LMCalloutBorder extends RectangularBorder 
	{
	
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
	
		/**
		 *  Constructor.
		 */
		public var tipPoint:Point = new Point;

		/**
		 * The Callout border draws the callout's background based on the 
		 * direction assigned.  It also creates a hit area that's shape is
		 * determined by the borders aspect ratio.
		 */
		 
		public function LMCalloutBorder() 
		{
			super();
		}
		
		/**
		 *  @private
		 */
		 
		private function handleTimer(e:TimerEvent):void
		{
			trace("hit");
		}
		
		//----------------------------------
		//  borderMetrics
		//----------------------------------
	
		/**
		 *  @private
		 *  Storage for the borderMetrics property.
		 */
		private var _borderMetrics:EdgeMetrics;
		
		
		
		/**
		 *  @private
		 */
		override public function get borderMetrics():EdgeMetrics
		{		
			if (_borderMetrics)
				return _borderMetrics;
				
			var borderStyle:String = getStyle("borderStyle");
			var calloutOffsetX:Number = getStyle("calloutOffsetX");
			var calloutOffsetY:Number = getStyle("calloutOffsetY");
			
			switch (borderStyle)
			{	
				case "topRightCallout":
				{
	 				_borderMetrics = new EdgeMetrics(calloutOffsetX, 0, -calloutOffsetX, 0);
					break;
				}
	
	 			case "topLeftCallout":
				{
	 				_borderMetrics = new EdgeMetrics(0, 0, 0, 0);
					break;
				}			
				case "bottomLeftCallout":
				{
	 				_borderMetrics = new EdgeMetrics(0, calloutOffsetY, 0, -calloutOffsetY);
					break;
				}
					case "bottomRightCallout":
				{
	 				_borderMetrics = new EdgeMetrics(calloutOffsetX, calloutOffsetY, -calloutOffsetX, -calloutOffsetY);
					break;
				} 
						
					case "noCornerCallout":
				{
					_borderMetrics = new EdgeMetrics(0, 0, 0, 0);
					break;

				}
	 		}
			
			return _borderMetrics;
		}
	
		//--------------------------------------------------------------------------
		//
		//  Overridden methods
		//
		//--------------------------------------------------------------------------
		
		
		/**
		 *  @private
		 *  If borderStyle may have changed, clear the cached border metrics.
		 */
		override public function styleChanged(styleProp:String):void
		{
			if (styleProp == "borderStyle" ||
				styleProp == "calloutOffsetX" ||
				styleProp == "calloutOffsetY" ||
				styleProp == "calloutPointerWidth" ||
				styleProp == "showHitArea" ||
				styleProp == null)
			{
				_borderMetrics = null;
			}
			
			invalidateDisplayList();
		}
	
		/**
		 *  @private
		 *  Draw the background, border, and hitArea.
		 */
		override protected function updateDisplayList(w:Number, h:Number):void
		{	
			
			super.updateDisplayList(w, h);
			var backgroundGradientColors:Array = getStyle("backgroundGradientColors");
			var backgroundAlpha:Number= getStyle("backgroundAlpha");
			var borderStyle:String = getStyle("borderStyle");
			
			var calloutPointerWidth:Number = getStyle("calloutPointerWidth");
			var calloutOffsetX:Number = getStyle("calloutOffsetX");
			var calloutOffsetY:Number = getStyle("calloutOffsetY");
	
			var cornerRadius:Number = getStyle("cornerRadius");
			var dropShadowAlpha:Number = 1;
			
			
			//
			var fillType:String = GradientType.LINEAR;
	  		var colors:Array = backgroundGradientColors;
	  		var alphas:Array = [backgroundAlpha, backgroundAlpha];
	  		var ratios:Array = [0x00, 0x80];
	  		var matr:Matrix = new Matrix();
	  		matr.createGradientBox(w, h, Math.PI/2, 0, 0);
	 		var spreadMethod:String = SpreadMethod.PAD;
	  		
			
			var shadowAlpha:Number = 0.1;
			
			// hit area offset grows based on aspect 
			// ratio of callout
			

			var hitAreaOffset:int =( w/h * 2) + 1;
			
		
	
			var g:Graphics = graphics;
			g.clear();  
			
			filters = [];


			g.endFill();
	
			switch (borderStyle)
			{
	
				
				case "topRightCallout": 
				{

					// hit area
					g.beginFill(0xFF0000, 0);
					g.moveTo(calloutOffsetX - hitAreaOffset/4, 
							 -hitAreaOffset/4)
							 
					g.lineTo(w + hitAreaOffset,
							 -hitAreaOffset);
							 
					g.lineTo(w + hitAreaOffset,
							 h - calloutOffsetY + hitAreaOffset);		 
					
					g.lineTo(0,
							 h + calloutOffsetY );	
			 					
					g.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
								
					// border 	
					g.drawRoundRectComplex(calloutOffsetX,					
										   0,
										   w-calloutOffsetX,
									       h-calloutOffsetY,
									       cornerRadius,
										   cornerRadius,
										   0,
										   cornerRadius
										   ); 
	
					// topRight pointer 
	 				g.moveTo(calloutOffsetX, 
	 						 h-calloutOffsetY);
					
					g.lineTo(0, 
							 calloutOffsetY + h);
							 
					g.lineTo(calloutOffsetX + calloutPointerWidth, 
							 h-calloutOffsetY);
							 
					g.endFill(); 
					

					
					filters = [ new DropShadowFilter(2, 90, 0, dropShadowAlpha) ];
					
					tipPoint.x = 0;
					tipPoint.y = calloutOffsetY + h;			
					
					
					break;
					
				}
	
	 			case "topLeftCallout": 
				{


					// hit area
					g.beginFill(0xFF0000, 0);
					g.moveTo(0, 
							 -hitAreaOffset)
							 
					g.lineTo(w - calloutOffsetX,
							 0 );
							 
					g.lineTo(w + calloutOffsetX,
							 h + calloutOffsetY);		 
					
					g.lineTo(0,
							 h - calloutOffsetY + hitAreaOffset);	
					


					this.graphics.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
	
					// border 
	
					g.drawRoundRectComplex(0,					
										   0,
										   w-calloutOffsetX,
									       h-calloutOffsetY,
									       cornerRadius,
										   cornerRadius,
										   cornerRadius,
										   0
										   ); 
	
					// topLeft pointer 
	
	 				g.moveTo(w-calloutOffsetX, h-calloutOffsetY);
					g.lineTo(w + calloutOffsetX, h + calloutOffsetY); // tip
					g.lineTo(w - calloutOffsetX - calloutPointerWidth, h-calloutOffsetY);
					g.endFill(); 
					
					filters = [ new DropShadowFilter(2, 90, 0, dropShadowAlpha) ];
					
					tipPoint.x = w + calloutOffsetX;
					tipPoint.y = calloutOffsetY; 
					
					break;
					
				}
	
				case "bottomLeftCallout": 
				{

					// hit area
					g.beginFill(0xFF0000, 0);
					g.moveTo(0, 
							 calloutOffsetY - hitAreaOffset)
							 
					g.lineTo(w + calloutOffsetX,
							 0);
							 
					g.lineTo(w - calloutOffsetX,
							 h);		 
					
					g.lineTo(0,
							 h + hitAreaOffset);	


					g.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
	
					// border 
	
					g.drawRoundRectComplex(0,
										   calloutOffsetY,
										   w-calloutOffsetX,
									       h-calloutOffsetY,
									       cornerRadius,
										   0,
										   cornerRadius,
										   cornerRadius
										   ); 
	
					// bottomLeft pointer 
	
	 				g.moveTo(w - calloutPointerWidth- calloutOffsetX, calloutOffsetY);
					g.lineTo(w + calloutOffsetX, 0); // tip
					g.lineTo(w - calloutOffsetX, calloutOffsetY);
					g.endFill(); 
					
					filters = [ new DropShadowFilter(2, 90, 0, dropShadowAlpha) ];
					
					tipPoint.x = w + calloutOffsetX;
					tipPoint.y = 0; 
					
					break;
					
				}
				case "bottomRightCallout": 
				{


					// hit area
					g.beginFill(0xFF0000, 0);
					g.moveTo(0, 
							 0)
							 
					g.lineTo(w,
							 calloutOffsetY - hitAreaOffset);
							 
					g.lineTo(w,
							 h + hitAreaOffset);		 
					
					g.lineTo(calloutOffsetX,
							 h);	
					

					g.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
	
					// border 
					g.drawRoundRectComplex(calloutOffsetX,					
										   calloutOffsetY,
										   w-calloutOffsetX,
									       h-calloutOffsetY,
									       0,
										   cornerRadius,
										   cornerRadius,
										   cornerRadius
										   ); 
	
					// bottomRight pointer 
	
	 				g.moveTo(calloutOffsetX, calloutOffsetY);
					g.lineTo(0,0); // tip
					g.lineTo(calloutOffsetX + calloutPointerWidth, calloutOffsetY);
					g.endFill(); 
					
					filters = [ new DropShadowFilter(2, 90, 0, dropShadowAlpha) ];
					
					tipPoint.x = 0;
					tipPoint.y = 0; 
					
					break;
					
				} 
				
					
				case "noCornerCallout": 
				{
					
					
					// hit area
					g.beginFill(0xFF0000, 0);
					g.moveTo(0, 
						0)
					
					g.lineTo(w,
						calloutOffsetY - hitAreaOffset);
					
					g.lineTo(w,
						h + hitAreaOffset);		 
					
					g.lineTo(calloutOffsetX,
						h);	
					
					
					g.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
					
					// border 
					g.drawRoundRectComplex(calloutOffsetX,					
						calloutOffsetY,
						w-calloutOffsetX,
						h-calloutOffsetY,
						cornerRadius,
						cornerRadius,
						cornerRadius,
						cornerRadius
					); 
					
					
					filters = [ new DropShadowFilter(2, 90, 0, dropShadowAlpha) ];
					
					tipPoint.x = 0;
					tipPoint.y = 0; 
					
					break;
					
				} 
					

			}
		}
	}
}
