//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.videoplayer.controls
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.HSlider;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import vlm.events.LMEvent;
	
	public class LMAnnotationControlBar extends UIComponent
	{
		// display objects
		private var _slider:HSlider;
		private var _startFrameButton:Button;
		private var _endFrameButton:Button;
		private var _submitCutButton:Button;
		private var _startFrameTextInput:TextInput;
		private var _endFrameTextInput:TextInput;
		private var _allBox:VBox;
		private var _controlBox:HBox;
		private var _visualizationCanvas:Canvas;		
		
		private var _userAnnotations:Array;
		private var _startFrame:int;
		private var _endFrame: int;
		private var _sprites:Array;
		
		private var _objectId:int;
		
		public function LMAnnotationControlBar():void
		{
			super();
			_userAnnotations = new Array();
			_startFrame = 0;
			_endFrame = 0;
			_sprites = null;
			_objectId = -1;
		}
		
		public function set startFrame(sf:int):void
		{
			_startFrame = sf;
			_slider.minimum = sf;	
		}
		
		public function set objectId(i:int):void
		{
			_objectId = i;
		}
		
		public function get objectId():int
		{
			return _objectId;
		}
		
		public function get startFrame():int
		{
			return _startFrame;
		}
		
		public function set endFrame(ef:int):void
		{
			_endFrame = ef;	
			_slider.maximum = ef;
		}
		
		public function get endFrame():int
		{
			return _endFrame;
		}
				
		public function set userAnnot(ua:Array):void
		{
			_userAnnotations = ua;
		}
		
		public function updateCurrFrame(f:int):void
		{
			_slider.value = f;
		}
		
		public function setUserAnnotationInfo(ua:Array, color:uint):void
		{
			this.userAnnot = ua;
			
			_sprites = new Array();
			_visualizationCanvas.removeAllChildren();
			_visualizationCanvas.addChild(this._slider);
			//draw a sprite for each manual annotation
			for each (var frame:int in _userAnnotations)
			{
				var uic:UIComponent = new UIComponent();
				var cbs:ControlBarSprite = new ControlBarSprite(frame);
				cbs.graphics.lineStyle(7, color, 1);
				var x:int = Math.round((_slider.width * Number(frame - _startFrame)) / (_endFrame - _startFrame));
				var y:int = Math.round(_visualizationCanvas.height / 2); 
				cbs.graphics.moveTo(x,y);
				cbs.graphics.drawCircle(x, y, 5);
				uic.addChild(cbs);
				_sprites.push(cbs);
				this._visualizationCanvas.addChild(uic);
				//if there's any need for an event listener on click for this point. put it here
			}
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			_slider = new HSlider();
			
			_allBox = new VBox();
			_controlBox = new HBox();
			_visualizationCanvas = new Canvas();
			_allBox.addChild(_visualizationCanvas);
			_visualizationCanvas.addChild(_slider);
			_allBox.addChild(_controlBox);
			
			this.addChild(_allBox);
			
			//buttons and control box stuff
			_startFrameButton = new Button();
			_startFrameButton.label = "startFrame";
			_startFrameTextInput = new TextInput();
			
			_endFrameButton = new Button();
			_endFrameButton.label = "endFrame";
			_endFrameTextInput = new TextInput();
			_submitCutButton = new Button();
			_submitCutButton.label = "Submit cut"
			
			_controlBox.addChild(_startFrameTextInput);
			_controlBox.addChild(_startFrameButton);
			_controlBox.addChild(_endFrameTextInput);
			_controlBox.addChild(_endFrameButton);
			_controlBox.addChild(_submitCutButton);
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();	
			_allBox.width = this.unscaledWidth;
			_allBox.height = this.unscaledHeight;
		
			_visualizationCanvas.width = this.unscaledWidth-10;
			_visualizationCanvas.height = Math.round(this.unscaledHeight/2)-5;
			_slider.width = _visualizationCanvas.width;
			_slider.height = _visualizationCanvas.height;
			_slider.visible = true;
			_slider.x = 0;
			_slider.y = 0;
			_slider.minimum = _startFrame;
			_slider.maximum = _endFrame;
			
			_controlBox.width = this.unscaledWidth;
			_controlBox.height = _visualizationCanvas.height;
			_startFrameButton.width = 90;
			_startFrameButton.height = 20;
			_startFrameButton.addEventListener(MouseEvent.CLICK, onStartFrameButtonClick);
			
			_endFrameButton.width = 90;
			_endFrameButton.height = 20;
			_endFrameButton.addEventListener(MouseEvent.CLICK, onEndFrameButtonClick);
			
			_submitCutButton.width = 100;
			_submitCutButton.height = 20;
			_submitCutButton.addEventListener(MouseEvent.CLICK, onSubmitCutButtonClick);
			
			_startFrameTextInput.width = 20;
			_startFrameTextInput.height = 20;
			_endFrameTextInput.width = 20;
			_endFrameTextInput.height = 20;
		}	
		
		public function updateStartFrame(f:int):void
		{
			_startFrameTextInput.text = String(f);	
		}
		
		public function updateEndFrame(f:int):void
		{
			_endFrameTextInput.text = String(f);
		}
		
		private function onStartFrameButtonClick(evt:MouseEvent):void	
		{
			var e:LMEvent = new LMEvent(LMEvent.CURRENTFRAMEREQUEST);
			e.frameType = LMEvent.STARTFRAMETYPE;
			dispatchEvent(e);
		}
		
		private function onEndFrameButtonClick(evt:MouseEvent):void
		{
			var e:LMEvent = new LMEvent(LMEvent.CURRENTFRAMEREQUEST);
			e.frameType = LMEvent.ENDTFRAMETYPE;
			dispatchEvent(e);
		}
		
		private function onSubmitCutButtonClick(evt:MouseEvent):void
		{
			var e:LMEvent = new LMEvent(LMEvent.DELETEPOLYSOUTSIDERANGE);
			e.startFrame = int(_startFrameTextInput.text);
			e.endFrame = int(_endFrameTextInput.text);
			dispatchEvent(e);
		}
				
	}
}


import flash.display.Sprite;

class ControlBarSprite extends Sprite
{
	private var _frame:int;
	
	public function ControlBarSprite(f:int=1):void
	{
		_frame = f;	
	}
}
