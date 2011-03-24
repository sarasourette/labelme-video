//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.components
{
	import mx.controls.TileList;
	import mx.core.mx_internal; //this import statement should appear be last

	
	public class ExposedTileList extends TileList
	{
		use namespace mx_internal; //tells Actionscript that mx_internal is a namespace 
       
		public function ExposedTileList()
		{
			super();
		}
		
        //The array of renderers being used in this list
        public function get renderers():Array
        {
            //prefix the internal property name with its namespace
            return mx_internal::rendererArray;
        }
		
	}
}
