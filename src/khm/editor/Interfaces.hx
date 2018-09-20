package khm.editor;

import kha.graphics2.Graphics;
import khm.Screen.Pointer;

interface Tool {

	// function setActive():Void;
	function clearHistory():Void;
	function undo():Void;
	function redo():Void;
	function onMouseDown(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void;
	function onMouseMove(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void;
	function onMouseUp(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void;
	function onRender(g:Graphics):Void;
	function onUpdate():Void;

}
