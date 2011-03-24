//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.videoplayer.controls
{
	import flash.events.MouseEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Button;
	import mx.controls.HSlider;
	import mx.controls.Menu;
	import mx.controls.Text;
	import mx.controls.sliderClasses.SliderThumb;
	import mx.core.UIComponent;
	import mx.events.MenuEvent;
	import mx.managers.PopUpManager;
	
	import vlm.components.videoplayer.controls.fxslider.LMProgressSliderEvent;
	import vlm.events.LMEvent;

	public class AnnotationSlider extends HSlider
	{	
		private var _highlightFrames:ArrayCollection;
		private var _keyFrames:Dictionary;
		private var _kfComponents:Array;
		
		private var _menu:Menu;
		private var _leftBracketSelected = true;
		public function AnnotationSlider()
		{
			super();
			_highlightFrames = new ArrayCollection();
			_keyFrames = new Dictionary();
			this.thumbCount = 2;
			this.setStyle("showTrackHighlight", true);
			this.setStyle("trackSkin", LMAnnotationSliderTrack);
        	this.sliderThumbClass = BracketThumb;
        	this._kfComponents = new Array();
        	this.allowTrackClick = false;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			this.setStyle("showTrackHighlight", true);
			this.setStyle("trackSkin", LMAnnotationSliderTrack);
        	this.sliderThumbClass = BracketThumb;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			this.getThumbAt(0).id = "0";
			this.getThumbAt(1).id = "1";
			var thumbLeft:SliderThumb = this.getThumbAt(0);
			thumbLeft.addEventListener(MouseEvent.ROLL_OVER, onMouseOverThumbLeft);
			var thumbRight:SliderThumb = this.getThumbAt(1);
			thumbRight.addEventListener(MouseEvent.ROLL_OVER, onMouseOverThumbRight);
		}
		
		private function onMouseOverThumbRight(evt:MouseEvent):void
		{
			trace("mouse over thumb!! (right)");
			
			
			if(!_menu)
			{
				var menuData:XML = new XML("<menuitem label=\"move to current time\"></menuitem>");
				
				_menu = Menu.createMenu(null, menuData);
				
				_menu.addEventListener(MenuEvent.ITEM_CLICK, onMenuClick);
				_menu.labelField = "@label";
			}
			this._leftBracketSelected = false;
			_menu.show(evt.stageX+10, evt.stageY+10);
			//var thumbMenu:ThumbMenu = PopUpManager.createPopUp(this, ThumbMenu) as ThumbMenu;
			
			//	thumbMenu.move(evt.stageX+10, evt.stageY+10)
		}
		

		private function onMouseOverThumbLeft(evt:MouseEvent):void
		{
			trace("mouse over thumb!! (left)");
		
			if(!_menu)
			{
				var menuData:XML = new XML("<menuitem label=\"move to playhead\"></menuitem>");
				
				_menu = Menu.createMenu(null, menuData);
				
				_menu.addEventListener(MenuEvent.ITEM_CLICK, onMenuClick);
				_menu.labelField = "@label";
			}
			_menu.show(evt.stageX, evt.stageY);
			//var thumbMenu:ThumbMenu = PopUpManager.createPopUp(this, ThumbMenu) as ThumbMenu;
			this._leftBracketSelected = true;
		//	thumbMenu.move(evt.stageX+10, evt.stageY+10)
		}
		
		private function onMenuClick(evt:MenuEvent):void
		{
			//bracket location change request
			
			var e:LMProgressSliderEvent;
			if(this._leftBracketSelected)
			{
				e = new LMProgressSliderEvent(LMProgressSliderEvent.LEFTBRACKETMOVETOPLAYHEADREQUEST);
			}
			else
			{
				e = new LMProgressSliderEvent(LMProgressSliderEvent.RIGHTBRACKETMOVETOPLAYHEADREQUEST);			
			}
			dispatchEvent(e);
		}
		
		public function get highlightFrames():ArrayCollection
		{
			return this._highlightFrames;
		}
		public function set highlightFrames(frames:ArrayCollection):void
		{
			this._highlightFrames = frames;
			
			for each (var s:UIComponent in _kfComponents)
			{
				this.removeChild(s);
			}	
			_kfComponents = new Array();
			_keyFrames = new Dictionary();
			
			for each (var frame:int in frames)
			{	
				//draw a sprite per keyframe
				var x:int  =  (frame - this.minimum) * this.width / (this.maximum - this.minimum);
				var kfUIComp:Button = new Button();
				var a:Array  = new Array();
				a.push(VLMParams.green);
				a.push(VLMParams.green);
				a.push(VLMParams.darkPink);
				a.push(VLMParams.darkPink);
				
				kfUIComp.setStyle("fillColors", a)
				
				kfUIComp.setActualSize(10,10);
				kfUIComp.setStyle("frontColor", VLMParams.green)
				kfUIComp.setStyle("themeColor", VLMParams.green)
				kfUIComp.setStyle("alpha", 1);
			
				kfUIComp.x = x;
				kfUIComp.y = -2;
				kfUIComp.useHandCursor = true;
				_keyFrames[kfUIComp] = frame;
				kfUIComp.addEventListener(MouseEvent.CLICK, onKfSprite);
				
				
				kfUIComp.toolTip ="seek to keyframe";
				this.addChild(kfUIComp);
				_kfComponents.push(kfUIComp);
				
			}
		}
		
		private function onKfSprite(evt:MouseEvent):void
		{
			//figure out which frame the clicked sprite is associated to
			var f:int = int(_keyFrames[evt.target]);
			
			//throw event to skip to the appropriate frame
			var e:LMEvent = new LMEvent(LMEvent.KEYFRAMESELECTED);
			e.frame = f;
			dispatchEvent(e);
		}
		
		
		
	}
}
