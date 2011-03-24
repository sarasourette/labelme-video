package vlm.util
{
	import flash.utils.Dictionary;

	public class DictionaryUtils
	{
		public static function merge(dictionaries:Array):Dictionary
		{
			var merged:Dictionary = new Dictionary();
			for each(var dictionary:Dictionary in dictionaries)
			{
				for(var key:Object in dictionary)
				{
					merged[key] = dictionary[key];
				}
			}
			return merged;
		}
		
		public static function values(dictionary:Dictionary):Array
		{
			var values:Array = new Array();
			for(var key:Object in dictionary)
			{
				values.push(dictionary[key]);
			}
			return values;		
		}
	}
}
