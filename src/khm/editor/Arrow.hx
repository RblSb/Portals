package khm.editor;

import kha.graphics2.Graphics;
import khm.editor.Interfaces.Tool;
import khm.editor.ui.Modal;
import khm.Screen.Pointer;
import khm.tilemap.Tilemap;
import khm.tilemap.Tilemap.GameObject;
import haxe.Json;

class Arrow implements Tool {

	var editor:Editor;
	var tilemap:Tilemap;
	var tsize(get, never):Int;
	function get_tsize():Int return tilemap.tileSize;
	var x = 0;
	var y = 0;

	public function new(editor:Editor, tilemap:Tilemap) {
		this.editor = editor;
		this.tilemap = tilemap;
	}

	public function clearHistory():Void {}
	public function undo():Void {}
	public function redo():Void {}

	public function onMouseDown(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		this.x = x;
		this.y = y;
		action(layer, x, y, tile);
	}

	public function onMouseMove(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		this.x = x;
		this.y = y;
	}

	public function onMouseUp(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		this.x = x;
		this.y = y;
	}

	public function onUpdate():Void {}

	public function onRender(g:Graphics):Void {}

	function action(layer:Int, x:Int, y:Int, tile:Int):Void {
		var objs = tilemap.getObjects(layer, x, y);
		if (objs.length == 0) { //check other layers
			for (i in 0...tilemap.map.layers.length) {
				layer = i;
				objs = tilemap.getObjects(layer, x, y);
				if (objs.length != 0) break;
			}
		}
		if (objs.length == 0) return;
		#if kha_html5
		Modal.prompt("Object:", Json.stringify(objs, "  "), function(data:String) {
			var objs:Array<GameObject> = Json.parse(data);
			if (objs != null) tilemap.setObjects(layer, x, y, objs);
		});
		#end
	}

}
