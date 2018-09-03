package khm.editor;

import kha.graphics2.Graphics;
import khm.tilemap.Tilemap;
import khm.Screen;
import khm.Screen.Pointer;

class TilePanel {

	static inline var BG_COLOR = 0xAA000000;
	static inline var GRID_COLOR = 0x50000000;
	static inline var SELECT_COLOR = 0xAAFFFFFF;
	static inline var OVER_ALPHA = 1;
	static inline var OUT_ALPHA = 0.5;
	public var x = 0;
	public var y = 0;
	public var w = 0;
	public var h = 0;
	var editor:Editor;
	var tilemap:Tilemap;
	var tsize(get, never):Int;
	function get_tsize():Int return tilemap.tileSize;
	var minW = 2;
	var maxW = 10;
	var tiles = 0;
	var opacity = OUT_ALPHA;
	var current = 0;

	public function new(editor:Editor, tilemap:Tilemap) {
		this.editor = editor;
		this.tilemap = tilemap;
		resize();
	}

	public function onDown(p:Pointer):Bool {
		var result = false;
		if (isInside(p.x, p.y)) {
			setTile(p);
			result = true;
		}
		return result;
	}

	function setTile(p:Pointer):Void {
		var tx = Std.int((p.x - x) / tsize);
		var ty = Std.int((p.y - y) / tsize);
		var cord = ty * w + tx;
		var pos = countTilePos(cord);
		if (pos.layer == editor.tilesLengths.length) return;
		if (pos.tile != 0) editor.layer = pos.layer;
		editor.tile = pos.tile;
	}

	function countTilePos(tile:Int):{tile:Int, layer:Int} {
		var layer = 0;
		for (len in editor.tilesLengths) {
			if (tile > len) {
				tile -= len;
				layer++;
			} else break;
		}
		return {tile: tile, layer: layer};
	}

	public function onMove(p:Pointer):Bool {
		var result = false;
		if (isInside(p.x, p.y)) {
			opacity = OVER_ALPHA;
			result = true;
		} else opacity = OUT_ALPHA;
		return result;
	}

	public function onUp(p:Pointer):Bool {
		var result = false;
		if (isInside(p.x, p.y)) {
			result = true;
		}
		return result;
	}

	inline function isInside(x:Int, y:Int):Bool {
		if (x < this.x || x >= this.x + w * tsize || y < this.y || y >= this.y + h * tsize) return false;
		return true;
	}

	public function resize():Void {
		update();
	}

	public function update():Void {
		current = currentTile();
		tiles = 1;
		var offs = editor.tilesLengths;
		for (i in offs) tiles += i;

		w = minW;
		for (i in 0...maxW - minW) {
			h = Math.ceil(tiles / w);
			if (y + h * tsize > Screen.h) w++;
		}
		h = Math.ceil(tiles / w);
		x = Screen.w - tsize * w;
	}

	inline function currentTile():Int {
		var id = editor.tile;
		var tilesLengths = editor.tilesLengths;
		for (i in 0...editor.layer) id += tilesLengths[i];
		return id;
	}

	public function render(g:Graphics):Void {
		g.opacity = opacity;
		drawBg(g, x, y, w, h);
		drawGrid(g, x, y, w, h);
		drawTiles(g, x, y, w, h);
		drawSelection(g, x, y, w, h);
		g.opacity = 1;
	}

	function drawBg(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
		g.color = BG_COLOR;
		g.fillRect(x - 1, y, w * tsize + 1, h * tsize);
	}

	function drawTiles(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
		var tilesLengths = editor.tilesLengths;
		var offX = 0;
		var tx = 0;
		var ty = 0;
		g.color = 0xFFFFFFFF;
		for (l in 0...tilesLengths.length) {
			for (id in 0...tilesLengths[l] + 1) {
				if (id == 0 && l != 0) continue;
				editor.drawTile(g, l, x + tx, y + ty, id);
				offX += tsize;
				tx = offX % (w * tsize);
				ty = Std.int(offX / (w * tsize)) * tsize;
			}
		}
	}

	function drawGrid(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
		var tiles = w * h;
		var offX = 0;
		var ix = 0;
		var iy = 0;
		g.color = GRID_COLOR;
		for (i in 0...tiles) {
			g.drawRect(x + ix, y + iy, tsize, tsize);
			offX += tsize;
			ix = offX % (w * tsize);
			iy = Std.int(offX / (w * tsize)) * tsize;
		}
		g.drawLine(x, y, x, y + iy);
	}

	function drawSelection(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
		var offX = editor.tile == 0 ? 0 : current * tsize;
		var ix = offX % (w * tsize);
		var iy = Std.int(offX / (w * tsize)) * tsize;
		g.color = SELECT_COLOR;
		g.drawRect(x + ix, y + iy, tsize, tsize);
	}

}
