//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.util
{
	import flash.geom.Matrix;

	public class MatrixUtils
	{
		public static function isIdentity(m:Matrix):Boolean
		{
			return (m.a == 1 && m.b==0 && m.c==0 && m.d==1 && m.tx==0 && m.ty==0);
		}
	}
}
