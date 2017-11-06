package;

import kha.math.Vector2;
import Types.IPoint;
import Types.Rect;

interface Body {
	var rect:Rect;
	var speed:Vector2;
	var onLand:Bool;
	var rotate:Float;
	var dir:Int;
	function setClone(x:Float, y:Float, ang:Float, dir:Int, tile:IPoint):Void;
}
