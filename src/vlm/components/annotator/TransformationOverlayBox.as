//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.annotator
{
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.containers.VBox;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import vlm.core.PolygonSpriteState;
	import vlm.events.LMAnnotationEvent;
	import vlm.skins.TransformationOverlay;

 //this import statement should appear be last
	
	
	public class TransformationOverlayBox extends VBox
	{
		use namespace mx_internal; //tells Actionscript that mx_internal is a namespace 
       
       	//the 4 corners of the box
       	private var _points:Array;
       	private var _x:Array;
       	private var _y:Array;
       	
       	//scaling variables
       	private var _oldX:int;
       	private var _oldY:int;
       	
       	private var _selectedPoint:UIComponent;
        private var color:uint = VLMParams.lightBlue;       
		
		private var _spriteState:String;
		
		public function TransformationOverlayBox(spriteState:String)
		{
			super();
			_points = new Array();	
			_x = new Array();
			_y = new Array();
			
			_selectedPoint = null;
			_oldX = 0;
			_oldX = 0;
		
			if(!getStyle("borderSkin"))
				setStyle("borderSkin", TransformationOverlay);
			
			//border = new TransformationOverlay();
			if(!getStyle("backgroundColor"))
				setStyle("backgroundColor", VLMParams.white);
			
			if(!getStyle("backgroundAlpha"))
				setStyle("backgroundAlpha", 0);    
			
			if(!getStyle("cornerRadius"))
				setStyle("cornerRadius", 14);	
			
			_spriteState = spriteState;
		
		}
			
		override protected function commitProperties():void
		{
			super.commitProperties();
		
		}
		
		override protected function createChildren():void
		{	
			super.createChildren();
			
			//create a point per corner (for the resizing controls)
			var p:UIComponent = makeResizeCtrlPoint(0,0,color);
			this.addChild(p);
			_points.push(p);
			p.id = "topleft";
			if(this._spriteState != PolygonSpriteState.VIEWONLY)
				p.addEventListener(MouseEvent.MOUSE_DOWN, onCtrlPointDown);
			
			this.addEventListener(MouseEvent.CLICK, onClick);
			p = makeResizeCtrlPoint(0, 0, color);
			this.addChild(p);
			_points.push(p);
			p.id = "topright";
			if(this._spriteState != PolygonSpriteState.VIEWONLY)
				p.addEventListener(MouseEvent.MOUSE_DOWN, onCtrlPointDown);
						
			p = makeResizeCtrlPoint(0,0, color);
			this.addChild(p);
			_points.push(p);
			p.id = "bottomright";
			if(this._spriteState != PolygonSpriteState.VIEWONLY)		
				p.addEventListener(MouseEvent.MOUSE_DOWN, onCtrlPointDown);
			
			p = makeResizeCtrlPoint(0, 0, color);
			this.addChild(p);
			_points.push(p);
			p.id = "bottomleft";
			if(this._spriteState != PolygonSpriteState.VIEWONLY)
				p.addEventListener(MouseEvent.MOUSE_DOWN, onCtrlPointDown);
			
			//create a point at the top center for the rotation control
			p = makeRotationCtrlPoint(0,-50,color);
			this.addChild(p);
			_points.push(p);
			p.id = "rotationCtrl";
			if(this._spriteState != PolygonSpriteState.VIEWONLY)		
				p.addEventListener(MouseEvent.MOUSE_DOWN, onCtrlPointDown);
		}
	
		private function onClick(evt:MouseEvent):void
		{
			evt.stopPropagation();	
		}
		private function onCtrlPointDown(evt:MouseEvent):void
		{
			var u:UIComponent = UIComponent(evt.target);
			if(u)
				u.parent.setChildIndex(u, u.parent.numChildren-1)		
			evt.stopPropagation();
			this._selectedPoint = u;
			trace(u.id);
			
			if(u.id == "rotationCtrl")
				this.root.addEventListener(MouseEvent.MOUSE_MOVE, onRotate);
			else
				this.root.addEventListener(MouseEvent.MOUSE_MOVE, onCtrlPointMove);
			
			this._oldX = evt.stageX;
			this._oldY = evt.stageY;
			
			var e:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.RESIZEOBJECTSTART);
			dispatchEvent(e);
		}		
		
		private function onRotate(evt:MouseEvent):void
		{
			// the center of the bounding box is the anchor
			var anchorPt:Point;
			anchorPt = new Point(this.width/2, this.height/2);
			anchorPt = this.localToGlobal(anchorPt);
			
			//create the resize event
			var e:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.RESIZEOBJECT);
			
			e._oldX = this._oldX;
			e._oldY = this._oldY;
			e._newX = evt.stageX;
			e._newY = evt.stageY;
			e._anchorX = anchorPt.x;
			e._anchorY = anchorPt.y;
			e._rotating = true;
			
			this._oldX = evt.stageX;
			this._oldY = evt.stageY;
			this.invalidateDisplayList();
			
			_points[4].removeEventListener(MouseEvent.MOUSE_DOWN, onCtrlPointDown);
			
			this.root.addEventListener(MouseEvent.MOUSE_UP, onRotateCtrlPointUp);
			
			dispatchEvent(e);
				
		}
		
		private function onCtrlPointMove(evt:MouseEvent):void
		{
			var p:UIComponent = _selectedPoint;
			
			if(p.id != "rotationCtrl")
				p.startDrag();
			
			var w:int = -1;
			var h:int = -1;
			var anchorPt:Point;
			var o:Point;
		
			var e:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.RESIZEOBJECT);
		
			switch (p.id)
			{
				case "bottomright"://bottom right corner
					//the origin point is the top left corner
					o = this.localToGlobal(new Point(0,0))
					w = -o.x + evt.stageX;
					h = -o.y + evt.stageY;
					
					//the top left corner is the anchor
					anchorPt = new Point(0,0);
					anchorPt = this.localToGlobal(anchorPt);
					//consider the inner bounding box
					anchorPt.x = anchorPt.x + LMPolygonSprite.OUTERRADIUS;
					anchorPt.y = anchorPt.y + LMPolygonSprite.OUTERRADIUS;
					break;
					
				case "topleft":
					//the anchor/origin point is the bottom right corner
					o = this.localToGlobal(new Point(this.width,this.height))
					w = o.x - evt.stageX;
					h = o.y - evt.stageY;
					
					//the bottom right corner is the anchor
					anchorPt = new Point(this.width,this.height);
					anchorPt = this.localToGlobal(anchorPt);
					
					//move the box the amount the top left corner was moved 
					var topLeftCoords:Point = this.parent.globalToLocal(new Point(evt.stageX, evt.stageY));
					this.x = topLeftCoords.x;
					this.y = topLeftCoords.y;
			
					anchorPt.x = anchorPt.x - LMPolygonSprite.OUTERRADIUS;
					anchorPt.y = anchorPt.y - LMPolygonSprite.OUTERRADIUS;
				
					break;
				case "topright":
					//the anchor/origin point is the bottom left corner
					o = this.localToGlobal(new Point(0,this.height))
					w = -o.x + evt.stageX;
					h = o.y - evt.stageY;
					
					//the bottom left corner is the anchor
					anchorPt = new Point(0,this.height);
					anchorPt = this.localToGlobal(anchorPt);
					
					//move the box the y amount the top right corner was moved 
					// the 0 is a dummy variable
					var topRightCoords:Point = this.parent.globalToLocal(new Point(0, evt.stageY));
					this.y = topRightCoords.y;
	
					anchorPt.x = anchorPt.x + LMPolygonSprite.OUTERRADIUS;
					anchorPt.y = anchorPt.y - LMPolygonSprite.OUTERRADIUS;
					break;
					
				case "bottomleft":
					//the anchor/origin point is the top right corner
					o = this.localToGlobal(new Point(this.width,0))
					w = o.x - evt.stageX;
					h = -o.y + evt.stageY;
					
					// top right chorner is the anchor
					anchorPt = new Point(this.width, 0);
					anchorPt = this.localToGlobal(anchorPt);
					
					//move the box the y amount the top left corner was moved 
					//the 0 is a dummy variable
					var topLeftCoords:Point = this.parent.globalToLocal(new Point(evt.stageX, 0));
					this.x = topLeftCoords.x;
					anchorPt.x = anchorPt.x - LMPolygonSprite.OUTERRADIUS;
					anchorPt.y = anchorPt.y + LMPolygonSprite.OUTERRADIUS;
					break;		
				
				default: 
					return;
			}
			trace("orig.x " + o.x + " orig.y " + o.y);
			trace("mouse.x " + evt.stageX + " orig.y " + evt.stageY);
			trace("moving " + p.id + "  w: " + w + " h:  " + h);	
			
			//resize this box 
			this.setActualSize(w,h);
			p.removeEventListener(MouseEvent.MOUSE_DOWN, onCtrlPointDown);
			this.root.addEventListener(MouseEvent.MOUSE_UP, onCtrlPointUp);
			
			e._oldX = this._oldX;
			e._oldY = this._oldY;
			e._newX = evt.stageX;
			e._newY = evt.stageY;
			e._anchorX = anchorPt.x;
			e._anchorY = anchorPt.y;
			
			this._oldX = evt.stageX;
			this._oldY = evt.stageY;
			this.invalidateDisplayList();
			trace("old(x,y): " + e._oldX + " , " + e._oldY );
			trace("new(x,y): " + e._newX + " , " + e._newY );
			trace("anchor(x,y): " + e._anchorX + " , " + e._anchorY );
			
			dispatchEvent(e);
		}
	
		private function onRotateCtrlPointUp(evt:MouseEvent):void
		{
			var p:UIComponent = _selectedPoint;
			evt.stopPropagation();
			_points[4].addEventListener(MouseEvent.MOUSE_DOWN, onCtrlPointDown);
			
			this.root.removeEventListener(MouseEvent.MOUSE_UP, onRotateCtrlPointUp);
			this.root.removeEventListener(MouseEvent.MOUSE_MOVE, onRotate);
			_selectedPoint = null;
			var e:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.RESIZEOBJECTEND);
			dispatchEvent(e);
			
		}
		
		private function onCtrlPointUp(evt:MouseEvent):void
		{
			var p:UIComponent = _selectedPoint;
			evt.stopPropagation();
			if(p)
			{
				p.addEventListener(MouseEvent.MOUSE_DOWN, onCtrlPointDown);
				p.stopDrag();
			}
			
			this.root.removeEventListener(MouseEvent.MOUSE_MOVE, onCtrlPointMove);
			this.root.removeEventListener(MouseEvent.MOUSE_UP, onCtrlPointUp);
			_selectedPoint = null;
			var e:LMAnnotationEvent = new LMAnnotationEvent(LMAnnotationEvent.RESIZEOBJECTEND);
			dispatchEvent(e);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			//place each control point in a corner of the box
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var p:UIComponent = UIComponent(_points[0]);
			p.x =0; p.y = 0;
			
			p = UIComponent(_points[1]);
			p.x = unscaledWidth; p.y=0;
			
			p = UIComponent(_points[2]);
			p.x = unscaledWidth; p.y=unscaledHeight;
			
			p = UIComponent(_points[3]);
			p.x = 0; p.y=unscaledHeight;
			
			//place the rotation control point in the center top
			p = UIComponent(_points[4]);
			//we don't set the y component here because the bounding box gets messed up. The point was created at the right y coordinate
			p.x = this.width/2;			
		}
		
		//makes the controller for the rotation function
		private function makeRotationCtrlPoint(x:int, y:int, color:uint):UIComponent
		{
			//the radius of the point, the white component
        	var r:int = 5;
        	var u:UIComponent = new UIComponent();
        	u.graphics.beginFill(0xFFFF,1);   		
        	u.graphics.lineStyle(9, VLMParams.white,1);
       		u.graphics.drawCircle(x, y, r);
       		u.graphics.endFill();
       		
       		r = 2;
       		u.graphics.beginFill(color,1);
       		u.graphics.lineStyle(7, color, 1);
       		u.graphics.drawRect(x-r,y-r,r*2, r*2);
       		u.graphics.endFill();
       		
       		u.toolTip = "rotate";
       		u.buttonMode = true;
       		u.useHandCursor = true;
       		return u;
		}
		
		private function makeResizeCtrlPoint(x:int,y:int, color:uint):UIComponent
        {
        	//the radius of the point, the white component
        	var r:int = 6;
        	var u:UIComponent = new UIComponent();
        	u.graphics.beginFill(VLMParams.white,1);   		
        	u.graphics.lineStyle(9, VLMParams.white,1);
       		u.graphics.drawRect(x-r,y-r,r*2,r*2);
       		u.graphics.endFill();
       		
       		r = 2;
       		u.graphics.beginFill(color,1);
       		u.graphics.lineStyle(7, color, 1);
       		u.graphics.drawRect(x-r,y-r,r*2, r*2);
       		u.graphics.endFill();
       		
       		u.toolTip = "scale";
       		u.buttonMode = true;
       		u.useHandCursor = true;
       		return u;
        }
		
	}
}
