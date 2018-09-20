package khm.tilemap;

import kha.graphics2.Graphics;
import kha.Image;
import kha.Assets;
import kha.System;
import kha.Blob;
import khm.tilemap.Data.Props;
import khm.Types.Rect;
import khm.Types.IPoint;

typedef GameMapJSON = {
	?version:Int,
	?name:String,
	w:Int,
	h:Int,
	layers:Array<Array<Array<Int>>>,
	objects:Array<GameObject>,
	floatObjects:Array<FloatObject>
}

typedef GameMap = { // map format
	?version:Int,
	?name:String,
	w:Int,
	h:Int,
	layers:Array<Array<Array<Tile>>>,
	objects:Array<GameObject>,
	floatObjects:Array<FloatObject>
}

typedef GameObject = {
	// grid-based
	type:String,
	layer:Int,
	x:Int,
	y:Int,
	data:Dynamic
}

typedef FloatObject = {
	type:String,
	rect:Rect,
	data:Dynamic
}

class Tilemap {

	public var map(default, null):GameMap;
	public var w(get, never):Int;
	public var h(get, never):Int;
	inline function get_w():Int return map.w;
	inline function get_h():Int return map.h;
	public var tileSize(get, never):Int;
	inline function get_tileSize():Int return tileset.tileSize;
	public var camera:Camera;
	public var scale = 1.0;
	var tileset:Tileset;

	public function new() {}

	public function init(tileset:Tileset):Void {
		this.tileset = tileset;
		camera = new Camera(this);
	}

	public function loadMap(map:GameMap):Void {
		this.map = copyMap(map);
	}

	public function loadJSON(map:GameMapJSON):Void {
		this.map = copyMap(fromJSON(map));
	}

	public function fromJSON(map:GameMapJSON):GameMap {
		var layers:Array<Array<Array<Tile>>> = [
			for (l in 0...map.layers.length) [
				for (iy in 0...map.layers[l].length) [
					for (ix in 0...map.layers[l][iy].length)
						new Tile(this, l, map.layers[l][iy][ix])
				]
			]
		];
		return {
			name: map.name,
			w: map.w,
			h: map.h,
			layers: layers,
			objects: map.objects,
			floatObjects: map.floatObjects
		}
	}

	public function toJSON(map:GameMap):GameMapJSON {
		var layers:Array<Array<Array<Int>>> = [
			for (l in 0...map.layers.length) [
				for (iy in 0...map.layers[l].length) [
					for (ix in 0...map.layers[l][iy].length)
						map.layers[l][iy][ix].id
				]
			]
		];
		return {
			name: map.name,
			w: map.w,
			h: map.h,
			layers: layers,
			objects: map.objects,
			floatObjects: map.floatObjects
		}
	}

	public function copyMap(map:GameMap):GameMap {
		var layers:Array<Array<Array<Tile>>> = [
			for (l in map.layers) [
				for (iy in 0...l.length) [
					for (ix in 0...l[iy].length)
						l[iy][ix].copy()
				]
			]
		];
		var objects:Array<GameObject> = [
			for (obj in map.objects) Reflect.copy(obj)
		];
		var floatObjects:Array<FloatObject> = [
			for (obj in map.floatObjects) Reflect.copy(obj)
		];
		return {
			name: map.name,
			w: map.w,
			h: map.h,
			layers: layers,
			objects: objects,
			floatObjects: floatObjects
		}
	}

	public inline function isInside(x:Int, y:Int):Bool {
		return x > -1 && y > -1 && x < map.w && y < map.h;
	}

	public function getTile(layer:Int, x:Int, y:Int):Tile {
		if (!isInside(x, y)) return new Tile(this, layer, 0);
		return map.layers[layer][y][x];
	}

	public function setTile(layer:Int, x:Int, y:Int, tile:Tile):Void {
		if (!isInside(x, y)) return;
		map.layers[layer][y][x] = tile;
	}

	public function setTileId(layer:Int, x:Int, y:Int, id:Int):Void {
		if (!isInside(x, y)) return;
		map.layers[layer][y][x].id = id;
	}

	public function drawLayer(g:Graphics, l:Int):Void {
		// screen in tiles
		var screenW = Math.ceil(camera.w / tileSize) + 1;
		var screenH = Math.ceil(camera.h / tileSize) + 1;
		// camera in tiles
		var ctx = -Std.int(camera.x / tileSize);
		var cty = -Std.int(camera.y / tileSize);
		var ctw = ctx + screenW;
		var cth = cty + screenH;
		var camX = Std.int(camera.x * scale) / scale;
		var camY = Std.int(camera.y * scale) / scale;

		// tiles offset
		var sx = ctx < 0 ? 0 : ctx;
		var sy = cty < 0 ? 0 : cty;
		var ex = ctw > map.w ? map.w : ctw;
		var ey = cth > map.h ? map.h : cth;
		g.color = 0xFFFFFFFF;

		for (iy in sy...ey) {
			for (ix in sx...ex) {
				var tile = map.layers[l][iy][ix];
				var id = tile.id;
				if (id > 0) {
					var layer = map.layers[l][iy][ix].layer;
					if (tile.frame > 0) {
						id = tileset.layersOffsets[layer];
						id += tileset.tilesLengths[layer];
						id += tileset.sprites[layer][tile.id].firstFrame + tile.frame;
					} else {
						id += tileset.layersOffsets[layer];
					}
					g.drawSubImage(
						tileset.img,
						ix * tileSize + camX,
						iy * tileSize + camY,
						(id % tileset.w) * tileSize,
						Std.int(id / tileset.w) * tileSize,
						tileSize, tileSize
					);
				}
			}
		}
	}

	public function drawLayers(g:Graphics):Void {
		for (i in 0...map.layers.length) drawLayer(g, i);
	}

	public function getObject(layer:Int, x:Int, y:Int, type:String):GameObject {
		for (obj in map.objects) {
			if (
				obj.x == x && obj.y == y &&
				obj.layer == layer && obj.type == type
			) return obj;
		}
		return null;
	}

	public function getObjects(layer:Int, x:Int, y:Int):Array<GameObject> {
		var arr:Array<GameObject> = [];
		for (obj in map.objects) {
			if (obj.x == x && obj.y == y && obj.layer == layer) arr.push(obj);
		}
		return arr;
	}

	public function setObject(layer:Int, x:Int, y:Int, type:String, data:Any):Void {
		if (data == null) {
			deleteObject(layer, x, y, type);
			return;
		}
		var obj = getObject(layer, x, y, type);
		if (obj != null) {
			obj.data = data;
			return;
		}
		map.objects.push({
			type: type,
			layer: layer,
			x: x,
			y: y,
			data: data
		});
	}

	public function setObjects(layer:Int, x:Int, y:Int, objs:Array<GameObject>):Void {
		var oldObjs = getObjects(layer, x, y);
		for (obj in oldObjs) map.objects.remove(obj);
		for (obj in objs) {
			if (obj != null) {
				if (obj.layer != layer) obj.layer = layer;
				if (obj.x != x) obj.x = x;
				if (obj.y != y) obj.y = y;
				map.objects.push(obj);
			}
		}
	}

	public function deleteObject(layer:Int, x:Int, y:Int, type:String):Void {
		var obj = getObject(layer, x, y, type);
		if (obj != null) map.objects.remove(obj);
	}

	public function objectTemplate(layer:Int, tile:Int):GameObject {
		return Data.objectTemplate(layer, tile);
	}

}
