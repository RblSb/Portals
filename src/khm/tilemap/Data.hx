package khm.tilemap;

import khm.Macro.EnumAbstractTools;
import khm.tilemap.Tileset.TSTransformation;
import khm.tilemap.Tileset.TSProps;
import khm.tilemap.Tilemap.GameObject;
import khm.Types.Rect;

/** Tile properties structure. `id:Int` property is requered. **/
typedef Props = {
	id:Int,
	collide:Bool,
	type:Slope,
	portalize:Bool,
	permeable:Bool
}

/** Called from Tileset for more flexible initialization. Functions requered, but can be empty. **/
class Data {

	/** Init every tile object from json (function requered). **/
	public static function initProps(tile:TSProps):Void {
		if (tile.collide == null) tile.collide = false;
		if (tile.portalize == null) tile.portalize = false;
		if (tile.permeable == null) tile.permeable = false;
		if (tile.type == null) tile.type = tile.collide ? "FULL" : "NONE";
		else tile.type = Slope.fromString(cast tile.type);
	}

	/**
		After json tile initialised, if it has a transformation, this function is called (function requered).
	**/
	public static function onTransformedProps(tile:Props, type:TSTransformation):Void {
		switch (type) {
			case Rotate90: tile.type = Slope.rotate(tile.type);
			case Rotate180: for (i in 0...2) tile.type = Slope.rotate(tile.type);
			case Rotate270: for (i in 0...3) tile.type = Slope.rotate(tile.type);
			case FlipX: tile.type = Slope.flipX(tile.type);
			case FlipY: tile.type = Slope.flipY(tile.type);
		}
	}

	/**
		Return default object for a specific layer and tile (function requered).
	**/
	public static function objectTemplate(layer:Int, tile:Int):GameObject {
		return switch (layer) {
			case 0: null;
			case 1:
				switch (tile) {
					default: null;
				}
			case 2:
				switch (tile) {
					case 1: obj("player", layer);
					case 2: obj("end", layer);
					case 3: obj("death", layer);
					case 4: obj("save", layer);
					case 5: obj("text", layer, {text: "", author: ""});
					default: null;
				}
			default: null;
		}
	}

	static inline function obj(type:String, layer:Int, ?data:Any):GameObject {
		return {type: type, layer: layer, x: -1, y: -1, data: data};
	}

}

/** Optional custom property example. Used as tile collision type. **/
@:enum
abstract Slope(Int) from Int to Int {

	var NONE = -1;
	var FULL = 0;
	var HALF_B = 1;
	var HALF_T = 2;
	var HALF_L = 3;
	var HALF_R = 4;
	var HALF_BL = 5;
	var HALF_BR = 6;
	var HALF_TL = 7;
	var HALF_TR = 8;
	var QUARTER_BL = 9;
	var QUARTER_BR = 10;
	var QUARTER_TL = 11;
	var QUARTER_TR = 12;

	public inline function new(type:Slope) this = type;

	@:from public static function fromString(type:String):Slope {
		return new Slope(EnumAbstractTools.fromString(type, Slope));
	}

	public static function rotate(type:Slope):Slope {
		return new Slope(switch (type) {
			case HALF_B: HALF_L;
			case HALF_T: HALF_R;
			case HALF_L: HALF_T;
			case HALF_R: HALF_B;
			case HALF_BL: HALF_TL;
			case HALF_BR: HALF_BL;
			case HALF_TL: HALF_TR;
			case HALF_TR: HALF_BR;
			case QUARTER_BL: QUARTER_TL;
			case QUARTER_BR: QUARTER_BL;
			case QUARTER_TL: QUARTER_TR;
			case QUARTER_TR: QUARTER_BR;
			default: type;
		});
	}

	public static function flipX(type:Slope):Slope {
		return new Slope(switch (type) {
			case HALF_L: HALF_R;
			case HALF_R: HALF_L;
			case HALF_BL: HALF_BR;
			case HALF_BR: HALF_BL;
			case HALF_TL: HALF_TR;
			case HALF_TR: HALF_TL;
			case QUARTER_BL: QUARTER_BR;
			case QUARTER_BR: QUARTER_BL;
			case QUARTER_TL: QUARTER_TR;
			case QUARTER_TR: QUARTER_TL;
			default: type;
		});
	}

	public static function flipY(type:Slope):Slope {
		return new Slope(switch (type) {
			case HALF_B: HALF_T;
			case HALF_T: HALF_B;
			case HALF_BL: HALF_TL;
			case HALF_BR: HALF_TR;
			case HALF_TL: HALF_BL;
			case HALF_TR: HALF_BR;
			case QUARTER_BL: QUARTER_TL;
			case QUARTER_BR: QUARTER_TR;
			case QUARTER_TL: QUARTER_BL;
			case QUARTER_TR: QUARTER_BR;
			default: type;
		});
	}

}
