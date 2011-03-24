//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.core
{	
	

import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.IDataInput;
import flash.utils.IDataOutput;
import flash.utils.IExternalizable;

import mx.controls.Alert;
import mx.utils.ArrayUtil;
import mx.utils.ObjectUtil;
import vlm.components.annotator.LMPolygonSprite;
import vlm.components.annotator.Annotator;


[RemoteClass(alias="LMAnnotator.LMPolygon")]
public class LMPolygon implements IExternalizable
{
	private var _x:Array; //stores real coordinates
	private var _y:Array;
	
//	private var _labeled:Array;
	private var _labeledBool:int;
	private var _color:int;
	private var _frame:uint;
	private var _polySprite:LMPolygonSprite;
	private var _startFrame:uint;
	private var _endFrame:uint;
//	private var _polyComponent:LMPolygonComponent;
	private var _oId:int;
	
	private var _spriteState:String;
	
	public function LMPolygon():void
	{
		//registerClassAlias("com.fxcomponents.controls.lmannotator", LMPolygon);			
	}
	
	public function initializePoints(px:Array, py:Array, c:uint, f:uint, lbld:int, scaleX:Number, scaleY:Number, spriteState:String):void
	{
		//scaleX and scaleY indicate the scale of the display vs the real size
		_x = new Array(px.length);
		_y = new Array(py.length);
		for (var i:int =0; i< px.length; i++)
		{
			_x[i] = px[i]/scaleX;
			_y[i] = py[i]/scaleY;
		}
		_color = c;
		_frame = f;
		this._spriteState = spriteState;
		_polySprite = new LMPolygonSprite(this, _color, this._spriteState);
		_oId = -1;
		_labeledBool = lbld;
	
	}
	
	public function initializeWithXML(xml:XML, spriteState:String, oId:int):void
	{
		var n:int = xml.child("*").length()-1;
		
		_x = new Array(n);
		_y = new Array(n);
		
		var i:int = 0;
		for each (var px:int in xml.pt.x)
		{
			_x[i] = px;
			i++;
		}
		i = 0;
		for each (var py:int in xml.pt.y)
		{
			_y[i] = py;
			i++;
		}
		_labeledBool = int(xml.pt[1].l);
	
		_frame = int(xml.t);
		_oId = oId;
		_color = -1;
		this._spriteState = spriteState;
		
	}
	
	public function get objectId():int
	{
		return _oId;
	}
	
	public function set objectId(oId:int):void
	{
		_oId = oId;
	}
	
	public function draw(scaleX:Number, scaleY:Number):LMPolygonSprite
	{
		if(!_polySprite)
			_polySprite = new LMPolygonSprite(this, this.color, this._spriteState);
		_polySprite.setDisplayToRealScale(scaleX, scaleY);
		return _polySprite;
	}
	
	public function set frame(f:uint):void
	{
		_frame = f;	
	}
	
	public function get frame():uint
	{
		return _frame;
	}
	
	public function get nPoints():int
	{
		return _x.length;	
	}
	
	public function set xArray(x:Array):void
	{
		this._x = x;
	}
	
	public function get xArray():Array
	{
		return this._x;
	}
	
	public function set yArray(y:Array):void
	{
		this._y = y;
	}
	public function get yArray():Array
	{
		return this._y;	
	}
	public function getX(idx:int):int
	{
		if(idx>=0 && idx <=_x.length)
		{
			return _x[idx];
		}
		return null;
	}
	
	public function setX(idx:int, value:int):void
	{
		if(idx>=0 && idx <=_x.length) {
			_x[idx] = value;
		}
	}
	
	public function getY(idx:int):int
	{
		if(idx>=0 && idx <=_y.length)
		{ 
			return _y[idx];
		}
		return null;
	}
	
	public function setY(idx:int, value:int):void
	{
		if(idx>=0 && idx <=_y.length) 
		{
			_y[idx] = value;
		}
	}
	
	public function get labeled():int
	{
		return _labeledBool;
	}
	
	public function set labeled(l:int):void
	{
		this._labeledBool = l;
	}
	
	public function getLabeled(idx:int):int
	{
		return this._labeledBool;
	}
	
	public function setLabeled(value:int):void
	{
		this._labeledBool = value;
	}
	
	public function nManuallyLabeled():int
	{
		return this.nPoints;
	}
		
	public function set startFrame(sf:int):void
	{
		_startFrame = sf;
	}
	
	public function set endFrame(ef:int):void
	{
		_endFrame = ef;
	}
	
	public function get startFrame():int
	{
		return _startFrame;
	}
	
	public function get endFrame():int
	{
		return _endFrame;
	}
	
	public static function makeXML(x:Array, y:Array, frameNo:uint, labeled:int):XML
	{
		var polyXML:XML = LMXMLAnnotation.makeXMLNode("polygon", "");

		return polyXML;

	}
	
	public static function makeXMLString(x:Array, y:Array, frameNo:uint, labeled:int):String
	{
		var str:String = "<polygon>";
		str += "<t>"+frameNo+"</t>";
		for(var i:int = 0; i< x.length; i++)
		{
			str += "<pt><x>"+ x[i] +"</x><y>"+y[i]+ "</y><l>"+ labeled + "</l></pt>"; 
		}
		
		str+="</polygon>";
		return str;
	}
	
	public function get xml():XML 
	{
		return this.getXML();
	}
	
	public function getXML():XML
	{
		//var xml:XML = XML(this);
		return makeXML(_x, _y, _frame, this._labeledBool);
	}			
	
	public function getXMLString():String
	{
		return makeXMLString(_x, _y, _frame, _labeledBool);
	}
	//gives an artificially generated annotation (namely, not created by the user)
	public function clone(withLabelInfo:Boolean = false):LMPolygon
	{
		var p:LMPolygon = ObjectUtil.copy(this) as LMPolygon;
		
		if(!withLabelInfo)
		{
			p._labeledBool = 0;
		}
		return p;
		
	}
	
	public function set color(c:uint):void
	{
		this._color = c;
		
	}	
	
	public function get color():uint
	{
		if(_color <0)
			_color = Annotator._colorPicker.getColor(_oId);
		return _color;
	}
	
	public function get scaleX():Number{
		return scaleX;
	}
	
	public function set polySprite(ps:LMPolygonSprite):void
	{
		this._polySprite = ps;
	}
	
	private function cloneArray(source:Array):Array
	{
		//warning, only works with numbers
		var c:Array = new Array();
		for each (var item:Object in source)
		{
			c.push(item);
		}
		return c;
	}
	
	//serialization functions
	public function readExternal(input:IDataInput):void
	{
		this.frame = input.readInt();
		
		this._x = input.readObject() as Array;
		this._y = input.readObject() as Array;
		this._labeledBool = input.readInt();
		this._frame = input.readInt();
		this._startFrame = input.readInt();
		this._endFrame = input.readInt();
		this._oId = input.readInt();
		this._color = input.readUnsignedInt();
	}
	
	public function writeExternal(output:IDataOutput):void
	{
		output.writeInt(this._frame);
		output.writeObject(_x);
		output.writeObject(_y);
		output.writeInt(this._labeledBool);
		output.writeInt(_frame);
		output.writeInt(_startFrame);
		output.writeInt(_endFrame);
		output.writeInt(_oId);
		output.writeUnsignedInt(this._color);
	}
	
}
}
