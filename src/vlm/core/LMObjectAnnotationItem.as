//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.core
{
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	
	import mx.utils.StringUtil;

	[RemoteClass(alias="LMAnnotator.LMObjectAnnotationItem")]
	
	public class LMObjectAnnotationItem implements IExternalizable
	{
		private var _id:int;
		private var _name:String;
		private var _startFrame:int;
		private var _selected:Boolean;
		private var _endFrame:int;
		private var _action:String;
		private var _moving:String;
		
		public function LMObjectAnnotationItem(id:int =NaN, name:String="", startFrame:int=0, endFrame:int=0, moving:String="", action:String="")
		{
			_id = id;
			_name = name;
			_startFrame = startFrame;
			_selected = false;
			_endFrame = endFrame;
			_action = action;
			_moving = moving;
		}
		
		public function get name():String
		{
			return _name;
		}

		public function get id():int
		{
			return _id;
		}
		
		public function get startFrame():int
		{
			return _startFrame;
		}
	
		public function get endFrame():int
		{
			return _endFrame;
		}
		
		public function get selected():Boolean
		{
			return _selected;	
		}
		
		public function set selected(s:Boolean):void
		{
			_selected = s;
		}
		
		public function get action():String
		{
			return _action;
		}
		
		public function get moving():String
		{
			return _moving;
		}
		public function readExternal(input:IDataInput):void
		{
			
			_id = input.readInt();
			_name = input.readObject() as String;
			_startFrame = input.readInt();
			_selected = input.readBoolean();
			_endFrame = input.readInt();
			_action = input.readObject() as String;
			_moving = input.readObject() as String;
			
		}
		
		public function writeExternal(output:IDataOutput):void
		{
			
			output.writeInt(_id);
			output.writeObject(_name) as String;
			output.writeInt(_startFrame);
			output.writeBoolean(_selected);
			output.writeInt(_endFrame);
			output.writeObject(_action) as String;
			output.writeObject(_moving) as String;
			
			
		}
	}
}
