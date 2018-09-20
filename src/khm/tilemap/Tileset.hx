package khm.tilemap;

import kha.graphics2.Graphics;
import kha.math.FastMatrix3;
import kha.FastFloat;
import kha.Blob;
import kha.Assets;
import kha.Image;
import khm.Macro;
import khm.Macro.EnumAbstractTools;
import khm.tilemap.Data.Props;

/** Tileset in JSON **/
private typedef TSTiles = {
	tileSize:Int,
	layers:Array<Array<TSProps>>
}

typedef TSProps = {
	> Props,
	?file:String,
	?transformation:TSTransformation,
	?frames:Array<TSProps>,
	?tx:Int, // grid-locked cords
	?ty:Int,
	?x:Int,
	?y:Int
}

@:enum abstract TSTransformation(String) {
	var Rotate90 = "rotate90";
	var Rotate180 = "rotate180";
	var Rotate270 = "rotate270";
	var FlipX = "flipX";
	var FlipY = "flipY";

	public static inline function getIndex(t:TSTransformation):Int {
		return EnumAbstractTools.getIndex(t);
	}
}

/** Tileset parsed data. **/
private typedef TSData = {
	tileSize:Int,
	layersOffsets:Array<Int>,
	tilesLengths:Array<Int>,
	layersLength:Int,
	sprites:Array<Array<TSSprite>>,
	props:Array<Array<Props>>,
	img:Image,
	w:Int,
	h:Int
}

private typedef TSSprite = {
	firstFrame:Int,
	length:Int,
	id:Int
}

class Tileset {

	public var props:Array<Array<Props>>;
	public var layersOffsets:Array<Int>;
	public var tilesLengths:Array<Int>;
	public var layersLength:Int;
	public var sprites:Array<Array<TSSprite>>;
	public var img(default, null):Image;
	public var w(default, null):Int;
	public var h(default, null):Int;
	public var tileSize(default, null):Int;

	public function new(data:Blob):Void {
		var text = data.toString();
		var json:TSTiles = haxe.Json.parse(text);

		var generator = new TilesetGenerator();
		var ts:TSData = generator.fromJSON(json);
		tileSize = ts.tileSize;
		layersOffsets = ts.layersOffsets;
		tilesLengths = ts.tilesLengths;
		layersLength = ts.layersLength;
		sprites = ts.sprites;
		props = ts.props;
		img = ts.img;
		w = ts.w;
		h = ts.h;
	}

}

private class TilesetGenerator {

	var props:Array<Array<Props>>;
	var w:Int;
	var h:Int;
	var tileSize:Int;

	var offX = 0;
	var x = 0;
	var y = 0;
	var next = {
		file: "",
		x: 0,
		y: 0
	};

	public function new():Void {}

	public function fromJSON(json:TSTiles):TSData {
		var layers = json.layers;
		for (layer in layers)
			for (id in 0...layer.length)
				fillProps(layer[id], id);

		tileSize = json.tileSize;
		var layersLength = layers.length;
		var layersOffsets = [0]; // offsets in layers range
		var tilesLengths:Array<Int> = []; // layers tiles length
		var sprites:Array<Array<TSSprite>> = [
			for (layer in layers) []
		];
		props = [ // props for every tile/frame
			for (layer in layers) []
		];

		var tilesCount = countTiles(layers);
		w = Math.ceil(Math.sqrt(tilesCount));
		h = Math.ceil(tilesCount / w);
		var img = Image.createRenderTarget(w * tileSize, h * tileSize);
		var g = img.g2;
		g.begin(true, 0x0);
		pushOffset();

		for (l in 0...layersLength) {
			var layer = layers[l];
			// empty tile properties for every layer
			addProps(l, layer.shift());
			var tilesN = 0;

			for (tile in layer) {
				addTile(g, l, tile);
				tilesN++;
			}

			tilesLengths.push(tilesN);

			// draw sprite frames after all layer tiles
			var spritesN = 0;
			var spriteOffset = 0;

			for (sprite in layer) {
				var len = sprite.frames.length;
				if (len == 0) continue;

				sprites[l][sprite.id] = {
					firstFrame: spriteOffset,
					length: len,
					id: sprite.id
				};
				spriteOffset += len;

				for (tile in sprite.frames) {
					addTile(g, l, tile);
					spritesN++;
				}
			}

			// save layer offset
			var prev = layersOffsets[layersOffsets.length - 1];
			layersOffsets.push(prev + tilesN + spritesN);
		}
		g.end();
		return {
			tileSize: tileSize,
			layersOffsets: layersOffsets,
			tilesLengths: tilesLengths,
			layersLength: layersLength,
			sprites: sprites,
			props: props,
			img: img,
			w: w,
			h: h
		}
	}

