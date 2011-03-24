package vlm.skins.videoplayer
{

import mx.skins.Border;

/**
 *  The skin for the track in a Slider.
 */
public class LMVerticalTrack extends Border 
{
	
	//--------------------------------------------------------------------------
	//a
	//  Constructor
	//
	//--------------------------------------------------------------------------

    /**
	 *  Constructor.
	 */
	public function LMVerticalTrack()
	{
		super();
	}

	//--------------------------------------------------------------------------
	//
	//  Overridden properties
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  measuredWidth
	//----------------------------------

	/**
	 *  @private
	 */
	override public function get measuredWidth():Number
	{
		return 7;
	}

	//----------------------------------
	//  measuredHeight
	//----------------------------------

	/**
	 *  @private
	 */
	override public function get measuredHeight():Number
	{
		return 20;
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overridden methods
	//
	//--------------------------------------------------------------------------
	
    /**
	 *  @private
	 */
	override protected function updateDisplayList(w:Number, h:Number):void
	{	
		super.updateDisplayList(w, h);
		
		var trackColor:Number = getStyle("trackColor");
		
		graphics.clear();
		
		drawRoundRect(0, 0, w, h, 0, trackColor, 1);
	}
}

}
