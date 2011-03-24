package vlm.util
{
	public class ArrayUtils
	{
		public static function arrayintersection(array1:Array, array2:Array):Array
		{
			var newa:Array = new Array();
			for each(var elem in array1)
			{
				if (array2.indexOf(elem)>=0)
					newa.push(elem);
			}
			return newa;
		}
		// Requires that the arrays contain only numeric values.
		public static function dotproduct(array1:Array, array2:Array):Number
		{
			if (array1.length != array2.length)
				throw new Error("arrays not the same length");
			var dotproduct:Number = 0;
			for(var i:int=0;i<array1.length;i++)
			{
				var p:Number = array1[i]*array2[i];
				dotproduct = dotproduct + p;
			}
			return dotproduct;
		}
		
		public static function createArrayOfOnes(n:int):Array
		{
			var a:Array = new Array();
			for(var i=0;i<n;i++)
			{
				a.push(1);	
			}
			return a;
		}
		
		public static function maxAndMin(array:Array):Array
		{
			var min:Number = Infinity;
			var max:Number = -Infinity;
			for each(var elem:Number in array)
			{
				if( elem < min )
				{
					min = elem;
				}
				if( elem > max )
				{
					max = elem;
				}
			}
			return [max, min];
		}
		/*
			Returns array1 - array2
		*/
		public static function difference(array1:Array, array2:Array):Array
		{
			var newa:Array = new Array();
			for each(var elem in array1)
			{
				if (array2.indexOf(elem)<0)
					newa.push(elem);
			}
			return newa;
		}
		
	}
}
