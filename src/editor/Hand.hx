package editor;

import kha.graphics2.Graphics;
import editor.Interfaces.Tool;
import Types.Point;

class Hand implements Tool {
	
	var editor:Editor;
	var lvl:Lvl;
	var x:Int;
	var y:Int;
	var speed:Point = {x: 0, y: 0};
	var isDown = false;
	
	public function new(editor:Editor, lvl:Lvl) {
		this.editor = editor;
		this.lvl = lvl;
	}
	
	public function clearHistory():Void {}
	public function undo():Void {}
	public function redo():Void {}
	
	public function onMouseDown(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		var pointer = editor.pointers[id];
		this.x = pointer.x;
		this.y = pointer.y;
		isDown = true;
	}
	
	public function onMouseMove(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		var pointer = editor.pointers[id];
		if (!pointer.isDown) return;
		speed.x = pointer.x - this.x;
		speed.y = pointer.y - this.y;
		this.x = pointer.x;
		this.y = pointer.y;
		editor.moveCamera(speed);
	}
	
	public function onMouseUp(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		isDown = false;
	}
	
	public function onUpdate():Void {
		if (isDown) return;
		if (speed.x == 0 && speed.y == 0) return;
		if (speed.x != 0) speed.x -= Std.int(Math.abs(speed.x)/speed.x);
		if (speed.y != 0) speed.y -= Std.int(Math.abs(speed.y)/speed.y);
		editor.moveCamera(speed);
	}
	
	public function onRender(g:Graphics):Void {}
	
}
