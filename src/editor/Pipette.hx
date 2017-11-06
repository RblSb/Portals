package editor;

import kha.graphics2.Graphics;
import editor.Interfaces.Tool;

class Pipette implements Tool {
	
	var editor:Editor;
	var lvl:Lvl;
	
	public function new(editor:Editor, lvl:Lvl) {
		this.editor = editor;
		this.lvl = lvl;
	}
	
	public function clearHistory():Void {}
	public function undo():Void {}
	public function redo():Void {}
	
	public function onMouseDown(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (lvl.getTile(layer, x, y) == tile) return;
		action(layer, x, y, tile);
	}
	
	public function onMouseMove(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (lvl.getTile(layer, x, y) == tile) return;
		var pointer = editor.pointers[id];
		if (pointer.isDown) action(layer, x, y, tile);
	}
	
	public function onMouseUp(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (lvl.getTile(layer, x, y) == tile) return;
		action(layer, x, y, tile);
	}
	
	public function onUpdate():Void {}
	
	public function onRender(g:Graphics):Void {}
	
	function action(layer:Int, x:Int, y:Int, tile:Int):Void {
		var old = lvl.getTile(layer, x, y);
		editor.pipetteSet(layer, old);
	}
	
}
