//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.videoplayer.controls
{
import vlm.components.videoplayer.controls.fxslider.LMProgressSliderEvent;
import vlm.skins.videoplayer.SliderProgressSkin;

import flash.display.DisplayObject;
import flash.display.Graphics;

import mx.collections.ArrayCollection;
import mx.controls.HSlider;
import mx.core.IFlexDisplayObject;
import mx.events.SliderEvent;
import mx.styles.ISimpleStyleClient;
import vlm.components.videoplayer.controls.fxslider.FXSlider;

[Style(name="progressColor", type="uint", format="Color", inherit="no")]
[Style(name="progressSkin", type="Class", inherit="no")]

public class FXProgressSlider extends FXSlider
{

	private var skinClass:Class;
	private var progressBar:IFlexDisplayObject;
	
	protected var annotationSlider:AnnotationSlider;
	private var _lastLeft:Number;
	private var _lastRight:Number;
	
	private var _progress:Number = 20;
		
	public function FXProgressSlider()
	{
		super();
		
		
	}
		
	public function get progress():Number
	{
		return _progress;
	}
	public function set progress(value:Number):void
	{
		_progress = value;
		
		invalidateDisplayList();
	}
	
	public function getAnnotationThumbVals():Array
	{
		return annotationSlider.values;
	}
	
	public function getAnnotationSlider():HSlider
	{
		return annotationSlider;
	}
	
	override protected function createChildren():void
	{
		super.createChildren();
		
		if(!getStyle("progressColor"))
			setStyle("progressColor", VLMParams.gray);
			
		if(!getStyle("progressSkin"))
			setStyle("progressSkin", SliderProgressSkin);
		
		if (!progressBar)
        {
            skinClass = getStyle("progressSkin");
			
            progressBar = new skinClass();
            
            if (progressBar is ISimpleStyleClient)
                ISimpleStyleClient(progressBar).styleName = this;

            addChildAt(DisplayObject(progressBar), 1);
        }
        
        if(!annotationSlider)
        {
        	annotationSlider = new AnnotationSlider();
        	addChild(annotationSlider);
        	annotationSlider.addEventListener(SliderEvent.CHANGE,onSliderManualChange);
			
        }
        
	}
	
	override protected function commitProperties():void
	{
		super.commitProperties();
		annotationSlider.thumbCount = 2;
        annotationSlider.width = this.unscaledWidth;
        annotationSlider.height = this.unscaledHeight;
        annotationSlider.y = 11;
    }
	
	public function setAnnotationSlider(min:int, max:int):void
	{
		annotationSlider.minimum = min;
		annotationSlider.maximum = max;
		annotationSlider.setThumbValueAt(1, max);
	}
	
	public function moveLeftBracket(left:uint):void
	{
		if( left > this._lastRight)
			left = _lastRight;
		annotationSlider.setThumbValueAt(0,left);
		this._lastLeft = left;
		dispatchSliderChangeEvent(0)
	}

	public function moveRightBracket(right:uint):void
	{
		if(right < this._lastLeft)
			right = _lastLeft;
		annotationSlider.setThumbValueAt(1,right);
		this._lastRight = right;
		dispatchSliderChangeEvent(1)
	}

	public function setLeftBrightBracketBoundaries(left:int, right:int):void
	{
		annotationSlider.setThumbValueAt(0,left);
		annotationSlider.setThumbValueAt(1, right);
		this._lastLeft = left;
		this._lastRight = right;
	}
	
	public function showAnnotationSlider():void
	{
		annotationSlider.visible = true;
	}
	
	public function hideAnnotationSlider():void
	{
		annotationSlider.visible = false;
	}

	public function set highlightFrames(frames:ArrayCollection):void
	{
		annotationSlider.highlightFrames = frames;
	}
	
	public function get highlightFrames():ArrayCollection
	{
		return annotationSlider.highlightFrames;
	}
	
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		var w:Number;
		var buggyArea:Number = unscaledWidth / maximum * 10;
		
		progressBar.setActualSize(Math.floor(_progress*unscaledWidth/100), unscaledHeight);
		
		
	    annotationSlider.width = this.unscaledWidth;
        annotationSlider.height = this.unscaledHeight;
		var g:Graphics = bound.graphics;
        
        g.clear();
        g.beginFill(VLMParams.darkPink, 0);
        
        (_progress == 100) ? w = unscaledWidth : w = Math.max(_progress*unscaledWidth/100 - buggyArea, 0)
       
        g.drawRect(0, 0, w, unscaledHeight);
        g.endFill();
	}
	
	private function onSliderManualChange(evt:SliderEvent):void
	{
		dispatchSliderChangeEvent();
	}
	
	private function dispatchSliderChangeEvent(lastSelected:int=-1):void
	{
		var e:LMProgressSliderEvent = new LMProgressSliderEvent(LMProgressSliderEvent.SELECTEDREGIONCHANGE,
											annotationSlider.values[0], annotationSlider.values[1]);
		
		if(lastSelected ==0  ||annotationSlider.values[0] != _lastLeft)
			e._lastThumbSelected = 0;
		else if (lastSelected == 1 || annotationSlider.values[1] != _lastRight)
			e._lastThumbSelected = 1;
			
		_lastRight = annotationSlider.values[1];
		_lastLeft = annotationSlider.values[0];
		
		dispatchEvent(e);			
	}
}
}
