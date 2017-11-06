package editor;

import kha.graphics2.Graphics;
import kha.math.Vector2;
import Types.IPoint;
import Types.Rect;

interface Tool {
	//function setActive():Void;
	function clearHistory():Void;
	function undo():Void;
	function redo():Void;
	function onMouseDown(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void;
	function onMouseMove(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void;
	function onMouseUp(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void;
	function onRender(g:Graphics):Void;
	function onUpdate():Void;
}
