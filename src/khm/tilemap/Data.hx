package khm.tilemap;

import khm.tilemap.Tileset.TSTransformation;
import khm.tilemap.Tileset.TSProps;
import khm.tilemap.Tilemap.GameObject;

/** Tile properties structure. `id:Int` property is requered. **/
typedef Props = haxe.macro.MacroType<[khm.tilemap.Macro.build("TileProps")]>;
/** If `-D khmProps=path` doesn't specify a path to the custom Props typedef, this one is used. **/
typedef TileProps = {
	id:Int
}

/** Called from Tileset for more flexible initialization. Functions requered, but can be empty. **/
class Data {

	/** Init every tile object from json. **/
	public static dynamic function initProps(tile:TSProps):Void {
		// if (tile.collide == null) tile.collide = false;
		// if (tile.type == null) tile.type = tile.collide ? "FULL" : "NONE";
	}

	/**
		After json tile initialised, if it has a transformation, this function is called.
	**/
	public static dynamic function onTransformedProps(tile:Props, type:TSTransformation):Void {
		switch (type) {
			case Rotate90: // tile.type = Slope.rotate(tile.type);
			case Rotate180:
			case Rotate270:
			case FlipX:
			case FlipY:
		}
	}

	/**
		Return default object for a specific layer and tile.
	**/
	public static dynamic function objectTemplate(layer:Int, tile:Int):GameObject {
		return switch (layer) {
			case 0:
				switch (tile) {
					// case 0: {type: "chest", layer: layer, x: -1, y: -1, data: data}
					default: null;
				}
			default: null;
		}
	}

}
