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

	/**
	 * This class extends the lightweight DownloadProgressBar class.  This class
	 * uses an embedded Flash 8 MovieClip symbol to show preloading.
	 * 
	 * @author jessewarden
	 * 
	 */	
	public class InitPreloader extends UIComponent
	{
		/**
		* The Flash 8 MovieClip embedded as a Class.
		*/		
	//	[Embed(source="../assets/flash/preloader_3.swf", symbol="MyCustomPreloader")]
	//	[Embed(source="../assets/flash/V.swf", symbol="MyCustomPreloader")]
	//	private var FlashPreloaderSymbol:Class;
		
		private var _preloader:VLMPreloader;
		private var clip:MovieClip;
		private var _backdrop:Canvas;
		
		public function InitPreloader()
		{
			super();
			
			// instantiate the Flash MovieClip, show it, and stop it.
			// Remember, AS2 is removed when you embed SWF's, 
			// even "stop();", so you have to call it manually if you embed.
			_preloader = new VLMPreloader();
			_backdrop = new Canvas();
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
			addChild(_backdrop);
			addChild(_preloader);
			
//			addChild(clip);
//			clip.gotoAndStop("start");
		}
		
		private function onAdded(e:Event):void
		{
			_preloader.stop();
			//cp.x = stage.stageWidth*0.5 - cp.width/2;
			//cp.y = stage.stageHeight*0.5; //- cp.height/2;
			_preloader.x = this.stage.stageWidth/2 - 448/2
			_preloader.y = this.stage.stageHeight/2 + _preloader.height/2;//this.stage.stageHeight/2 - 171/2
			
			_backdrop.width = this.stage.stageWidth;
			_backdrop.height = this.stage.stageHeight;
			
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			_backdrop.graphics.beginFill(VLMParams.white, 0.5);
			_backdrop.graphics.drawRect(0,0, this.stage.stageWidth, this.stage.stageHeight);
			_backdrop.graphics.endFill();
				
		}
		public function updateVideoLoadProgress(loadProgress:uint):void
		{
			if(loadProgress >=100)
			{
				_preloader.videoStatus_txt.text = "Loaded video";
			}
			else
			{
				_preloader.videoStatus_txt.text = "Loading video : " + loadProgress + "%";
			}
			//cp.preloaderFill_mc.scaleX = loadProgress/100;
			//		clip.preloader.gotoAndStop(loadProgress);
			//		clip.preloader.amount_txt.text = String(loadProgress) + "%";
		}
		
		public function updateXMLString(str:String):void
		{
			_preloader.xmlStatus_txt.text  = str;
		}
		
		public function updateXMLProgress(loadProgress:uint):void
		{
			if(loadProgress >=100)
			{
				_preloader.xmlStatus_txt.text = "Loaded annotations";
			}
			else
			{
				_preloader.xmlStatus_txt.text = "Loading annotations ...";
			}	
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
		
		/*
		public override function set preloader(preloader:Sprite):void 
        {                   
            preloader.addEventListener( ProgressEvent.PROGRESS , 	onSWFDownloadProgress );    
            preloader.addEventListener( Event.COMPLETE , 			onSWFDownloadComplete );
            preloader.addEventListener( FlexEvent.INIT_PROGRESS , 	onFlexInitProgress );
            preloader.addEventListener( FlexEvent.INIT_COMPLETE , 	onFlexInitComplete );
            
            centerPreloader();
        }
		
	
		
        private function centerPreloader():void
		{
			x = (stageWidth / 2) - (clip.width / 2);
			y = (stageHeight / 2) - (clip.height / 2);
		}
		
		
		private function onSWFDownloadProgress( event:ProgressEvent ):void
        {
        	var t:Number = event.bytesTotal;
        	var l:Number = event.bytesLoaded;
        	var p:Number = Math.round( (l / t) * 100);
			clip.preloader_mc.percent_txt.text = String(p);
        	//clip.preloader.gotoAndStop(p);
        	//clip.preloader.amount_txt.text = String(p) + "%";
        }
        
    
        private function onSWFDownloadComplete( event:Event ):void
        {
       		//clip.preloader.gotoAndStop(100);
        	//clip.preloader.amount_txt.text = "100%";
        }
        
  
        private function onFlexInitProgress( event:FlexEvent ):void
        {
        	clip.preloader.gotoAndStop(100);
        	clip.preloader.amount_txt.text = "Initializing...";
        }
 
        private function onFlexInitComplete( event:FlexEvent ):void 
        {
        	clip.addFrameScript(21, onDoneAnimating);
        	clip.gotoAndPlay("fade out");
        }
        
       
        private function onDoneAnimating():void
        {
        	clip.stop();
        	dispatchEvent( new Event( Event.COMPLETE ) );
        }
		*/
	}
}