	function fillProps(tile:TSProps, id:Int):Void {
		if (tile.id == null) tile.id = id;
		if (tile.file != null) tile.file = ~/(-|\/)/g.replace(tile.file, "_");
		if (tile.frames == null) tile.frames = [];
		else for (frame in tile.frames) {
			if (frame.file != null) frame.file = ~/(-|\/)/g.replace(frame.file, "_");
		}
	}

	function addTile(g:Graphics, l:Int, tile:TSProps):Void {
		var transform = tile.transformation;
		setTransformation(g, transform);
		drawTile(g, tile);
		g.transformation = FastMatrix3.identity();
		if (transform == null) addProps(l, tile);
		else addTransformedProps(l, tile, transform);
	}

	function setTransformation(g:Graphics, transform:TSTransformation):Void {
		if (transform == null) return;
		switch (transform) {
			case Rotate90, Rotate180, Rotate270:
				var angle = 90 + TSTransformation.getIndex(transform) * 90;
				setRotation(g, angle);
			case FlipX:
				setFlipX(g);
			case FlipY:
				setFlipY(g);
			default:
				throw('unknown $transform transformation');
		}
	}

	function countTiles(layers:Array<Array<TSProps>>):Int {
		var count = 1;
		for (layer in layers) {
			for (tile in layer) {
				count += 1 + tile.frames.length;
			}
		}
		return count;
	}

	function getFile(tile:TSProps):Image {
		if (tile.file != null) {
			if (next.file != tile.file) {
				next.x = 0;
				next.y = 0;
			}
			next.file = tile.file;
		}
		if (Assets.images.get(next.file) == null) trace(tile);
		return Assets.images.get(next.file);
	}

	function initTileCords(tile:TSProps, img:Image):Void {
		if (tile.x == null && tile.y == null) {
			if (tile.tx != null && tile.ty != null) {
				tile.x = tile.tx * tileSize;
				tile.y = tile.ty * tileSize;
			} else {
				tile.x = next.x;
				tile.y = next.y;
			}
		}
		var nextCords = tile.y * img.height + tile.x + tileSize;
		next.x = nextCords % (img.width * tileSize);
		next.y = Std.int(nextCords / (img.width * tileSize)) * tileSize;
	}

	function drawTile(g:Graphics, tile:TSProps):Void {
		var img = getFile(tile);
		initTileCords(tile, img);
		g.drawSubImage(img, x, y, tile.x, tile.y, tileSize, tileSize);
		pushOffset();
	}

	function setRotation(g:Graphics, angle:Int):Void {
		g.transformation = g.transformation.multmat(
			rotation(angle * Math.PI / 180, x + tileSize / 2, y + tileSize / 2)
		);
	}

	inline function rotation(angle:FastFloat, centerX:FastFloat, centerY:FastFloat): FastMatrix3 {
		return FastMatrix3.translation(centerX, centerY)
			.multmat(FastMatrix3.rotation(angle))
			.multmat(FastMatrix3.translation(-centerX, -centerY));
	}

	function setFlipX(g:Graphics):Void {
		g.transformation = g.transformation.multmat(
			new FastMatrix3(
				-1, 0, x * 2 + tileSize,
				0, 1, 0,
				0, 0, 1
			)
		);
	}

	function setFlipY(g:Graphics):Void {
		g.transformation = g.transformation.multmat(
			new FastMatrix3(
				1, 0, 0,
				0, -1, y * 2 + tileSize,
				0, 0, 1
			)
		);
	}

	function pushOffset():Void {
		offX += tileSize;
		x = offX % (w * tileSize);
		y = Std.int(offX / (w * tileSize)) * tileSize;
	}

	function addProps(l:Int, tile:TSProps):Void {
		Data.initProps(tile);
		props[l].push(Macro.getTypedObject(tile, Props));
	}

	function addTransformedProps(l:Int, tile:TSProps, type:TSTransformation):Void {
		addProps(l, tile);
		var tile = props[l][props[l].length - 1];
		Data.onTransformedProps(tile, type);
	}

}
