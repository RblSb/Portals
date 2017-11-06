package editor;

import kha.graphics2.Graphics;
import editor.Interfaces.Tool;
import Lvl.Object;
import Lvl.TField;
import haxe.Json;

class Arrow implements Tool {
	
	var editor:Editor;
	var lvl:Lvl;
	var tsize(get, never):Int;
	function get_tsize() return lvl.tsize;
	var x = 0;
	var y = 0;
	
	public function new(editor:Editor, lvl:Lvl) {
		this.editor = editor;
		this.lvl = lvl;
	}
	
	public function clearHistory():Void {}
	public function undo():Void {}
	public function redo():Void {}
	
	public function onMouseDown(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		this.x = x;
		this.y = y;
		action(layer, x, y, tile);
	}
	
	public function onMouseMove(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		this.x = x;
		this.y = y;
	}
	
	public function onMouseUp(id:Int, layer:Int, x:Int, y:Int, tile:Int):Void {
		this.x = x;
		this.y = y;
	}
	
	public function onUpdate():Void {}
	
	public function onRender(g:Graphics):Void {
		var obj = lvl.getObject(1, x, y);
		if (obj == null) return;
		g.color = 0xFFFF00FF;
		if (obj.doors != null)
		for (i in obj.doors) {
			drawLink(g, obj.x, obj.y, i.x, i.y);
		}
		
		if (obj.speed != null) drawSpeed(g, obj.x, obj.y, obj.speed.x, obj.speed.y);
	}
	
	inline function drawLink(g:Graphics, x:Int, y:Int, x2:Int, y2:Int):Void {
		g.drawLine(
			x * tsize + lvl.camera.x + tsize/2,
			y * tsize + lvl.camera.y + tsize/2,
			x2 * tsize + lvl.camera.x + tsize/2,
			y2 * tsize + lvl.camera.y + tsize/2
		);
	}
	
	inline function drawSpeed(g:Graphics, x:Int, y:Int, sx:Float, sy:Float):Void {
		var x = x * tsize + lvl.camera.x + tsize/2;
		var y = y * tsize + lvl.camera.y + tsize/2;
		g.drawLine(x, y, x + sx * lvl.scale * 3, y + sy * lvl.scale * 3);
	}
	
	function action(layer:Int, x:Int, y:Int, tile:Int):Void {
		var obj = lvl.getObject(1, x, y);
		if (obj != null) {
			if (obj.speed != null) editPanel(obj);
			if (obj.doors != null) editDoors(obj);
			return;
		}
		
		var obj = lvl.getObject(2, x, y);
		if (obj == null) return;
		if (obj.text != null) editText(obj);
	}
	
	inline function editPanel(obj:Object):Void {
		#if kha_html5
		var prompt = js.Browser.window.prompt;
		var upd = Json.parse(prompt('Speed:', Json.stringify(obj.speed)));
		if (upd != null) obj.speed = upd;
		#end
	}
	
	inline function editDoors(obj:Object):Void {
		#if kha_html5
		var prompt = js.Browser.window.prompt;
		var upd = Json.parse(prompt('Doors:', Json.stringify(obj.doors)));
		if (upd != null) obj.doors = upd;
		#end
	}
	
	inline function editText(obj:Object):Void {
		#if kha_html5
		if (!Reflect.hasField(obj.text, Lang.iso))
			Reflect.setField(obj.text, Lang.iso, {text: "", author: ""});
		var tf = Reflect.field(obj.text, Lang.iso);
		var prompt = js.Browser.window.prompt;
		var text = prompt('Text:', tf.text);
		if (text != null) {
			tf.text = text;
			var author = prompt('Author:', tf.author);
			if (author != null) tf.author = author;
		}
		#else
		kha.input.Keyboard.get().show();
		#end
	}
	
}
