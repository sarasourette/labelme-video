//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.videoplayer.controls.fxvideo
{

import flash.display.Shape;
import flash.events.MouseEvent;

import mx.controls.Button;

public class LMButton extends Button
{
	public function LMButton()
	{
		super();
	}
	
	private var panelAlpha:Number = 0;
	
	protected var icon:Shape;
	
	private var _iconColor:uint = VLMParams.white;
	
	public function set iconColor(value:uint):void
	{
		_iconColor = value;
	}
	
	public function get iconColor():uint
	{
		return _iconColor;
	}
	
	override public function get measuredWidth():Number
	{
		return 21;
	}
	
	override public function get measuredHeight():Number
	{
		return 21;
	}
	
	override protected function createChildren():void
	{
		super.createChildren();
		
		icon = new Shape();
		addChild(icon);
	}
	
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		
		addEventListener(MouseEvent.ROLL_OVER, onRollOver);
		addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		
		graphics.clear();
		graphics.beginFill(_iconColor, panelAlpha);
		graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
	}
	
	private function onRollOver(event:MouseEvent):void
	{
		panelAlpha = .1;
		
		invalidateDisplayList();
	}
	
	private function onRollOut(event:MouseEvent):void
	{
		panelAlpha = 0;
		
		invalidateDisplayList();
	}
	
	protected function centerIcon():void
	{
		icon.x = int((unscaledWidth - icon.width)/2);
		icon.y = int((unscaledHeight - icon.height)/2);
	}
}
}
