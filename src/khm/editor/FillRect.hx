package khm.editor;

import kha.graphics2.Graphics;
import khm.editor.Interfaces.Tool;
import khm.editor.Types.ArrHistory;
import khm.tilemap.Tilemap;
import khm.Screen;
import khm.Screen.Pointer;
import khm.Types.IPoint;
import khm.Types.IRect;

class FillRect implements Tool {

	var undoH:Array<ArrHistory> = [];
	var redoH:Array<ArrHistory> = [];
	var maxHistory = 10;
	var editor:Editor;
	var tilemap:Tilemap;
	var start:IPoint;
	var end:IPoint;

	public function new(editor:Editor, tilemap:Tilemap) {
		this.editor = editor;
		this.tilemap = tilemap;
	}

	function addHistory(h:ArrHistory):Void {
		undoH.push(h);
		if (undoH.length > maxHistory) undoH.shift();
		redoH = [];
	}

	public function clearHistory():Void {
		undoH = [];
		redoH = [];
	}

	inline function history(h1:Array<ArrHistory>, h2:Array<ArrHistory>):Void {
		var hid = h1.length - 1;
		if (hid == -1) return;
		var h = h1[hid];

		var olds = copyRect(h.rect, h.layer);
		fillTiles(h.rect, h.layer, h.tiles);

		h2.push({
			layer: h.layer,
			rect: h.rect,
			tiles: olds
		});
		h1.pop();
	}

	public function undo():Void {
		history(undoH, redoH);
	}

	public function redo():Void {
		history(redoH, undoH);
	}

	public function onMouseDown(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		start = {
			x: x,
			y: y
		};
		end = start;
	}

	public function onMouseMove(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (!p.isDown) return;
		end = {
			x: x,
			y: y
		};
	}

	public function onMouseUp(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (p.type == 1) {
			if (x == start.x && y == start.y) {
				editor.tile = tilemap.getTile(layer, x, y).id;
				start = end = null;
				return;
			}
			//else clear area
			tile = 0;
		}
		end = {
			x: x,
			y: y
		};
		fill(layer, tile);
		start = end = null;
	}

	public function onUpdate():Void {}

	function makeRect(p:IPoint, p2:IPoint):IRect {
		var sx = p.x < p2.x ? p.x : p2.x;
		var sy = p.y < p2.y ? p.y : p2.y;
		var ex = p.x < p2.x ? p2.x : p.x;
		var ey = p.y < p2.y ? p2.y : p.y;
		return {x: sx, y: sy, w: ex - sx, h: ey - sy};
	}

	public function onRender(g:Graphics):Void {
		if (start == null || end == null) return;
		g.color = 0xFFFF00FF;
		var rect = makeRect(start, end);
		var tsize = tilemap.tileSize;
		g.drawRect(
			rect.x * tsize + tilemap.camera.x - 1,
			rect.y * tsize + tilemap.camera.y - 2,
			(rect.w + 1) * tsize + 3, (rect.h + 1) * tsize + 3
		);
	}

	function fill(layer:Int, tile:Int):Void {
		if (start == null || end == null) return;
		var rect = makeRect(start, end);

		var newObj = tilemap.objectTemplate(layer, tile);
		if (newObj != null) return;

		var olds = copyRect(rect, layer);
		fillRect(rect, layer, tile);

		addHistory({layer: layer, rect: rect, tiles: olds});
	}

	function copyRect(rect:IRect, layer:Int):Array<Array<Int>> {
		var arr:Array<Array<Int>> = [];
		for (iy in rect.y...rect.y + rect.h + 1) {
			var ty = iy - rect.y;
			arr[ty] = [];
			for (ix in rect.x...rect.x + rect.w + 1) {
				var tx = ix - rect.x;
				arr[ty][tx] = tilemap.getTile(layer, ix, iy).id;
			}
		}
		return arr;
	}

	function fillRect(rect:IRect, layer:Int, tile:Int):Void {
		for (iy in rect.y...rect.y + rect.h + 1)
			for (ix in rect.x...rect.x + rect.w + 1) {
				tilemap.setTileId(layer, ix, iy, tile);
			}
	}

	function fillTiles(rect:IRect, layer:Int, tiles:Array<Array<Int>>):Void {
		for (iy in rect.y...rect.y + rect.h + 1) {
			var ty = iy - rect.y;
			for (ix in rect.x...rect.x + rect.w + 1) {
				var tx = ix - rect.x;
				tilemap.setTileId(layer, ix, iy, tiles[ty][tx]);
			}
		}
	}

}
