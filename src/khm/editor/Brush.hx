package khm.editor;

import kha.graphics2.Graphics;
import khm.editor.Interfaces.Tool;
import khm.editor.Types.History;
import khm.tilemap.Tilemap;
import khm.Screen.Pointer;

class Brush implements Tool {

	var undoH:Array<History> = [];
	var redoH:Array<History> = [];
	var maxHistory = 50;
	var editor:Editor;
	var lvl:Tilemap;

	public function new(editor:Editor, lvl:Tilemap) {
		this.editor = editor;
		this.lvl = lvl;
	}

	function addHistory(h:History):Void {
		undoH.push(h);
		if (undoH.length > maxHistory) undoH.shift();
		redoH = [];
	}

	public function clearHistory():Void {
		undoH = [];
		redoH = [];
	}

	inline function history(h1:Array<History>, h2:Array<History>):Void {
		var hid = h1.length - 1;
		if (hid == -1) return;
		var h = h1[hid];

		h2.push({ //save current state
			layer: h.layer,
			x: h.x,
			y: h.y,
			tile: lvl.getTile(h.layer, h.x, h.y).id,
			objs: lvl.getObjects(h.layer, h.x, h.y)
		});

		//return previous state
		lvl.setTileId(h.layer, h.x, h.y, h.tile);
		lvl.setObjects(h.layer, h.x, h.y, h.objs);

		//trace(h.obj);
		h1.pop();
	}

	public function undo():Void {
		history(undoH, redoH);
	}

	public function redo():Void {
		history(redoH, undoH);
	}

	public function onMouseDown(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		action(p, layer, x, y, tile);
	}

	public function onMouseMove(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (!p.isDown) return;
		action(p, layer, x, y, tile);
	}

	public function onMouseUp(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		action(p, layer, x, y, tile);
	}

	public function onUpdate():Void {}

	public function onRender(g:Graphics):Void {}

	function action(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		var old = lvl.getTile(layer, x, y).id;
		if (old == tile) return;

		if (p.type == 1) { //pipette
			editor.tile = old;
			return;
		}

		var objs = lvl.getObjects(layer, x, y);
		addHistory({layer: layer, x: x, y: y, tile: old, objs: objs});

		lvl.setTileId(layer, x, y, tile);
		var newObj = lvl.objectTemplate(layer, tile);
		// if (newObj == null) {
		// 	lvl.setObjects(layer, x, y, []);
		// 	trace(lvl.map.objects);
		// 	return;
		// }
		//newObj.x = x;
		//newObj.y = y;
		lvl.setObjects(layer, x, y, [newObj]);
	}

}
