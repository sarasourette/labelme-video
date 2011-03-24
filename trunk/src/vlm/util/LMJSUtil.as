//-------------------------------------------------------------------------------
//Copyright (c) 2011 Jenny Yuen. 
//MIT Computer Science and Artificial Intelligence Laboratory
//jenny@csail.mit.edu
//------------------------------------------------------------------------------
package vlm.util
{
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.*;
	import mx.controls.Alert;
	
	public class LMJSUtil
	{

	   public static function jsRenderHtml(html:String):void
	   {

		     if (ExternalInterface.available)
		     {
		     	var a = ExternalInterface.call("renderHtml", html);
		     	Alert.show("sent data for js to render" + a);
		     }
		     else
		     {
				Alert.show("error submitting HIT");
		     }
	   }
	   
	   	public static function jsRedirectToUrl(url)
		{
		    var u:URLRequest = new URLRequest(url);
	        navigateToURL(u,"_self");
		}

	}
}
