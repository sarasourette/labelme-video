package vlm.skins.videoplayer
{

import flash.display.Graphics;

import mx.skins.ProgrammaticSkin;

/**
 *  The skin for all the states of a thumb in a Slider.
 */
public class LMThumbSkin extends ProgrammaticSkin
{
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

    /**
	 *  Constructor.
	 */
	public function LMThumbSkin()
	{
		super();
	}
	
    /**
	 *  @private
	 */
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		
 		var c:uint = getStyle("thumbColor");
 		
 		var g:Graphics = graphics;
 		g.clear();
		
		g.beginFill(getStyle("thumbOutlineColor"), 1);
		g.drawRect(-unscaledWidth/2 - 1, -1, unscaledWidth + 2, unscaledHeight + 2);
		
		switch (name)
		{
			case "upSkin":
			{				
				g.beginFill(c, 1);
				break;
			}
			
			case "overSkin":
			{
				g.beginFill(c + 0x111111, 1);
				break;
			}
			
			case "downSkin":
			{
				g.beginFill(c + 0x111111, 1);
				break;
			}
			
			case "disabledSkin":
			{
				g.beginFill(c, .5);
				break;
			}
		}
		
		g.drawRect(-unscaledWidth/2, 0, unscaledWidth, unscaledHeight);
	}
}
}
