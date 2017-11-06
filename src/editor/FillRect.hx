package editor;

import kha.graphics2.Graphics;
import Types.IPoint;
import Types.IRect;
import editor.Interfaces.Tool;
import editor.Types.ArrHistory;

class FillRect implements Tool {
	
	var undo_h:Array<ArrHistory> = [];
	var redo_h:Array<ArrHistory> = [];
	var HISTORY_MAX = 10;
	var editor:Editor;
	var lvl:Lvl;
	var start:IPoint;
	var end:IPoint;
	
	public function new(editor:Editor, lvl:Lvl) {
		this.editor = editor;
		this.lvl = lvl;
	}
	
	function addHistory(h:ArrHistory):Void {
		undo_h.push(h);
		if (undo_h.length > HISTORY_MAX) undo_h.shift();
		redo_h = [];
	}
	
	public function clearHistory():Void {
		undo_h = [];
		redo_h = [];
	}
	
	inline function history(h1:Array<ArrHistory>, h2:Array<ArrHistory>):Void {
		var hid = h1.length - 1;
		if (hid == -1) return;
		var h = h1[hid];
		var olds:Array<Array<Int>> = [];
		var th = h.y + h.tiles.length;
		var tw = h.x + h.tiles[0].length;
		for (iy in h.y...th) {
			var ty = iy - h.y;
			olds[ty] = [];
			for (ix in h.x...tw) {
				var tx = ix - h.x;
				olds[ty][tx] = lvl.getTile(h.layer, ix, iy);
				if (lvl.getObject(h.layer, ix, iy) != null) continue; //fix
				lvl.setTile(h.layer, ix, iy, h.tiles[ty][tx]);
			}
		}
		
		h2.push({
			layer: h.layer,
			x: h.x,
			y: h.y,
			tiles: olds
		});
		h1.pop();
	}
	
	public function undo():Void {
		history(undo_h, redo_h);
	}
	
	public function redo():Void {
		history(redo_h, undo_h);
	}
	
	public function onMouseDown(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		start = {
			x: x,
			y: y
		};
		end = start;
	}
	
	public function onMouseMove(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (!editor.pointers[id].isDown) return;
		end = {
			x: x,
			y: y
		};
	}
	
	public function onMouseUp(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		end = {
			x: x,
			y: y
		};
		fill(layer, tile);
		start = end = null;
	}
	
	public function onUpdate():Void {}
	
	inline function makeRect(p:IPoint, p2:IPoint):IRect {
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
		var tsize = lvl.tsize;
		g.drawRect(
			rect.x * tsize + lvl.camera.x,
			rect.y * tsize + lvl.camera.y-1,
			(rect.w+1) * tsize+1, (rect.h+1) * tsize+1
		);
	}
	
	inline function fill(layer:Int, tile:Int):Void {
		if (start == null || end == null) return;
		var rect = makeRect(start, end);
		var olds:Array<Array<Int>> = [];
		
		for (iy in rect.y...rect.y+rect.h+1) {
			var ty = iy - rect.y;
			olds[ty] = [];
			for (ix in rect.x...rect.x+rect.w+1) {
				var tx = ix - rect.x;
				if (lvl.getObject(layer, ix, iy) != null) continue; //fix
				olds[ty][tx] = lvl.getTile(layer, ix, iy);
				lvl.setTile(layer, ix, iy, tile);
			}
		}
		addHistory({layer: layer, x: rect.x, y: rect.y, tiles: olds});
	}
	
}
