
package vlm.components.videoplayer.controls
{
import assets.SeekToStartButton;

import flash.events.ContextMenuEvent;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.ProgressEvent;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuBuiltInItems;
import flash.ui.ContextMenuItem;
import flash.ui.Keyboard;

import mx.collections.ArrayCollection;
import mx.containers.Canvas;
import mx.controls.VideoDisplay;
import mx.core.UIComponent;
import mx.events.MetadataEvent;
import mx.events.SliderEvent;
import mx.events.VideoEvent;
import mx.managers.IFocusManagerComponent;


import vlm.components.videoplayer.controls.fxslider.LMProgressSliderEvent;
import vlm.components.videoplayer.controls.fxvideo.FastForwardButton;
import vlm.components.videoplayer.controls.fxvideo.FrameChangeEvent;
import vlm.components.videoplayer.controls.fxvideo.NextKFButton;
import vlm.components.videoplayer.controls.fxvideo.PlayPauseButton;
import vlm.components.videoplayer.controls.fxvideo.PrevKFButton;
import vlm.components.videoplayer.controls.fxvideo.RewindButton;
import vlm.components.videoplayer.controls.fxvideo.SeekToEndButton;
import vlm.components.videoplayer.controls.fxvideo.SubmitCutButton;
import vlm.events.LMEvent;
import vlm.components.VideoLabelMe;

/**
 *  The color of the control bar. 
 *  
 *  @default 0x555555
 */

[Style(name="backColor", type="uint", format="Color", inherit="no")]

/**
 *  The color of the buttons on the control bar. 
 *  
 *  @default 0xeeeeee
 */

[Style(name="frontColor", type="uint", format="Color", inherit="no")]

/**
 *  The height of the control bar. Odd values look better. 
 *  
 *  @default 21
 */

[Style(name="controlBarHeight", type="Number", inherit="no")]

/**
 *  The name of the font used in the timer.
 *
 *  @default "Verdana"
 */
[Style(name="timerFontName", type="String", inherit="no")]

/**
 *  The size of the font used in the timer. 
 *  
 *  @default 9
 */

[Style(name="timerFontSize", type="Number", inherit="no")]

/**
 *  The FXVideo control lets you play an FLV file in a Flex application. 
 *  It supports progressive download over HTTP, streaming from the Flash Media
 *  Server, and streaming from a Camera object.
 * 
 *  @mxml
 *
 *  <p>The <code>&lt;controls:FXVideo&gt;</code> tag inherits all the tag
 *  attributes of its superclass, and adds the following tag attributes:</p>
 *
 *  <pre>
 *  &lt;controls:FXVideo
 *    
 *    <b>Styles</b>
 *    backColor="0x555555"
 *    frontColor="0xeeeeee"
 *    controlBarHeight="21"
 *    timerFontName="Verdana"
 *    timerFontSize="9"
 *
 *  /&gt;
 *  </pre>
 *
 */

public class FXVideo extends VideoDisplay implements IFocusManagerComponent
{
	
	/**
     *  Constructor.
     */
	
	public function FXVideo() 
	{
		super();
	
		textFormat = new TextFormat();
		
		var newContextMenu:ContextMenu;
		newContextMenu = new ContextMenu();
		
		newContextMenu.hideBuiltInItems();
        var defaultItems:ContextMenuBuiltInItems = newContextMenu.builtInItems;
        defaultItems.print = true;
		
		var item:ContextMenuItem = new ContextMenuItem("About FX Video Player");
		item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onMenuItemSelect);
		newContextMenu.customItems.push(item);
		
        contextMenu = newContextMenu;
        this.thumbHookedToPlayhead = true;
        
        this.autoRewind = false;
        
        //keep 0 volume for copyright issues
        this.volume = 0;
	}
	
	private var textFormat:TextFormat;
	private var thumbHookedToPlayhead:Boolean = true;
	private var loadProgress:Number = 0;
	private var flo:Boolean = true;
	
	/** display objects */
	
	private var controlBar:UIComponent;
	private var box:Canvas;
	private var playheadSlider:FXProgressSlider;
	private var videoArea:UIComponent;
	private var ppButton:PlayPauseButton;
	private var fastForwardButton:FastForwardButton;

	private var nextKFButton:NextKFButton;
	private var seekToEndButton:SeekToEndButton;
	private var rewindButton:RewindButton;
	private var prevKFButton:PrevKFButton;
	private var seekToBeginningButton:SeekToStartButton;
	private var timerTextField:TextField;
	private var frameNumDisplay:TextField;
	private var progressDisplay:TextField;
	private var xField:TextField;
	private var yField:TextField;
	private var annotationCutButton:SubmitCutButton;
	
	/** style */
	
	private var _frontColor:uint;
	private var _backColor:uint;
	private var _controlBarHeight:uint;
	private var _timerFontName:String;
	private var _timerFontSize:Number;
	
	
	/** video properties */
	private var frameRate:Number = 30.0;
	private static var step:Number = 10;
	
	
	/**
     *  @private
     */
	
	public function get fps():Number
	{
		return frameRate;
	}
	
	public function setAnnotationSlider(min:int, max:int):void
	{
		playheadSlider.setAnnotationSlider(min, max);
	}
	
	//where the brackets are located in the slider
	public function setLeftBrightBracketBoundaries(left:int, right:int):void
	{
		playheadSlider.setLeftBrightBracketBoundaries(left, right);
	}
	public function setLeftBracketBoundary(left:int):void
	{
		playheadSlider.moveLeftBracket(left);
	}
	public function setRightBracketBoundary(right:int):void
	{
		playheadSlider.moveRightBracket(right);
	}
	private var _playPressed:Boolean;
	
	private function set playPressed(value:Boolean):void
	{
		_playPressed = value;
		
		(value) ? ppButton.state = "pause" : ppButton.state = "play"
	}
	
	private function get playPressed():Boolean
	{
		return _playPressed;
	}
	
	/**
	 * Creates any child components of the component. For example, the
	 * ComboBox control contains a TextInput control and a Button control
	 * as child components.
	 */
	
	override protected function createChildren():void
	{
		super.createChildren();
		
		// sets default values for styles
		
		_frontColor = getStyle("frontColor");
		if(getStyle("frontColor") == undefined)
			_frontColor = 0;
		
		_backColor = getStyle("backColor");
		if(getStyle("backColor") == undefined)
			_backColor = VLMParams.gray;
		
		_controlBarHeight = getStyle("controlBarHeight");
		if(!_controlBarHeight)
			_controlBarHeight = 90;
		
		_timerFontName = getStyle("timerFontName");
        if(!_timerFontName)
        	_timerFontName = "Verdana";
		
		_timerFontSize = getStyle("timerFontSize");
        if(!_timerFontSize)
        	_timerFontSize = 9;
		
		addEventListener(MetadataEvent.METADATA_RECEIVED, onMetadataReceived);
		addEventListener(ProgressEvent.PROGRESS, onProgress);
		addEventListener(VideoEvent.PLAYHEAD_UPDATE, onPlayheadUpdate);
		addEventListener(VideoEvent.STATE_CHANGE, onStateChange);
		addEventListener(VideoEvent.REWIND, onRewind);
		addEventListener(VideoEvent.COMPLETE, onComplete);
		addEventListener(VideoEvent.READY, onReady);
		addEventListener(KeyboardEvent.KEY_DOWN, obKBDown);
		
		videoArea = new UIComponent();
		addChild(videoArea);
		
		videoArea.addEventListener(MouseEvent.CLICK, pp_onClick);
		
		controlBar = new UIComponent();
		addChild(controlBar);
		
		box = new Canvas();
		controlBar.addChild(box);
		
		playheadSlider = new FXProgressSlider();
		controlBar.addChild(playheadSlider);
		
		playheadSlider.addEventListener(SliderEvent.CHANGE, playhead_onChange);
		playheadSlider.addEventListener(SliderEvent.THUMB_PRESS, onThumbPress);
		playheadSlider.addEventListener(SliderEvent.THUMB_RELEASE, onThumbRelease);
		playheadSlider.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		playheadSlider.addEventListener(SliderEvent.THUMB_DRAG, onThumbDrag);
		playheadSlider.addEventListener(LMProgressSliderEvent.SELECTEDREGIONCHANGE, onSelectedRegionChange);
	
		prevKFButton = new PrevKFButton();
		prevKFButton.enabled = false;
		controlBar.addChild(prevKFButton);
		prevKFButton.addEventListener(MouseEvent.CLICK, prevKeyFrame_onClick);
		
		
		seekToBeginningButton = new SeekToStartButton();
		seekToBeginningButton.enabled = false;
		controlBar.addChild(seekToBeginningButton);
		seekToBeginningButton.addEventListener(MouseEvent.CLICK, stop_onClick);
		
		
		rewindButton = new  RewindButton();
		rewindButton.enabled = false;
		controlBar.addChild(rewindButton);
		
		rewindButton.addEventListener(MouseEvent.CLICK, prevFrame_onClick);
		
		ppButton = new PlayPauseButton();
		controlBar.addChild(ppButton);
		ppButton.enabled = false;
		
		ppButton.addEventListener(MouseEvent.CLICK, pp_onClick);
		
		
		fastForwardButton = new  FastForwardButton();
		fastForwardButton.enabled = false;
		controlBar.addChild(fastForwardButton);

		fastForwardButton.addEventListener(MouseEvent.CLICK, nextFrame_onClick);
		
		seekToEndButton = new  SeekToEndButton();
		seekToEndButton.enabled = false;
		controlBar.addChild(seekToEndButton);
		
		seekToEndButton.addEventListener(MouseEvent.CLICK, seekToEnd_onClick);
		
		nextKFButton = new NextKFButton();
		nextKFButton.enabled = false;
		controlBar.addChild(nextKFButton);
		
		nextKFButton.addEventListener(MouseEvent.CLICK, nextKeyFrame_onClick);
				
		annotationCutButton = new SubmitCutButton();
		annotationCutButton.addEventListener(MouseEvent.CLICK, onAnnotationCutButtonClick);
		annotationCutButton.enabled = false;
		//controlBar.addChild(annotationCutButton);
		
		timerTextField = new TextField();
		controlBar.addChild(timerTextField);
		
		frameNumDisplay = new TextField();
		controlBar.addChild(frameNumDisplay);
		progressDisplay = new TextField();
		controlBar.addChild(progressDisplay);
        
        xField = new TextField();
        controlBar.addChild(xField);
        
        yField = new TextField();
        controlBar.addChild(yField);
        autoPlay = true;
        (autoPlay) ? playPressed = true : playPressed = false
        
        this.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        
	}
	
	/**
	 * Commits any changes to component properties, either to make the 
	 * changes occur at the same time, or to ensure that properties are set in 
	 * a specific order.
	 */
	
	override protected function commitProperties():void
	{
		super.commitProperties();
		
		playheadSlider.setStyle("thumbColor", VLMParams.red);
		playheadSlider.setStyle("thumbOutlineColor", _backColor);
		
		this.controlBar.setStyle("styleName", "videoControlBar");
		
		textFormat.color = _frontColor;
		textFormat.font = _timerFontName;
		textFormat.size = _timerFontSize;
		
		timerTextField.defaultTextFormat = textFormat;
		timerTextField.text = "Loading";
		timerTextField.selectable = false;
		timerTextField.autoSize = TextFieldAutoSize.LEFT;
		
		frameNumDisplay.defaultTextFormat = textFormat;
		frameNumDisplay.text = "";
		frameNumDisplay.selectable = false;
		frameNumDisplay.autoSize = TextFieldAutoSize.LEFT;
		
		progressDisplay.defaultTextFormat = textFormat;
		progressDisplay.text ="";
		progressDisplay.selectable = false;
		progressDisplay.autoSize = TextFieldAutoSize.LEFT;
		
		yField.defaultTextFormat = textFormat;
		yField.text = "";
		yField.selectable = false;
		yField.autoSize = TextFieldAutoSize.LEFT;
		
		xField.defaultTextFormat = textFormat;
		xField.text = "";
		xField.selectable = false;
		xField.autoSize = TextFieldAutoSize.LEFT;
	
	}
	
	public function setFrameNum(num:Number):void
	{
		this.frameNumDisplay.text = "expct Frame: " + String(num);	
	}
	/**
	 * Sizes and positions the children of the component on the screen based on 
	 * all previous property and style settings, and draws any skins or graphic 
	 * elements used by the component. The parent container for the component 
	 * determines the size of the component itself.
	 */
	
	public function getRealHeight():int
	{
		return this.height + this.controlBar.height;	
	}
	
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
    {
        super.updateDisplayList(unscaledWidth, unscaledHeight);
        
        var h:uint = _controlBarHeight/2.6;
        
        // draw
        videoArea.graphics.clear();
        videoArea.graphics.beginFill(VLMParams.gray, 0);
        videoArea.graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
        
      //  videoArea.graphics.lineStyle(1, VLMParams.purple)
        //videoArea.graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
        
        
        controlBar.graphics.clear();
		controlBar.graphics.beginFill(VLMParams.darkGray);
		controlBar.graphics.drawRect(0, 0, unscaledWidth, _controlBarHeight);
        controlBar.graphics.endFill();
        
       // controlBar.graphics.lineStyle(1, VLMParams.purple)
       // controlBar.graphics.drawRect(0, 0, unscaledWidth, _controlBarHeight/2);
        
        controlBar.graphics.drawRect(0, 0, unscaledWidth, _controlBarHeight);
        
        // size
        
        controlBar.setActualSize(unscaledWidth, h*3);
        box.setActualSize(unscaledWidth, h*3);
 		seekToBeginningButton.setActualSize(h,h);
 		prevKFButton.setActualSize(21,17);
        rewindButton.setActualSize(h,h);
        ppButton.setActualSize(h, h);
        fastForwardButton.setActualSize(h,h);
        nextKFButton.setActualSize(21,17);
        seekToEndButton.setActualSize(h,h);
        
      
//        playheadSlider.progress = 0;
        
        // position
		controlBar.x = 0;
		controlBar.y = unscaledHeight - 1;
        
        box.x = 0;
        box.y = 0;
        box.setStyle("styleName", "controlBarCanvas");
        
        
        //we're attempting some centering here so shift the first component to the center of the display 
        //minus the width of half of the buttons of buttons
        seekToBeginningButton.x = unscaledWidth/2 - (7*h)/2;
        seekToBeginningButton.y = 4;
        
       
        rewindButton.x = seekToBeginningButton.x + seekToBeginningButton.width + 2;
        rewindButton.y =  seekToBeginningButton.y;
        
        ppButton.x = rewindButton.x + rewindButton.width + 2;
        ppButton.y = seekToBeginningButton.y;
        
        
        fastForwardButton.x = ppButton.x + ppButton.width + 2;
        fastForwardButton.y =  seekToBeginningButton.y;
       
         
        seekToEndButton.x = fastForwardButton.x + fastForwardButton.width + 2;
        seekToEndButton.y = seekToBeginningButton.y;
        
        
        //the playheadslider shares the row with the control buttons for skipping frames
        
        playheadSlider.x = 10
        playheadSlider.y = seekToBeginningButton.y + (ppButton.height*1.5 + 5);//(controlBar.height - playheadSlider.height)/2;
		 
        playheadSlider.setActualSize(unscaledWidth - (prevKFButton.width + nextKFButton.width+ 20) , 9);
		annotationCutButton.setActualSize(2*h,h);
        
        prevKFButton.x = playheadSlider.x + playheadSlider.width +2;
        prevKFButton.y = seekToBeginningButton.y*2 + (ppButton.height*1.5 + 5)/2 +20;
    
     	nextKFButton.x = prevKFButton.x + prevKFButton.width + 2;
        nextKFButton.y = prevKFButton.y;
   
        //alight timer to the right
        
        //frame number goes to the left
        timerTextField.x = unscaledWidth - timerTextField.width - 60;
        timerTextField.y = 2;
        
        frameNumDisplay.x = timerTextField.x;
        frameNumDisplay.y = timerTextField.y + 10;
     
        progressDisplay.x = timerTextField.x;
		progressDisplay.y = frameNumDisplay.y + 10;
		
        xField.x = frameNumDisplay.x;
        xField.y = frameNumDisplay.y + 10;
        
        yField.x = xField.x;
        yField.y = xField.y + 10;
    }
    
    public function showAnnotationSlider():void
    {
    	this.playheadSlider.showAnnotationSlider();
    	this.prevKFButton.enabled = true;
    	this.nextKFButton.enabled = true;
		trace("____________> showing annotation slider");
    }
    
    public function hideAnnotationSlider():void
    {
    	this.playheadSlider.hideAnnotationSlider();
    	this.prevKFButton.enabled = false;
    	this.nextKFButton.enabled = false;
    }
    
    public function seek(frameNo:int):void
    {
    	trace("trying to seek to " + frameNo);
    	var newTime:Number = frameNo/this.fps;
    	this.playheadTime = newTime;	
    	//this.updateTimer();
    }
    
    /** MouseEvent */
    
	private function pp_onClick(event:MouseEvent):void
	{
		
		if(playPressed)
		{
			pause();
		}
		else
		{
			play();
		}
	}
	override public function pause():void
	{
		super.pause();
		playPressed = false;
	}
	
	override public function play():void
	{
		super.play();
		playPressed = true;
	}
	
	public function enableSubmitCutButton():void
	{
		this.annotationCutButton.enabled = true;
	}
	
	public function disableSubmitCutButton():void
	{
		this.annotationCutButton.enabled = false;
		
	}
	
	public function showHighlightFrames(frames:ArrayCollection):void
	{
		if(frames)
		{
			this.playheadSlider.highlightFrames = frames;
			this.prevKFButton.enabled = true;
			this.nextKFButton.enabled = true;
		}
	}
	
	private function onSelectedRegionChange(event:LMProgressSliderEvent):void
	{
			
		var val:Number = NaN;
		if(event._lastThumbSelected == 0)
			val = event._valueLeft;
		else if(event._lastThumbSelected == 1)
			val = event._valueRight;
		else
		{	
			trace("ASSERT ERROR: impossible path");	
			return;
		}
		this.thumbHookedToPlayhead = true;

		//make the playhead of the video seek all the way here
		// this should be called topdown this.seek(val);
		
		//get the values of the brackets to change the start and end frames in the annotation	
		var a:Array = playheadSlider.getAnnotationThumbVals();
		
		
		var e:LMEvent = new LMEvent(LMEvent.DELETEPOLYSOUTSIDERANGE);
		e.startFrame = int(a[0]);
		e.endFrame = int(a[1]);
		e.frame = val;
		dispatchEvent(e);
	}
	
	
	private function stop_onClick(event:MouseEvent):void
	{
		stop();
		this.playheadTime= 0;
		playPressed = false;
	}
	
	private function nextFrame_onClick(event:MouseEvent):void
	{
		skipRight();
		//CursorManager.setBusyCursor();
	}
	
	private function seekToEnd_onClick(event:MouseEvent):void
	{
		stop();
		playPressed = false;
		playheadTime  = this.totalTime- 0.1;
	}
	
	private function nextKeyFrame_onClick(event:MouseEvent):void
	{
		if(this.playPressed)
			pause();

		//find the closest keyFrame
		var currFrame:int = VideoLabelMe.time2Frame(playheadTime,this.frameRate);
		var keyFrames:ArrayCollection = this.playheadSlider.highlightFrames;
		
		var nextKF:int = -1;
		for each (var f:int in keyFrames)
		{
			if(f > currFrame)
			{	
				nextKF = f;
				break;
			}	
		}	
		if(nextKF !=-1)
		{
			var t:Number = VideoLabelMe.frame2Time(nextKF, this.frameRate);
			playheadTime = t < totalTime ? t : totalTime -1;	
		}
	}
	
	private function prevFrame_onClick(event:MouseEvent):void
	{	
		skipLeft();
		//CursorManager.setBusyCursor();
	}
	
	private function prevKeyFrame_onClick(event:MouseEvent):void
	{	
		if(this.playPressed)
			pause();

		//find the closest keyFrame
		var currFrame:int = VideoLabelMe.time2Frame(playheadTime,this.frameRate);
		var keyFrames:ArrayCollection = this.playheadSlider.highlightFrames;
		
		var prevKF:int = -1;
		for(var i:int = keyFrames.length -1; i >=0 ;i--)
		{
			var f:int  = keyFrames[i];
			if(f < currFrame)
			{	
				prevKF = f;
				break;
			}	
		}	
		if(prevKF !=-1)
		{
			var t:Number = VideoLabelMe.frame2Time(prevKF, this.frameRate);
			playheadTime = t < totalTime ? t : totalTime -1;	
		}		
	}
	
	
	private function skipRight():void
	{
		if(this.playPressed)
			pause();

		var t:Number = playheadTime + step/frameRate;
		playheadTime = t < totalTime ? t : totalTime -1;	
	}

	private function skipLeft():void
	{
		if(this.playPressed)
			pause();

		var t:Number = playheadTime - (step)/frameRate;
		playheadTime = t > 0 ? t : 0;
		var evt:FrameChangeEvent = new FrameChangeEvent("backward", true, true);
		this.dispatchEvent(evt);
	}
		
	private function onMouseDown(event:MouseEvent):void
	{
	//	if(event.target != this.playheadSlider.getAnnotationSlider())
		//	thumbHookedToPlayhead = false;
	}
	
	/*keyboard event*/
	private function obKBDown(event:KeyboardEvent):void
	{
		
		if(event.keyCode == Keyboard.RIGHT){
			skipRight();
		}
		else if(event.keyCode == Keyboard.LEFT){
			skipLeft();
		}
			
	}
	
	
	/** SliderEvent */
	
	private function onThumbPress(event:SliderEvent):void
	{
		thumbHookedToPlayhead = false;
	}
	
	private function onThumbRelease(event:SliderEvent):void
	{
		thumbHookedToPlayhead = true;
		trace("dragging playhead time : " + event.currentTarget.value);
	    playheadTime = event.currentTarget.value;
	}
	
	private function onThumbDrag(event:SliderEvent):void
	{
		this.updateTimer();
//		timerTextField.text = "Time: " +  formatTime(event.value)+" / "+formatTime(totalTime);
//		frameNumDisplay.text = "Frame: " + formatFrameNum(event.value) + " FPS: " + formatFrameNum(this.frameRate);
	//	trace("dragging playhead time : " + event.currentTarget.value);
	//	playheadTime = event.currentTarget.value;
	}
	
	private function playhead_onChange(event:SliderEvent):void
	{
		thumbHookedToPlayhead = true;
		this.updateTimer();

//		timerTextField.text = "Time: " + formatTime(event.value)+" / "+formatTime(totalTime);
//		frameNumDisplay.text = "Frame: " +  formatFrameNum(event.value) + " FPS: " + formatFrameNum(this.frameRate);
		trace("on change playhead time : " + event.currentTarget.value);
		playheadTime = event.currentTarget.value;
	}
	
	
	private function onAnnotationCutButtonClick(event:MouseEvent):void
	{
		var a:Array = playheadSlider.getAnnotationThumbVals();
		
		var e:LMEvent = new LMEvent(LMEvent.DELETEPOLYSOUTSIDERANGE);
		e.startFrame = int(a[0]);
		e.endFrame = int(a[1]);
		dispatchEvent(e);
	}
	
	/** */
	
	private function onRewind(event:VideoEvent):void
	{
		
	}
	
	private function onMetadataReceived(event:MetadataEvent):void
	{
		playheadSlider.maximum = totalTime;
		var info:Object = event.info;
		this.width = info.width;
		this.height = info.height;
		this.frameRate = event.info.framerate;
		this.totalTime = event.info.duration;
		trace("totalTime: "+ totalTime);
		updateTimer();
		dispatchEvent(new LMEvent(LMEvent.VIDEOREADY, true, false, null));

	}
	
	private function onPlayheadUpdate(event:VideoEvent):void
	{
		trace("FXVideo:current time : " + event.playheadTime);
			
		updateTimer(event.playheadTime);
	
		if(thumbHookedToPlayhead)
		{
			playheadSlider.value = event.playheadTime;
			
		}
		
		if(flo)
		{
			thumbHookedToPlayhead = false;
		}
		
		if(flo && playheadTime > 0)
		{
			thumbHookedToPlayhead = true;
			stop();
			
			flo = false;
			
			if(_playPressed)
			{	
				play();
			}
		}
	}
	
	private function onStateChange(event:VideoEvent):void
	{
		//trace("state: "+event.state+" : "+event.stateResponsive);
		
		if(event.state == VideoEvent.CONNECTION_ERROR)
		{
			timerTextField.text = "Conn Error";
		}
	}
	
	private function onReady(event:VideoEvent):void
	{
		ppButton.enabled = true;
		fastForwardButton.enabled = true;
		rewindButton.enabled = true;
		seekToBeginningButton.enabled = true;
		seekToEndButton.enabled = true;
		prevKFButton.enabled = false;
		nextKFButton.enabled = false;
		
		//Alert.show("this is me, new");
//		this.dispatchEvent(event);
	//	this.ppButton.state = "pause";
		//this.pause();
	//	this.play();
		
	}
	
	private function onComplete(event:VideoEvent):void
	{
	//	playPressed = false;
		
		

	}
	
	private function onProgress(event:ProgressEvent):void
	{
		loadProgress = Math.floor(event.bytesLoaded/event.bytesTotal*100);
		var playheadProgress:Number = Math.floor(playheadTime/totalTime*100);
		playheadSlider.progress = loadProgress;
		trace("overall video progress : " + loadProgress); 
		progressDisplay.text = "Loading : " + loadProgress +"%"
	}			
	
	private function onMenuItemSelect(event:ContextMenuEvent):void
	{
		navigateToURL(new URLRequest("http://www.fxcomponents.com/?p=29"));
	}
	
	private function onKeyDown(event:KeyboardEvent):void
	{
	/*	var num:int = step/frameRate;;
		if(event.keyCode == Keyboard.RIGHT){
			movePlayhead(num);
		}
		else if(event.keyCode == Keyboard.LEFT){
			movePlayhead(num*-1);
		}*/
	}
	
	private function movePlayhead(num:Number):void
	{	
		if(this.playheadTime+num >0)
		{
			this.playheadTime += num;
			trace("playheadTime: " + this.playheadTime);
		}
	}
	
	/** functions */
	
	private function formatFrameNum(value:Number):String
	{
		var result:String = String(VideoLabelMe.time2Frame(value, this.fps));
		return result;
	}
	
	private function formatTime(value:int):String
	{
		var result:String = (value % 60).toString();
        if (result.length == 1)
            result = Math.floor(value / 60).toString() + ":0" + result;
        else 
            result = Math.floor(value / 60).toString() + ":" + result;
        return result;
	}
		
	private function updateTimer(t=-1.0):void
	{
		if(t == -1.0)
			t = this.playheadTime;
			
		timerTextField.text = "Time: ("+ formatTime(t)+") / "+formatTime(totalTime);
		frameNumDisplay.text = "Frame: " + formatFrameNum(t) ;
	}
	
	public function updateX(x:int):void
	{
		this.xField.text = "X: " + x.toString();
	}
	
	public function updateY(y:int):void
	{
		this.yField.text = "Y: " + y.toString();
	}
}
}
