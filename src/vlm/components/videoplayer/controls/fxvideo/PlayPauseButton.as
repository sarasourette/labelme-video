//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components.videoplayer.controls.fxvideo
{
import flash.display.Shape;
import flash.events.MouseEvent;

import vlm.components.videoplayer.controls.fxvideo.LMButton;

public class PlayPauseButton extends LMButton
{
	[Embed('assets/play.png')]
	private static var playIcon:Class;

	[Embed('assets/play_down.png')]
	private static var playDownIcon:Class;
		
	[Embed('assets/pause.png')]
	private static var pauseIcon:Class;

	[Embed('assets/pause_down.png')]
	private static var pauseDownIcon:Class;

	
	public function PlayPauseButton()
	{
		super();
		this.buttonMode = true;
		this.useHandCursor = true;
	}
	
	private var _state:String = "pause";
	
	public function set state(value:String):void
	{
		_state = value;
		
		invalidateDisplayList();
	}
	
	public function get state():String
	{
		return _state;
	}
	
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		
		
		if(_state == "play")
		{
			this.setStyle("upSkin", playIcon);
			this.setStyle("overSkin", playDownIcon);
			this.setStyle("downSkin", playDownIcon);
			
		}
		
		if(_state == "pause")
		{
			this.setStyle("upSkin", pauseIcon);
			this.setStyle("overSkin", pauseDownIcon);
			this.setStyle("downSkin", pauseDownIcon);

		}
	}
}
}
