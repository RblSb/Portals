package khm.editor;

import kha.graphics2.Graphics;
import khm.editor.Interfaces.Tool;
import khm.tilemap.Tilemap;
import khm.Screen;
import khm.Screen.Pointer;

class Pipette implements Tool {

	var editor:Editor;
	var tilemap:Tilemap;

	public function new(editor:Editor, tilemap:Tilemap) {
		this.editor = editor;
		this.tilemap = tilemap;
	}

	public function clearHistory():Void {}

	public function undo():Void {}

	public function redo():Void {}

	public function onMouseDown(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		action(layer, x, y, tile);
	}

	public function onMouseMove(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (p.isDown) action(layer, x, y, tile);
	}

	public function onMouseUp(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		action(layer, x, y, tile);
	}

	public function onUpdate():Void {}

	public function onRender(g:Graphics):Void {}

	function action(layer:Int, x:Int, y:Int, tile:Int):Void {
		if (tilemap.getTile(layer, x, y).id == tile) return;
		editor.tile = tilemap.getTile(layer, x, y).id;
	}

}
