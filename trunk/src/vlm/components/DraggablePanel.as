//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components
{
	import mx.containers.Panel;
	import flash.events.Event;
	import flash.events.MouseEvent;

	import mx.containers.Panel;

	public class DraggablePanel extends Panel
	{
		public function DraggablePanel()
		{
			super();
		}

		private function handleDown(e:Event):void{
			this.startDrag()
		}
		private function handleUp(e:Event):void{
			this.stopDrag()
		}
		override protected function createChildren():void{
			super.createChildren();		
		}
	}

}
