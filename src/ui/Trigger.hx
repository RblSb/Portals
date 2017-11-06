package ui;

import haxe.Constraints.Function;
import Types.Rect;

class Trigger {
	
	public var func:Function;
	public var isDown = false;
	public var rect:Rect;
	
	public function new(rect:Rect, ?func:Function) {
		this.rect = rect;
		this.func = func;
	}
	
	public function check(x:Int, y:Int):Bool {
		if (x < rect.x || x > rect.x + rect.w || y < rect.y || y > rect.y + rect.h) return false;
		return true;
	}
	
}
