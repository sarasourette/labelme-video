//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm
{
	public class MTData
	{
		public var _mtMode:Boolean;
		public var _assignmentId:String;
		public var _hitId:String;
		public var _sandboxMode:String;
		
		public function MTData(mtMode:Boolean=false, aId:String="", hId:String="", sandboxMode="")
		{
			this._mtMode = mtMode;
			this._assignmentId = aId;
			this._hitId = hId;
			this._sandboxMode = sandboxMode;
		}

	}
}
