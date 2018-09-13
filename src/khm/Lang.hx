package khm;

import kha.System;
import kha.Assets;
import kha.Blob;
import haxe.Json;

private typedef LangMap = Map<String, String>;

class Lang {

	public static var ids(default, null):Array<String>;
	public static var langs(default, null):Array<LangMap>;
	public static var iso(default, null):String;
	public static var fontGlyphs(default, null):Array<Int>;
	static var current(default, null):LangMap;
	static var basic(default, null):LangMap;

	public static function loadFolder(folder:String):Void {
		ids = [];
		langs = [];
		var fields = Reflect.fields(Assets.blobs);
		for (field in fields) {
			if (field.indexOf(folder) == -1) continue;
			var ereg = new EReg(folder + "_(.*)_json$", "");
			if (!ereg.match(field)) continue;

			var id = ereg.matched(1);
			ids.push(id);
			var file = Assets.blobs.get(field);
			var data = Json.parse(file.toString());
			var lang = new LangMap();
			var keys = Reflect.fields(data);
			for (key in keys) {
				lang[key] = Reflect.field(data, key);
			}
			langs.push(lang);
		}
	}

	public static function set(?code:String, def = "en"):Void {
		iso = code == null ? System.language : code;
		var defId = -1;
		var id = -1;
		for (i in 0...ids.length) {
			var lang = ids[i];
			if (lang == def) defId = i;
			if (lang == iso) id = i;
		}

		if (defId == -1) throw 'default language file ($def) not found';
		if (id == -1) id = defId;
		current = langs[id];
		basic = langs[defId];
		setGlyphs();
	}

	static function setGlyphs():Void {
		var code = iso.substr(0, 2);
		fontGlyphs = [];
		for (i in 32...256) {
			fontGlyphs.push(i);
		}
		switch (code) {
			case "ru":
				for (i in 1024...1106) {
					fontGlyphs.push(i);
				}
			default:
		}
	}

	public static function get(id:String):String {
		if (current[id] != null) return current[id];
		if (basic[id] != null) return basic[id];
		return id;
	}

	public static inline function fastGet(id:String):String {
		return current[id];
	}

}
