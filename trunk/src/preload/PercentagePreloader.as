//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package preload
{
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.preloaders.DownloadProgressBar;
	

	public class PercentagePreloader extends UIComponent
	{
		private var _percentPreloader:VLMPercentPreloader;
		private var _backdrop:Canvas;
	
		public function PercentagePreloader()
		{
			super();
			_percentPreloader = new VLMPercentPreloader();
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
			_backdrop = new Canvas();
			addChild(_backdrop);
			addChild(_percentPreloader);
			
		}
		private function onAdded(e:Event):void
		{
			//this.close();
			_percentPreloader.stop();
			_percentPreloader.x = this.stage.stageWidth/2 - 448/2
			_percentPreloader.y = this.stage.stageHeight/2 + _percentPreloader.height/2;//this.stage.stageHeight/2 - 171/2
			_backdrop.width = this.stage.stageWidth;
			_backdrop.height = this.stage.stageHeight;
		}
		
		public function updateMessageTop(str:String):void
		{
			_percentPreloader.bar1_txt.text = str;	
		}
		
		public function updatePercentTop(percent:uint):void
		{
			_percentPreloader.fillerBar1_mc.scaleX = percent/100;
			//_percentPreloader.bar1_txt.text = prefix + " " + percent + "%";
		}
		
		public function updateMessageBottom(str:String):void
		{
			_percentPreloader.bar2_txt.text = str;	
		}
		
		public function updatePercentBottom(percent:uint):void
		{
			_percentPreloader.fillerBar2_mc.scaleX = percent/100;
			_backdrop.graphics.beginFill(VLMParams.white, 0.5);
			_backdrop.graphics.drawRect(0,0, this.stage.stageWidth, this.stage.stageHeight);
			_backdrop.graphics.endFill();
			
		//	_percentPreloader.bar2_txt.text = prefix + " " + percent + "%";
		}

		public function show():void
		{
			if(!this.visible)
				this.visible = true;
		}
		public function close():void
		{
			if(this.visible)
				this.visible = false;
			//		this.close();
			trace("closing preloader");
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			_backdrop.graphics.beginFill(VLMParams.white, 0.5);
			_backdrop.graphics.drawRect(0,0, this.stage.stageWidth, this.stage.stageHeight);
			_backdrop.graphics.endFill();
		}

	}
}
