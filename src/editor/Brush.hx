package editor;

import kha.graphics2.Graphics;
import editor.Interfaces.Tool;
import editor.Types.History;
import Screen.Pointer;

class Brush implements Tool {
	
	var undo_h:Array<History> = [];
	var redo_h:Array<History> = [];
	var HISTORY_MAX = 50;
	var editor:Editor;
	var lvl:Lvl;
	
	public function new(editor:Editor, lvl:Lvl) {
		this.editor = editor;
		this.lvl = lvl;
	}
	
	function addHistory(h:History):Void {
		undo_h.push(h);
		if (undo_h.length > HISTORY_MAX) undo_h.shift();
		redo_h = [];
	}
	
	public function clearHistory():Void {
		undo_h = [];
		redo_h = [];
	}
	
	inline function history(h1:Array<History>, h2:Array<History>):Void {
		var hid = h1.length - 1;
		if (hid == -1) return;
		var h = h1[hid];
		
		h2.push({
			layer: h.layer,
			x: h.x,
			y: h.y,
			tile: lvl.getTile(h.layer, h.x, h.y),
			obj: lvl.getObject(h.layer, h.x, h.y),
			objType: h.objType
		});
		
		lvl.setTile(h.layer, h.x, h.y, h.tile);
		lvl.setObject(h.layer, h.x, h.y, h.objType, h.obj);
		//trace(lvl.getTile(h.layer, h.x, h.y), lvl.getObject(h.layer, h.x, h.y));
		trace(h.objType, h.obj);
		h1.pop();
	}
	
	public function undo():Void {
		history(undo_h, redo_h);
	}
	
	public function redo():Void {
		history(redo_h, undo_h);
	}
	
	public function onMouseDown(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (lvl.getTile(layer, x, y) == tile) return;
		action(layer, x, y, tile);
	}
	
	public function onMouseMove(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (lvl.getTile(layer, x, y) == tile) return;
		if (p.isDown) action(layer, x, y, tile);
	}
	
	public function onMouseUp(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (lvl.getTile(layer, x, y) == tile) return;
		action(layer, x, y, tile);
	}
	
	public function onUpdate():Void {}
	
	public function onRender(g:Graphics):Void {}
	
	function action(layer:Int, x:Int, y:Int, tile:Int):Void {
		var old = lvl.getTile(layer, x, y);
		var obj = lvl.getObject(layer, x, y);
		var objType = obj == null ? tile : old;
		addHistory({layer: layer, x: x, y: y, tile: old, obj: obj, objType: objType});
		lvl.setTile(layer, x, y, tile);
		
		lvl.setObject(layer, x, y, old, null);
		var newObj = lvl.emptyObject(layer, tile, x, y);
		lvl.setObject(layer, x, y, tile, newObj);
	}
	
}
