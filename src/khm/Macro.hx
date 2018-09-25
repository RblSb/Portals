package khm;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

class EnumAbstractTools {

	macro public static function fromString(name:Expr, typePath:Expr):Expr {
		var type = Context.getType(typePath.toString());
		var name = name.toString();
		switch (type.follow()) {
			case TAbstract(_.get() => ab, _) if (isEnumAbstract(ab)):
				var code = 'switch($name) {';
				for (field in ab.impl.get().statics.get()) {
					if (isEnumAbstractField(field)) {
						code += 'case "${field.name}": ${field.name};';
					}
				}
				code += 'default: throw("Unknown case " + $name);}';
				return Context.parse(code, Context.currentPos());
			default:
				throw new Error(type.toString() + " should be @:enum abstract", typePath.pos);
		}
	}

	macro public static function getIndex(typePath:Expr):Expr {
		var type = Context.typeof(typePath);
		var name = typePath.toString();
		var index = 0;
		switch (type.follow()) {
			case TAbstract(_.get() => ab, _) if (isEnumAbstract(ab)):
				var code = 'switch($name) {';
				for (field in ab.impl.get().statics.get()) {
					if (isEnumAbstractField(field)) {
						code += 'case ${field.name}: $index;';
						index++;
					}
				}
				code += "}";
				return Context.parse(code, Context.currentPos());
			default:
				throw new Error(type.toString() + " should be @:enum abstract", typePath.pos);
		}
	}

	static function isEnumAbstract(ab:AbstractType):Bool {
		return ab.meta.has(":enum");
	}

	static function isEnumAbstractField(field:ClassField):Bool {
		return field.meta.has(":enum") && field.meta.has(":impl");
	}

}

class Macro {

	macro public static function getTypedObject(obj:Expr, typePath:Expr):Expr {
		var type = Context.getType(typePath.toString());
		switch (type.follow()) {
			case TAnonymous(_.get() => td):
				var name = obj.toString();
				var code = "{";
				for (field in td.fields) {
					code += '${field.name}: $name.${field.name}, ';
				}
				code += "}";
				return Context.parse(code, Context.currentPos());
			default:
				throw new Error(type.toString() + " should be type", typePath.pos);
		}
	}

	macro public static function getBuildTime():Expr {
		return macro $v{Date.now().toString()};
	}

}
