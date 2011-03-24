//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jessie Li. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.util
{
	
	import flash.geom.Matrix;
	
	import mx.utils.ArrayUtil;

	public class PlainMatrix
	{
		private var _nrows:int;
		private var _ncols:int;
		private var _rows:Array;
		private var _cols:Array;
		
		public function PlainMatrix(rows:int, cols:int)
		{
			_nrows = rows;
			_ncols = cols;
		}
		// Populate matrix using rowVectors
		public function populateMatrix(rowVectors:Array):void
		{
			if (rowVectors.length != nrows)
				throw new Error("number of row vectors does not equal number of rows");
			
			if (rowVectors[0].length != ncols)
				throw new Error("number of elements in each row vector does not equal number of columns");
			
			_rows = rowVectors;
			_cols = new Array();
			for(var j=0; j< ncols; j++)
			{
				var column:Array = new Array();
				for(var i=0; i< nrows; i++)
				{
					var row:Array = rowVectors[i];
					column.push(row[j]);
				}
				_cols.push(column);
			}
						
		}
		public function transpose():PlainMatrix
		{
			var transposedMatrix:PlainMatrix = new PlainMatrix(_ncols, _nrows);
			transposedMatrix.populateMatrix(_cols);
			return transposedMatrix;
		}
		public function multiply(matrix:PlainMatrix):PlainMatrix
		{	
			var productMatrix:PlainMatrix = new PlainMatrix(_nrows,matrix.ncols);
			var rightmatrixcols:Array = matrix.cols;
			
			var newrows:Array = new Array();
			
			for each(var row:Array in _rows)
			{
				var newrow:Array = new Array();
				
				for each(var col:Array in rightmatrixcols)
				{
					var product:Number = ArrayUtils.dotproduct(row, col);
					newrow.push(product);
				}
				newrows.push(newrow);
			}
			productMatrix.populateMatrix(newrows);
			return productMatrix;
		}
		/* Computes the inverse of a 3x3 matrix using closed form formula.*/
		public function inverse():PlainMatrix
		{
			if ( _nrows != 3 || _ncols != 3 )
				throw new Error("Number of rows or the number of cols does not equal 3");
			
			var a11:Number = _rows[0][0];
			var a12:Number = _rows[0][1];
			var a13:Number = _rows[0][2];
			
			var a21:Number = _rows[1][0];
			var a22:Number = _rows[1][1];
			var a23:Number = _rows[1][2];
			
			var a31:Number = _rows[2][0];
			var a32:Number = _rows[2][1];
			var a33:Number = _rows[2][2];
			
			var det:Number = a11*(a33*a22 - a32*a23) - a21*(a33*a12 - a32*a13) + a31*(a23*a12 - a22*a13);
			
			if( det < 0.01 )
				throw new Error("Matrix close to singular");
			
			var b11:Number = (1/det)*(a33*a22 - a32*a23);
			var b12:Number = -(1/det)*(a33*a12 - a32*a13);
			var b13:Number = (1/det)*(a23*a12 - a22*a13);
			
			var b21:Number = -(1/det)*(a33*a21 - a31*a23);
			var b22:Number = (1/det)*(a33*a11 - a31*a13);
			var b23:Number = -(1/det)*(a23*a11 - a21*a13);
			
			var b31:Number = (1/det)*(a32*a21 - a31*a22);
			var b32:Number = -(1/det)*(a32*a11 - a31*a12);
			var b33:Number = (1/det)*(a22*a11 - a21*a12);
			
			var newrows:Array = [[b11, b12, b13],[b21, b22, b23], [b31, b32, b33]]; 
				
			var inverse:PlainMatrix = new PlainMatrix(3,3);
			inverse.populateMatrix(newrows);
			return inverse;
		}
		/* Converts a PlainMatrix to a transformation Matrix*/
		public function convertToFlexMatrix():Matrix
		{
			if (_rows.length < 2)
				throw new Error("Must have at least two rows");
			if (_cols.length < 3)
				throw new Error("Must have at least three columns");
			
			var m:Matrix = new Matrix();
			m.a = _rows[0][0];
			m.c = _rows[0][1];
			m.tx = _rows[0][2];
			
			m.b = _rows[1][0];
			m.d = _rows[1][1];
			m.ty = _rows[1][2];
			return m;
		}
		public function get nrows():int
		{
			return _nrows;
		}
		public function get ncols():int
		{
			return _ncols;
		}
		public function get rows():Array
		{
			return _rows;
		}
		public function get cols():Array
		{
			return _cols;
		}
		
	}
}
