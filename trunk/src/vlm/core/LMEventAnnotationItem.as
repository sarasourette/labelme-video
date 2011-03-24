//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.core
{
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;
	import vlm.components.eventcallout.LMEventDisplayCallout;
	
	[RemoteClass(alias="LMEventAnnotationItem")]
	public class LMEventAnnotationItem implements IExternalizable
	{
		public var startFrame:int;
		public var endFrame:int;
		public var createdFrame:int;
		public var tokenLinks:Dictionary;
		public var tokens:Array;
		public var eid:int;
		public var x:int;
		public var y:int;
		public var username:String;
		
		//just the tostring representation
		public var _sentence:String;
		
		public function LMEventAnnotationItem(eid:int=NaN, startFrame:int=NaN, endFrame:int=NaN, createdFrame:int=NaN, tokenLinks:Dictionary=null, tokens:Array=null, x:int=NaN, y:int=NaN, username:String="")
		{
			this.eid = eid;
			this.startFrame = startFrame;
			this.endFrame = endFrame;
			this.createdFrame = createdFrame;
			this.tokenLinks = tokenLinks;
			this.tokens = tokens;
			
			_sentence = "";
			for each (var t:String in tokens)
			{
				_sentence += t + " ";		
			}
			this.x =x;
			this.y = y;
			this.username = username
		}

		public  function toString():String
		{
			_sentence = "";
			for each (var t:String in tokens)
			{
				_sentence += t + " ";		
			}
			return _sentence;
		}
		
		public function getXMLString():String
		{
			var now:Date = new Date();
			
			var str:String = "<event><username>"+username+"</username><startFrame>"+startFrame+"</startFrame><endFrame>"+endFrame+
				"</endFrame><createdFrame>"+createdFrame+"</createdFrame><date>"+now.toString() +"</date><eid>"+eid + "</eid><x>" + x +"</x><y>" +y +"</y><sentence>";
			
			for (var i:int = 0 ; i < tokens.length; i++)
			{	
				str +="<word><text>"+ tokens[i] + "</text>";
				
				
				var arr:ArrayCollection = tokenLinks[i];
				for each (var obId:String in arr)
				{
					str+="<id>"+ obId + "</id>";
				}	
				str +="</word>"
			}
			
			
			str += "</sentence></event>";
			return str;
		}
		
		public function getXML():XML
		{
			var evtXML:XML = LMXMLAnnotation.makeXMLNode("event", "");
			evtXML.appendChild(LMXMLAnnotation.makeXMLNode("username", username));
			evtXML.appendChild(LMXMLAnnotation.makeXMLNode("startFrame", startFrame));
			evtXML.appendChild(LMXMLAnnotation.makeXMLNode("endFrame", endFrame));
			evtXML.appendChild(LMXMLAnnotation.makeXMLNode("createdFrame", createdFrame));
			evtXML.appendChild(LMXMLAnnotation.makeXMLNode("date", new Date()));
			evtXML.appendChild(LMXMLAnnotation.makeXMLNode("eid", eid));
			evtXML.appendChild(LMXMLAnnotation.makeXMLNode("x", x));
			evtXML.appendChild(LMXMLAnnotation.makeXMLNode("y", y));
				
			var sentenceXML:XML = LMXMLAnnotation.makeXMLNode("sentence", "")
			
			for (var i:int = 0 ; i < tokens.length; i++)
			{	
				var wordXML:XML = LMXMLAnnotation.makeXMLNode("word", "")
				wordXML.appendChild(LMXMLAnnotation.makeXMLNode("text", tokens[i]));
				
				var arr:ArrayCollection = tokenLinks[i];
				for each (var obId:String in arr)
				{
					wordXML.appendChild(LMXMLAnnotation.makeXMLNode("id", obId));
				}	
				sentenceXML.appendChild(wordXML);	
			}
			
			evtXML.appendChild(sentenceXML);
			return evtXML;
		}
		
		//generates a sprite containing the 
		public function draw():LMEventDisplayCallout
		{
			var callout:LMEventDisplayCallout = new LMEventDisplayCallout();
			callout.resetLinkerWithEvtItem(this);
			return callout;
		}
		
		public function readExternal(input:IDataInput):void
		{
			startFrame = input.readInt();
			endFrame = input.readInt();
			createdFrame = input.readInt();
			tokenLinks = input.readObject() as Dictionary;
			tokens = input.readObject() as Array;
			eid = input.readInt();
			x = input.readInt();
			y = input.readInt();
		}
		
		public function writeExternal(output:IDataOutput):void
		{
			output.writeInt(startFrame);
			output.writeInt(endFrame);
			output.writeInt(createdFrame);
			output.writeObject(tokenLinks) as Dictionary;
			output.writeObject(tokens) as Array;			
			output.writeInt(eid);
			output.writeInt(x);
			output.writeInt(y);
		}
	}
}
