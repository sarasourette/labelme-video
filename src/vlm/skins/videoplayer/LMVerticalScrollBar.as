package vlm.skins.videoplayer
{
	import mx.controls.VScrollBar;
	
	public class LMVerticalScrollBar extends VScrollBar
	{
		public function LMVerticalScrollBar()
		{
			super();
			
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			this.setStyle("trackSkin", LMVerticalTrack);
			this.setStyle("thumbDownSkin", LMThumbSkin);
		} 
	}
}
