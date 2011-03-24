//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.core
{
	import flash.geom.Point;

	
	//helper class for interpolating polygons
	public class LM3DInterpolation
	{
		
		
		private static function getCentroid(x:Array, y:Array):Point
		{
			var n:int = Math.floor(x.length/2);
			var centroid:Point = new Point();
			centroid.x = x[n];
			centroid.y = y[n];
			
			return centroid;
		}
		
		//returns the vanishing point for all the pairs of points
		// x1, y1- is the array of x and y points for the first polygon
		// x2, y2 - is the array of x and y points for the second polygon (the one at a different time)		
		public static function getVanishingPoint(x1:Array, y1:Array, x2:Array, y2:Array):Point
		{
			//we assume here that all the arrays have the same length
			
			var intX:Array = new Array();
			var intY:Array = new Array();
			//only compute the intersection between pairs of distinct points						
			for( var i:int = 0; i < x1.length ; i++)
			{
				for (var j:int = i+1; j < x1.length; j++)
				{
					var intPoint:Point = LM3DInterpolation.getIntersectionPoint(new Point(x1[i], y1[i]),
								 new Point(x2[i], y2[i]), new Point(x1[j], y1[j]), new Point(x2[j], y2[j]));
					if(intPoint)
					{
						intX.push(intPoint.x);
						intY.push(intPoint.y);
					}
				}
			}
			if(intX.length >0)
			{
				// the vanishing point is just the independent median of each dimension of these points. 
				intX = intX.sort();
				intY = intY.sort();
				
				var idx:int = Math.floor(intX.length/2);
				var vPoint:Point = new Point(intX[idx], intY[idx]);
				return vPoint;
			}		
			else 
				return null;
		}
		
		//returns the intersection point for the line that passes through p and
		//q  and the one that passes through r and s
		private static function getIntersectionPoint(p:Point, q:Point, r:Point, s:Point):Point
		{
			var intersect:Point = new Point();
			//check. If the slope is the same between the two lines, the lines are parallel
			var m1:Number = (q.y - p.y)/(q.x - p.x);
			var m2:Number = (s.y - r.y)/(s.x - r.x);
			
			//for now this doesn't work for objects that move in a vertical line. TODO Fix
			if(q.x == p.y || r.x == s.x|| Math.abs(m1 - m2) < 0.1 )
				return null;
				
			intersect.x = ((p.x*q.y-p.y*q.x)*(r.x-s.x)-(p.x-q.x)*(r.x*s.y-r.y*s.x))/((p.x-q.x)*(r.y-s.y)-(p.y-q.y)*(r.x-s.x));
			intersect.y = ((p.x*q.y-p.y*q.x)*(r.y-s.y)-(p.y-q.y)*(r.x*s.y-r.y*s.x))/((p.x-q.x)*(r.y-s.y)-(p.y-q.y)*(r.x-s.x));
			
			return intersect;
		}
		
	}
}
