package;

import kha.Storage;
import kha.StorageFile;

private typedef SettingsData = {
	?v:Int,
	?levelProgress:Int,
	?musicVolume:Int,
	?lang:String,
	?controlType:Int,
	?touchMode:Bool
}

class Settings {
	
	static inline var v = 1;
	static var defaults:SettingsData = {
		v: v,
		levelProgress: 1,
		controlType: 1
	};
	
	public static function read():SettingsData {
		var file = Storage.defaultFile();
		var data:SettingsData = file.readObject();
		data = checkData(data);
		return data;
	}
	
	public static function set(sets:SettingsData):Void {
		var data = read();
		
		var fields = Reflect.fields(sets);
		for (field in fields) {
			var value = Reflect.field(sets, field);
			Reflect.setField(data, field, value);
		}
		
		write(data);
	}
	
	public static function write(data:SettingsData):Void {
		var file = Storage.defaultFile();
		data.v = v;
		file.writeObject(data);
	}
	
	public static function reset():Void {
		var data = checkData(null);
		write(data);
	}
	
	static inline function checkData(data:SettingsData):SettingsData {
		if (data != null && data.v == v) return data;
		return defaults;
	}
	
}
