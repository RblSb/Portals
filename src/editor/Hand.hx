package editor;

import kha.graphics2.Graphics;
import editor.Interfaces.Tool;
import Screen.Pointer;
import Types.Point;

class Hand implements Tool {
	
	var editor:Editor;
	var lvl:Lvl;
	var speed:Point = {x: 0, y: 0};
	var isDown = false;
	
	public function new(editor:Editor, lvl:Lvl) {
		this.editor = editor;
		this.lvl = lvl;
	}
	
	public function clearHistory():Void {}
	public function undo():Void {}
	public function redo():Void {}
	
	public function onMouseDown(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		isDown = true;
	}
	
	public function onMouseMove(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (!p.isDown) return;
		speed.x = p.moveX;
		speed.y = p.moveY;
		editor.moveCamera(speed);
	}
	
	public function onMouseUp(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
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
