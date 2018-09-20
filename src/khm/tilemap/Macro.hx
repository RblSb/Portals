package khm.tilemap;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

class Macro {

	public static function build(propsType:String):ComplexType {
		var defines = Context.getDefines();
		var path = defines["khmProps"];
		if (path == null) { // use default type
			path = Context.getLocalModule() + '.$propsType';
		}
		var pack = path.split(".");
		propsType = pack.pop();
		path = pack.join(".");

		var module = Context.getModule(path);
		for (type in module) {
			var typePath = type.toString();
			var name = typePath.split(".").pop();
			if (name != propsType) continue;

			var isSubmodule = ~/[A-Z]/.match(path);
			if (isSubmodule) {
				var moduleName = pack.pop();
				return TPath(
					{name: moduleName, sub: name, pack: pack}
				);
			} else return TPath(
				{name: name, pack: pack}
			);
		}
		throw new Error('$path.$propsType not found', Context.currentPos());
	}

}
