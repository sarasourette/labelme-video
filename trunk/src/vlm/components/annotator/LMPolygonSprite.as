//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.annotator
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import mx.core.UIComponent;
	
	import vlm.core.LMPolygon;
	import vlm.core.PolygonSpriteState;
	import vlm.events.LMAnnotationEvent;
	import vlm.events.LMEvent;
	
	
	public class LMPolygonSprite extends UIComponent
	{	
		private var _rootSprite:Sprite;
		private var _highlightSprite:Sprite;
		private var _polygon:LMPolygon;
		private var _overlayBox:TransformationOverlayBox;
		
		private var _showingControlPoints:Boolean;
		private var _selectFunction:Function;
		private var _controlPoints:Array;
		private var _selected:Boolean;
		private var _overlayOn:Boolean;
		private var _highlighted:Boolean;
		private var _selectedPtId:int;
		
		//variables for scaling
		private var _anchorPT:Vector3D;
		private var _movingPT:Vector3D;
		private var _origX:Array;
		private var _origY:Array;
		
		private var _hovered:Boolean;
		private var _startX:int;
		private var _startY:int;
		private var _endX:int;
		private var _spriteState:String;
		
		private var _scaleX:Number;
		private var _scaleY:Number;
	
		//the radiuses of the control point (each control point has an outer circle in white and an inner one in a color)
	    private static var INNERRADIUS:int = 2;
		public static var OUTERRADIUS:int = 15;
        
		public function LMPolygonSprite(poly:LMPolygon,color:uint, spriteState:String)
		{
				
			this._polygon = poly;			
			this._showingControlPoints = false;
			this.lMPolygon.color = color;
			this._selectFunction = null;
			this._controlPoints = new Array();
			this._movingPT = new Vector3D();
			this._anchorPT = new Vector3D();
			this._scaleX = 1;
			this._scaleY = 1;
			this.draw(this._scaleX, this._scaleY);
			this._hovered = false;
			this._overlayOn = false;
			this._highlighted = false;
			this._spriteState = spriteState;
			this._overlayBox = new TransformationOverlayBox(this._spriteState);
			//set so that a hand appears when on mouse hover
			//this.useHandCursor = true;
			//this.buttonMode = true;
		}
		
		override protected function createChildren():void
		{
	
			this._overlayBox = new TransformationOverlayBox(this._spriteState);	
			this.addChild(_overlayBox);
			if(this._spriteState != PolygonSpriteState.VIEWONLY)
			{
				this._overlayBox.addEventListener(LMAnnotationEvent.RESIZEOBJECT, onOverlayBoxResize);
				this._overlayBox.addEventListener(LMAnnotationEvent.RESIZEOBJECTSTART, onOverlayBoxResizeStart);
				this._overlayBox.addEventListener(LMAnnotationEvent.RESIZEOBJECTEND, onOverlayBoxResizeEnd);
			//	this._overlayBox.addEventListener(MouseEvent.MOUSE_DOWN, onAnnotationDown);
			}
			
			this._rootSprite = new Sprite();
			this._highlightSprite = new Sprite();
			this.addChild(_highlightSprite);
			this.addChild(_rootSprite);
			this._rootSprite.addEventListener(MouseEvent.ROLL_OVER, onAnnotationHover);
			this._rootSprite.addEventListener(MouseEvent.ROLL_OUT, onAnnotationUnHover);
			this._rootSprite.addEventListener(MouseEvent.CLICK, onAnnotationClick);	
		
			if(this._spriteState != PolygonSpriteState.VIEWONLY)
			{
				this._rootSprite.addEventListener(MouseEvent.MOUSE_DOWN, onAnnotationDown);
			}
					this._rootSprite.useHandCursor = true;
				this._rootSprite.buttonMode = true;
		
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			updateTransfBoxProperties();
		}
		
	
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
    	{
    		super.updateDisplayList(unscaledWidth, unscaledHeight);
    		
    		var xMod:int  = 0;//this._rootSprite.x;
    		var yMod:int = 0;//this._rootSprite.y;
    		var alphaFill:Number =0;
			
    		//drawing the outline of the polygon color line
//    		trace("rootSprite point x" + xMod + "  y " + yMod);
			this._rootSprite.graphics.clear();
			this._rootSprite.graphics.lineStyle(5,VLMParams.white);
			this._highlightSprite.x = this._rootSprite.x;
			this._highlightSprite.y = this._rootSprite.y;
			
			this._highlightSprite.graphics.clear();
			
			var displayX:Number = this.lMPolygon.xArray[0] * this._scaleX -xMod;
			var displayY:Number = this.lMPolygon.yArray[0] * this._scaleY -yMod;
			
			if(this._highlighted)
				alphaFill=0.5;
			else
				alphaFill = 0;
			
			if(this.lMPolygon.xArray.length>0)
			{
				displayX = this.lMPolygon.xArray[0] * this._scaleX -xMod;
				displayY = this.lMPolygon.yArray[0] * this._scaleY -yMod;
				
				_rootSprite.graphics.moveTo(displayX, displayY);
				if(this._highlighted)
					_highlightSprite.graphics.moveTo(displayX, displayY);
			}
			//trace("on updatedisplaylist x[0] " + this.lMPolygon.objectId + ": " + lMPolygon.xArray[0]);
			this._highlightSprite.graphics.beginFill(this.lMPolygon.color, alphaFill);
	
			//color part
			this._rootSprite.graphics.lineStyle(4,this.lMPolygon.color);
			if(this.lMPolygon.xArray.length>0)
			{
				_rootSprite.graphics.moveTo(displayX, displayY);
				if(this._highlighted)
					_highlightSprite.graphics.moveTo(displayX, displayY);
			}
			
			for(var i:int = 0; i < this.lMPolygon.xArray.length; i++)
			{
				if(i < this.lMPolygon.xArray.length - 1)
				{
					displayX = this.lMPolygon.xArray[i+1]* this._scaleX - xMod;
					displayY = this.lMPolygon.yArray[i+1]* this._scaleY - yMod;
					_rootSprite.graphics.lineTo(displayX, displayY);	
					if(this._highlighted)			
						_highlightSprite.graphics.lineTo(displayX, displayY);
				}
			}
			if(this.lMPolygon.xArray.length >0) 	 
			{
				displayX = this.lMPolygon.xArray[0] * this._scaleX -xMod;
				displayY = this.lMPolygon.yArray[0] * this._scaleY -yMod;
				
				_rootSprite.graphics.lineTo(displayX, displayY);
				if(this._highlighted)
					_highlightSprite.graphics.lineTo(displayX, displayY);
			}
			if(this._overlayOn)
				this._overlayBox.visible = true
			else
				this._overlayBox.visible = false;
				
//			trace("sprite width " + unscaledWidth +  " and height " + unscaledHeight);
		}
		
	
		
		public function get lMPolygon():LMPolygon
		{
			return _polygon;
		}
		
		public function set lMPolygon(lmp:LMPolygon):void
		{
			if(this._polygon != lmp)
			{
				this._polygon = lmp;
				updateTransfBoxProperties();
			}
		}
		
		public function setDisplayToRealScale(scaleX:Number, scaleY:Number):void
		{
			this._scaleX = scaleX;
			this._scaleY = scaleY;
		}
		 
		public function draw(scaleX:Number, scaleY:Number):void
		{
			this._scaleX = scaleX; this._scaleY = scaleY;
			this.invalidateDisplayList();	
		}
		
		private function onAnnotationClick(event:MouseEvent):void
		{
			event.stopPropagation();	
			
			if(this._highlighted)
			{
				
				var evt:LMEvent = new LMEvent(LMEvent.POLYSELECTED);
				evt.selectedId = this._polygon.objectId;
				evt.startFrame = this._polygon.startFrame;
				evt.endFrame = this._polygon.endFrame;
				dispatchEvent(evt);
			}
			else
			{
				var e:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.SPRITECLICK);
				var pt:Point = this.localToGlobal(new Point(event.localX, event.localY));
				e._anchorX = pt.x
				e._anchorY = pt.y;
				dispatchEvent(e);
			}
		}
		
		public function onAnnotationUnHover(event:MouseEvent):void
		{
			this._highlighted = false;
			this.invalidateDisplayList();
		}
		
		public function onAnnotationHover(event:MouseEvent):void
		{
			this._highlighted = true;
			this.invalidateDisplayList();
			var e:LMEvent = new LMEvent(LMEvent.POLYHIGHLIGHTED);
			e.selectedId = this._polygon.objectId;
			e.startFrame = this._polygon.startFrame;
			e.endFrame = this._polygon.endFrame;
			trace("lmpolygonsprite highlighted: " + this.lMPolygon.objectId);
			dispatchEvent(e);
		}
		
		public function getDisplayPoint(idx:int):Point
		{
			var pt:Point = new Point(this.lMPolygon.xArray[idx] * this._scaleX, this.lMPolygon.yArray[idx] * this._scaleY);
			return pt;
		}
		
		public function get numPoints():int
		{
			return this.lMPolygon.xArray.length;
		}

		public function get color():uint
		{
			return this.lMPolygon.color;
		}
		
		public function getControlPointIds():Array
		{
			var a:Array = new Array(_controlPoints.length);
			for(var i:int = 0 ; i < _controlPoints.length; i++)
			{
				a[i] = ControlPointSprite(_controlPoints[i]).id;	
			}
			return a;
		}
		
		public function select(f:Function):void
		{	
			this._selectFunction = f;
			this._selected = true;
			this.invalidateDisplayList();
			this._overlayOn = true;
			var xMod:int = 0;//this._rootSprite.x;
			var yMod:int = 0;//this._rootSprite.y;
			
			if(!_showingControlPoints){
				_showingControlPoints = false;
				this._controlPoints = new Array();
							
				for(var i:int = 0; i< this.lMPolygon.xArray.length; i++)
				{	
					var displayX:Number = this.lMPolygon.xArray[i]*this._scaleX - xMod;
					var displayY:Number = this.lMPolygon.yArray[i]*this._scaleY - yMod;
					var d:ControlPointSprite = new ControlPointSprite(i);
					if(this._spriteState != PolygonSpriteState.VIEWONLY)
						d.addEventListener(MouseEvent.MOUSE_DOWN, onControlPointDown);
					
					if(_polygon.getLabeled(i))
					{
						d.graphics.lineStyle(7, VLMParams.white, 1);
						d.graphics.beginFill(VLMParams.white);
					
						d.graphics.drawCircle(displayX,displayY, 5);	
						d.graphics.endFill();
						d.graphics.lineStyle(7, VLMParams.darkPink, 1);
						d.graphics.beginFill(VLMParams.darkPink);
						d.graphics.drawCircle(displayX, displayY, 2);		
						d.graphics.endFill();			
					}
					else		
					{
						d.graphics.lineStyle(7, VLMParams.white, 1);
						d.graphics.beginFill(VLMParams.white);
						d.graphics.drawCircle(displayX, displayY, 5);	
						d.graphics.endFill()
						d.graphics.lineStyle(7, this.lMPolygon.color, 1);
						d.graphics.beginFill(this.lMPolygon.color);
						d.graphics.drawCircle(displayX, displayY, 2);	
						d.graphics.endFill()
					}
					this._rootSprite.addChild(d);
					this._controlPoints.push(d);
				}
			}
		}
		
		public function unhighlight():void
		{
			this._highlighted = false;
			this.invalidateDisplayList();
		}
		
		public function highlight():void
		{
			this._highlighted = true;
			this.invalidateDisplayList();
		}
		
		public function unselect():void
		{
			if(this._selected)
			{
				this._selected = false;
				this._overlayOn = false;
				this._overlayBox.visible = false;
				
				this.invalidateDisplayList();
				hideControlPoints();
			}		
		}
		
		private function hideControlPoints():void
		{
			while(this._rootSprite.numChildren >0)
			{
				var o:DisplayObject = this._rootSprite.getChildAt(0) as DisplayObject;
				o.removeEventListener(MouseEvent.MOUSE_DOWN, onControlPointDown);
				this._rootSprite.removeChild(o);
			}
		}
		
		//scaling block
		//step 1
		private function onOverlayBoxResizeStart(evt:LMAnnotationEvent):void
		{
			if(_selected)
			{
				evt.stopPropagation();
				
				var e:LMEvent = new LMEvent(LMEvent.POLYHOLD);
				e.selectedId = _polygon.objectId;
				dispatchEvent(e);
				//trace("scaling started");
			}
		}
		//step 2
		private function onOverlayBoxResize(e:LMAnnotationEvent):void
		{
			if(_selected)
			{
				//resize the points
				trace('anchor (x, y) ' + e._anchorX + ' , ' + e._anchorY);
				trace('orig (x, y) ' + e._oldX + ' , ' + e._oldY);
				trace('new (x, y) ' + e._newX + ' , ' + e._newY);
				if(e._rotating)
					this.rotatePolygon(e._anchorX, e._anchorY,  new  Vector3D(e._oldX,e._oldY), e._newX, e._newY);
				else
					scalePolygon(e._anchorX , e._anchorY , new  Vector3D(e._oldX,e._oldY), e._newX, e._newY);
				this.updateTransfBoxProperties();
				this.invalidateDisplayList();
				this.hideControlPoints();
				this._overlayOn = true;
				
				//trace("scaling in progress");
			}
		}
		//step 3
		private function onOverlayBoxResizeEnd(evt:LMAnnotationEvent):void
		{
			if(_selected)
			{
				var e:LMEvent = new LMEvent(LMEvent.POLYUNHOLD);
				e.selectedId = _polygon.objectId;
				//for (var i:int = 0 ; i< this.lMPolygon.xArray.length; i++)
				//{
				//	this._polygon.setLabeled(i, 1);	
				//}
				this._polygon.setLabeled(1);
					
				
				dispatchEvent(e);
				this.dispatchEvent(new LMAnnotationEvent(LMAnnotationEvent.POLYSCALE));	
				
				//trace("scaling ending");
				this.select(this._selectFunction);
				this.updateTransfBoxProperties();
				this.invalidateDisplayList();
				
				
			}
		}
		
		//translation block
		//step 1
		private function onAnnotationDown(event:MouseEvent):void
		{
			if(_selected)
			{
				var u:Sprite = Sprite(event.target);
				if(u)
					u.parent.setChildIndex(u, u.parent.numChildren-1)		
				event.stopPropagation();
				
				this.root.addEventListener(MouseEvent.MOUSE_MOVE, onAnnotationMove);
				this.root.addEventListener(MouseEvent.MOUSE_UP, onAnnotationUp);
				this._startX = event.stageX;
				this._startY = event.stageY;
			}
 		}
 		//step 2 translation
		private function onAnnotationMove(event:MouseEvent):void
		{
			if(_selected)
			{
				var dx:Number = event.stageX - this._startX;
				var dy:Number = event.stageY - this._startY;
				this._startX = event.stageX;
				this._startY = event.stageY;
				updateTranslatedPoints(dx, dy);
				this.hideControlPoints();
				
				this.updateTransfBoxProperties();
				trace("polygon moved dx, dy: " + dx + " , " + dy);
				this.invalidateDisplayList();
			}
		}
		//step 3  translation
		private function onAnnotationUp(event:MouseEvent):void
		{
			if(_selected)
			{
				this.root.removeEventListener(MouseEvent.MOUSE_MOVE, onAnnotationMove);
				this.root.removeEventListener(MouseEvent.MOUSE_UP, onAnnotationUp);
				
				/*for (var i:int = 0 ; i< this.lMPolygon.xArray.length; i++)
				{
					this._polygon.setLabeled(i, 1);	
				}*/
				this._polygon.setLabeled(1);
					
				this.select(this._selectFunction);
				this.invalidateDisplayList();
				this.dispatchEvent(new LMAnnotationEvent(LMAnnotationEvent.POLYTRANSLATE,true, false));
						
			}
			else
				trace("uh oh !!!!!!!!!");
		}
		
		//code to move a point
		//step 1
		private function onControlPointDown(event:MouseEvent):void
		{
			if(_selected)
			{
				var point:ControlPointSprite = event.target as ControlPointSprite;
				if(point)
					point.parent.setChildIndex(point, point.parent.numChildren-1)		
				event.stopPropagation();
				
				_selectedPtId = point.id;
				trace("control point down: " + event.stageX + " , " + event.stageY);
				this.root.addEventListener(MouseEvent.MOUSE_MOVE, onControlPointMove);
				this.root.addEventListener(MouseEvent.MOUSE_UP, onControlPointRelease);
				
				this._startX = event.stageX;
				this._startY = event.stageY;
				
				var nManuallyLabeled:int = this.lMPolygon.nManuallyLabeled();
				var e:LMEvent = new LMEvent(LMEvent.POLYHOLD);
				e.selectedId = _polygon.objectId;
				dispatchEvent(e);
				
			}
				
		}
		
		//step 2
		private function onControlPointMove(event:MouseEvent):void
		{	
			if(_selected)
			{
				
				var dx:Number = event.stageX - this._startX;
				var dy:Number = event.stageY - this._startY;
				trace("startx starty" + _startX + " , " + _startY);
				trace("control point moving: " + event.stageX + " , " + event.stageY + "( dx, dy ) "+ dx + "," +dy );
				
				this._startX = event.stageX;
				this._startY = event.stageY;

				this.lMPolygon.xArray[_selectedPtId]+= dx/ this._scaleX;
				this.lMPolygon.yArray[_selectedPtId]+= dy/ this._scaleY;
				
				this.hideControlPoints();
								
				this.updateTransfBoxProperties();
				
				this.invalidateDisplayList();
			}
		}
		
		
		
		
		
		//step 3
		private function onControlPointRelease(event:MouseEvent):void
		{
			if(_selected)
			{
				this.root.removeEventListener(MouseEvent.MOUSE_MOVE, onControlPointMove);
				this.root.removeEventListener(MouseEvent.MOUSE_UP, onControlPointRelease);
				
				this.dispatchEvent(new LMAnnotationEvent(LMAnnotationEvent.POINTCHANGE, true, false, _selectedPtId));
			
				var e:LMEvent = new LMEvent(LMEvent.POLYUNHOLD);
				e.selectedId = _polygon.objectId;
				dispatchEvent(e);
				this.updateTransfBoxProperties();
				trace("control point released");
				this._polygon.setLabeled(1);
					
				this.select(this._selectFunction);
				this.invalidateDisplayList();
		
			}
		}
		
		
		private function updateTransfBoxProperties():void
		{
			var xRange:Object = computeRange(this.lMPolygon.xArray, this._scaleX);
			var yRange:Object = computeRange(this.lMPolygon.yArray, this._scaleY);
			this._overlayBox.width = xRange.maxVal - xRange.minVal + OUTERRADIUS * 2;
			this._overlayBox.height = yRange.maxVal - yRange.minVal + OUTERRADIUS * 2;
			_overlayBox.x = xRange.minVal - OUTERRADIUS;
			_overlayBox.y = yRange.minVal - OUTERRADIUS;
		//	trace("root sprite x " + xRange.minVal + " root sprite y " + xRange.minVal);
		//	trace("overlay box x " + xRange.minVal + " overlayBox y " + xRange.minVal);
		}
		
		private function updateTranslatedPoints(dx:int, dy:int):void
		{
			for (var i:int = 0; i< this.lMPolygon.xArray.length; i++)
			{
			//	if(i == 0)
			//		trace("oldx: " + this.lMPolygon.xArray[i]+  ", dx: " + dx + " , " + " scaledx: " + dx/this._scaleX );
				this.lMPolygon.xArray[i] = Number(this.lMPolygon.xArray[i]) + Number(dx)/this._scaleX;
				this.lMPolygon.yArray[i] = Number(this.lMPolygon.yArray[i]) + Number(dy)/this._scaleY;
			//	if(i == 0)
			//		trace("new x: " +this.lMPolygon.xArray[i])
			}
			
		}
		private function computeRange(a:Array,scale:Number):Object
		{
            var min:int = int.MAX_VALUE;
            var max:int = int.MIN_VALUE;
            for each(var i:int in a)
            {       
				i = i*scale;
		        if(i < min)
 	               min = i;
	            if(i > max)
                   max = i;
            }
            
	    	return {"maxVal":max, "minVal":min}
        }
        
        //rotates the polygon based on the angle created by the new point, the old point, and an anchor point
        private function rotatePolygon(anchorX:int, anchorY:int, oldMovingPt:Vector3D,   newX:int, newY:int):void
        {
        	trace("rotating polygon");
			var newMovingPt:Vector3D = new Vector3D(newX, newY);
			
			var anchorPt:Vector3D = new Vector3D(anchorX, anchorY);
			var oldDist:Number = Vector3D.distance(anchorPt, oldMovingPt);
			var newDist:Number = Vector3D.distance(anchorPt, newMovingPt);
			
			var oldV:Vector3D = oldMovingPt.subtract(anchorPt);
			var newV:Vector3D = newMovingPt.subtract(anchorPt);
		
			var theta:Number = Vector3D.angleBetween(oldV, newV);
			var cross:Vector3D = oldV.crossProduct(newV);
			
			if(isNaN(theta))
				return;
				
			if(cross.z <0)
				theta = - theta;
			
			var r:Number = newDist/oldDist;
			
			var M:Matrix = new Matrix();
			M.identity();
			
			M.translate(-anchorX, -anchorY);
			M.rotate(theta);
			M.translate(anchorX, anchorY);
			 
			trace("rotating angle : " + theta);		 
			for(var i:int = 0; i < this.lMPolygon.xArray.length ; i ++ )
			{
				var pt:Point = this.localToGlobal(new Point(this.lMPolygon.xArray[i]*this._scaleX, this.lMPolygon.yArray[i]*this._scaleY));
				
				var newP:Point =  M.transformPoint(pt);
				trace("old real polygon point x[" + i+ "] " + this.lMPolygon.xArray[i] + "  y[" + i+ "] " + this.lMPolygon.yArray[i]);
				newP = this.globalToLocal(newP);
				this.lMPolygon.xArray[i] = newP.x / this._scaleX;
				this.lMPolygon.yArray[i] = newP.y / this._scaleY;
				
				trace("new real polygon point x[" + i+ "] " + this.lMPolygon.xArray[i] + "  y[" + i+ "] " + this.lMPolygon.yArray[i]);
			}					

        }
        
        //helper function for scaling
        private function scalePolygon(anchorX:int, anchorY:int, oldMovingPt:Vector3D,   newX:int, newY:int):void
		{
			var newMovingPt:Vector3D = new Vector3D(newX, newY);
			
			var anchorPt:Vector3D = new Vector3D(anchorX, anchorY);
			var oldDist:Number = Vector3D.distance(anchorPt, oldMovingPt);
			var newDist:Number = Vector3D.distance(anchorPt, newMovingPt);
			
			var oldV:Vector3D = oldMovingPt.subtract(anchorPt);
			var newV:Vector3D = newMovingPt.subtract(anchorPt);
		
			var M:Matrix = new Matrix();
			M.identity();
			
			var M1:Matrix = new Matrix();
			M1.translate(-anchorX, -anchorY);
			
			var M2:Matrix = new Matrix();
			
			var newDistX:Number = newX - anchorPt.x;// Vector3D.distance(new Vector3D(anchorPt.x), new Vector3D(newX));
			var oldDistX:Number = oldMovingPt.x - anchorPt.x; //Vector3D.distance(new Vector3D(anchorPt.x), new Vector3D(oldMovingPt.x));
			
			var rx:Number = newDistX/oldDistX ;
			
			var newDistY:Number = newY - anchorPt.y;//Vector3D.distance(new Vector3D(anchorPt.y), new Vector3D(newY));
			var oldDistY:Number = oldMovingPt.y - anchorPt.y;;
			var ry:Number = newDistY/ oldDistY;
			
			if(newDistX ==0 || newDistY==0||oldDistX ==0 || oldDistY==0)
				return;
				
			trace("rx : " + rx + " ry : " + ry);
			M2.scale(rx,ry);

			var M3:Matrix = new Matrix();
			M3.translate(anchorX, anchorY);

			M.concat(M1);
			M.concat(M2);
			M.concat(M3);
			 
						 
			for(var i:int = 0; i < this.lMPolygon.xArray.length ; i ++ )
			{
				var pt:Point = this.localToGlobal(new Point(this.lMPolygon.xArray[i]*this._scaleX, this.lMPolygon.yArray[i]*this._scaleY));
				
				var newP:Point =  M.transformPoint(pt);
			//	trace("old polygon point x[" + i+ "] " + this.lMPolygon.xArray[i] + "  y[" + i+ "] " + this.lMPolygon.yArray[i]);
				newP = this.globalToLocal(newP);
				this.lMPolygon.xArray[i] = newP.x/ this._scaleX;
				this.lMPolygon.yArray[i] = newP.y/ this._scaleY;
			//	trace("new polygon point x[" + i+ "] " + this.lMPolygon.xArray[i] + "  y[" + i+ "] " + this.lMPolygon.yArray[i]);
			}					
		}
        
        // not used functions
        
        private function polyTranslate(event:MouseEvent):void
		{
			var p:ControlPointSprite = event.target as ControlPointSprite;
			
			for(var i:int = 0 ; i< _controlPoints.length; i++)
			{
				ControlPointSprite(_controlPoints[i]).startDrag();
			}			
			//thisis just a local fix... figure out why those control points aren't moving
			p.startDrag();
			var dx:Number = p.parent.mouseX - this.lMPolygon.xArray[p.id]*this._scaleX;
			var dy:Number = p.parent.mouseY - this.lMPolygon.yArray[p.id]*this._scaleY;
			
			for(var i:int = 0; i< this.lMPolygon.xArray.length; i++)
			{
				this.lMPolygon.xArray[i] = this.lMPolygon.xArray[i] + dx/this._scaleX;
				this.lMPolygon.yArray[i] = this.lMPolygon.yArray[i] + dy/this._scaleY;
			}
			this.lMPolygon.xArray[p.id] = p.parent.mouseX/this._scaleX;
			this.lMPolygon.yArray[p.id] = p.parent.mouseY/this._scaleY;
		
			this.removeEventListener(LMEvent.POLYSELECTED, this._selectFunction);
			this.addEventListener(MouseEvent.MOUSE_UP, onPolyRelease);
			this.draw(_scaleX, _scaleY);
		}
		
		private function onPolyRelease(event:MouseEvent):void
		{
			var p:ControlPointSprite = event.target as ControlPointSprite;
			
		
			this._rootSprite.stopDrag();
			//todo change this to create a new annotation event
			this.removeEventListener(MouseEvent.MOUSE_MOVE, polyTranslate);	
			this._polygon.setLabeled(1);
				
			this.dispatchEvent(new LMAnnotationEvent(LMAnnotationEvent.POLYTRANSLATE, true, false, null));
			var e:LMEvent = new LMEvent(LMEvent.POLYHOLD);
			e.selectedId = _polygon.objectId;
			dispatchEvent(e);
		}
		
		private function polyScale(event:MouseEvent):void
		{
			
			for(var i:int = 0 ; i< _controlPoints.length; i++)
			{
				ControlPointSprite(_controlPoints[i]).startDrag();
			}			
			
			//figure out which one is the  moving point
			var p:ControlPointSprite = event.target as ControlPointSprite;
			p.startDrag();
			
			//no need to change this function.. Scaling the scaled version is the same		
			this.polygonScale(0, new Vector3D(this.lMPolygon.xArray[p.id], this.lMPolygon.yArray[p.id]),  p.parent.mouseX, p.parent.mouseY);
			this.draw(_scaleX, _scaleY);
			this.removeEventListener(LMEvent.POLYSELECTED, this._selectFunction);
			this.addEventListener(MouseEvent.MOUSE_UP, onControlPointRelease);
			this.addEventListener(MouseEvent.MOUSE_OUT, onControlPointRelease);
			
		}
				
		public function polySpriteHitTest(pt:Point):Boolean
		{
			return this._rootSprite.hitTestPoint(pt.x, pt.y,true);
		}
		
		private function polygonScale(anchorIdx:int, oldMovingPt:Vector3D,   newX:int, newY:int):void
		{
			var newMovingPt:Vector3D = new Vector3D(newX, newY);
			
			var anchorPt:Vector3D = new Vector3D(this._origX[anchorIdx], this._origY[anchorIdx]);
			var oldDist:Number = Vector3D.distance(anchorPt, oldMovingPt);
			var newDist:Number = Vector3D.distance(anchorPt, newMovingPt);
			
			var oldV:Vector3D = oldMovingPt.subtract(anchorPt);
			var newV:Vector3D = newMovingPt.subtract(anchorPt);
		
			var theta:Number = Vector3D.angleBetween(oldV, newV);
			var cross:Vector3D = oldV.crossProduct(newV);
			
			if(cross.z <0)
				theta = - theta;
			var r:Number = newDist/oldDist;
			
			var M:Matrix = new Matrix();
			M.identity();
			
			var M1:Matrix = new Matrix();
			M1.translate(-this._origX[anchorIdx], -this._origY[anchorIdx]);
			
			var M2:Matrix = new Matrix();
			M2.rotate(theta);
			M2.scale(r, r);
			var M3:Matrix = new Matrix();
			M3.translate(this._origX[anchorIdx], this._origY[anchorIdx]);

			M.concat(M1);
			M.concat(M2);
			M.concat(M3);
			 
			for(var i:int = 0; i < this.lMPolygon.xArray.length ; i ++ )
			{
				var newP:Point =  M.transformPoint((new Point(this.lMPolygon.xArray[i], this.lMPolygon.yArray[i])));
				
				this.lMPolygon.xArray[i] = newP.x;
				this.lMPolygon.yArray[i] = newP.y;
			}			
		}
		

	}
}

import flash.display.Sprite;
import mx.controls.ToolTip;
import flash.events.MouseEvent;
import mx.core.UIComponent;

class ControlPointSprite extends Sprite
{	
	private var _id:int;

	public function ControlPointSprite(id:int)
	{
		this._id = id;
	}

	public function get id():int
	{
		return _id;
	}
	
	public function set id(i:int):void
	{
		_id = id;
	}
	
}
