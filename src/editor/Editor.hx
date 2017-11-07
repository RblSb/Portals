package editor;

import kha.Framebuffer;
import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.Assets;
import kha.Image;
import ui.Button;
import game.Game;
import editor.Interfaces.Tool;
import Lvl.GameMap;
import Types.IPoint;
import Types.Point;
import Types.ISize;
import Types.Rect;
import haxe.Json;

class Editor extends Screen {
	
	var buttons:Array<Button>;
	var arrow:Arrow;
	var brush:Brush;
	var fillRect:FillRect;
	var pipette:Pipette;
	var hand:Hand;
	var toolName:String;
	var tool(default, set):Tool;
	function set_tool(tool) {
		this.tool = tool;
		var arr = Type.getClassName(Type.getClass(tool)).split(".");
		toolName = arr[arr.length-1];
		return tool;
	}
	var lvl:Lvl;
	
	var tsize(get, never):Int;
	function get_tsize() return lvl.tsize;
	var cursor:IPoint = {x: 0, y: 0};
	var layer = 1;
	var layerOffsets:Array<Int> = [5, 10, 5];
	var tiles:Array<Int> = [];
	var x = 0;
	var y = 0;
	
	public function new() {
		super();
	}
	
	public function init():Void {
		#if kha_html5
		var window = js.Browser.window;
		window.ondragenter = function(e) {
			e.preventDefault();
		};
		window.ondragover = function(e) {
			e.preventDefault();
		};
		window.ondrop = drop;
		#end
		
		lvl = new Lvl();
		lvl.init();
		lvl.loadMap(0);
		
		arrow = new Arrow(this, lvl);
		brush = new Brush(this, lvl);
		fillRect = new FillRect(this, lvl);
		pipette = new Pipette(this, lvl);
		hand = new Hand(this, lvl);
		tool = brush;
		
		for (i in layerOffsets) tiles.push(0);
		initButtons();
	}
	
	inline function initButtons():Void {
		var i = Assets.images;
		
		buttons = [
			new Button({x: 0, y: tsize, img: i.icons_arrow, keys: [KeyCode.M]}),
			new Button({x: 0, y: tsize*2, img: i.icons_paint_brush, keys: [KeyCode.B]}),
			new Button({x: 0, y: tsize*3, img: i.icons_assembly_area, keys: [KeyCode.R]}),
			new Button({x: 0, y: tsize*4, img: i.icons_pipette, keys: [KeyCode.P]}),
			new Button({x: Screen.w - tsize, y: 0, img: i.icons_play, keys: [KeyCode.Zero]})
		];
		if (Screen.touch) buttons = buttons.concat([
			new Button({x: 0, y: tsize*5, img: i.icons_hand, keys: [KeyCode.H]}),
			new Button({x: 0, y: Screen.h - tsize, img: i.icons_turn, keys: [KeyCode.Control, KeyCode.Z]}),
			new Button({x: tsize, y: Screen.h - tsize, img: i.icons_turn, keys: [KeyCode.Control, KeyCode.Y]})
		]);
	}
	
	//@:allow(Pipette)
	public function pipetteSet(layer:Int, tile:Int):Void {
		tiles[layer] = tile;
	}
	
	//@:allow(Hand)
	public function moveCamera(speed:Point):Void {
		lvl.camera.x += speed.x;
		lvl.camera.y += speed.y;
		updateCamera();
	}
	
	override function onKeyDown(key:KeyCode):Void {
		if (keys[KeyCode.Control] || keys[224] || keys[15]) {
			
			if (key == KeyCode.Z || key == 1103) {
				if (!keys[KeyCode.Shift]) tool.undo();
				else tool.redo();
			}
			if (key == KeyCode.Y || key == 1085) tool.redo();
			
			if (key == KeyCode.S || key == 1099) {
				keys[KeyCode.S] = false;
				keys[1099] = false;
				save(lvl.map);
			}
		}
		
		if (key == KeyCode.M) {
			tool = arrow;
		
		} else if (key == KeyCode.B) {
			tool = brush;
			
		} else if (key == KeyCode.R) {
			tool = fillRect;
			
		} else if (key == KeyCode.P) {
			tool = pipette;
			
		} else if (key == KeyCode.H) {
			tool = hand;
			
		} else if (key == KeyCode.O) {
			browse();
			
		} else if (key == KeyCode.N) {
			createMap();
			
		} else if (key == KeyCode.Q) {
			tiles[layer]--;
			if (tiles[layer] < 0) tiles[layer] = layerOffsets[layer];
			if (tiles[layer] > layerOffsets[layer]) tiles[layer] = 0;
			
		} else if (key == KeyCode.E) {
			tiles[layer]++;
			if (tiles[layer] < 0) tiles[layer] = layerOffsets[layer];
			if (tiles[layer] > layerOffsets[layer]) tiles[layer] = 0;
			
		} else if (key == KeyCode.Zero) {
			var game = new Game();
			game.show();
			game.init(this);
			game.playCustomLevel(lvl.map);
			
		} else if (key == KeyCode.One) {
			layer = 0;
		} else if (key == KeyCode.Two) {
			layer = 1;
		} else if (key == KeyCode.Three) {
			layer = 2;
			
		} else if (key == 189 || key == KeyCode.HyphenMinus) {
			if (scale > 1) setScale(scale - 1);
			
		} else if (key == KeyCode.Equals) {
			if (scale < 9) setScale(scale + 1);
			
		} else if (key == KeyCode.Escape) {
			#if kha_html5
			var confirm = js.Browser.window.confirm;
			if (!confirm(Lang.get("reset_warning")+" "+Lang.get("are_you_sure"))) return;
			#end
			var menu = new Menu();
			menu.show();
			menu.init(); //2
		}
	}
	
	function createMap():Void {
		#if kha_html5
		var prompt = js.Browser.window.prompt;
		var newSize = Json.stringify({w: 20, h: 20});
		var size:ISize = Json.parse(prompt("Map Size:", newSize));
		if (size == null) return;
		var map:GameMap = {
			w: size.w,
			h: size.h,
			layers: [
				for (l in 0...lvl.map.layers.length) [
					for (iy in 0...size.h) [
						for (ix in 0...size.w) l == 0 ? 1 : 0
					]
				]
			],
			objects: {}
		}
		onMapLoad(map);
		#end
	}
	
	function save(map:GameMap, name="map"):Void {
		var json = haxe.Json.stringify(map);
		#if kha_html5
		var blob = new js.html.Blob([json], {
			type: "application/json"
		});
		var url = js.html.URL.createObjectURL(blob);
		var a = js.Browser.document.createElement("a");
		name = map.name == null ? name : map.name;
		untyped a.download = name+".json";
		untyped a.href = url;
		a.onclick = function(e) {
			e.cancelBubble = true;
			e.stopPropagation();
		}
		js.Browser.document.body.appendChild(a);
		a.click();
		js.Browser.document.body.removeChild(a);
		js.html.URL.revokeObjectURL(url);
		#else
		//TODO select path and write file
		#end
	}
	
	function browse():Void {
		#if kha_html5
		var input = js.Browser.document.createElement("input");
		input.style.visibility = "hidden";
		input.setAttribute("type", "file");
		input.id = "browse";
		input.onclick = function(e) {
			e.cancelBubble = true;
			e.stopPropagation();
		}
		input.onchange = function() {
			untyped var file:Dynamic = input.files[0];
			var name = file.name.split(".")[0];
			var ext = file.name.split(".").pop();
			var reader = new js.html.FileReader();
			reader.onload = function(e) {
				if (ext == "lvl") onFileLoad(e.target.result);
				else onMapLoad(haxe.Json.parse(e.target.result), name);
				js.Browser.document.body.removeChild(input);
			}
			if (ext == "lvl") reader.readAsArrayBuffer(file);
			else reader.readAsText(file);
		}
		js.Browser.document.body.appendChild(input);
		input.click();
		#else
		#end
	}
	
	#if kha_html5
	function drop(e:js.html.DragEvent):Void {
		var file = e.dataTransfer.files[0];
		var name = file.name.split(".")[0];
		var ext = file.name.split(".").pop();
		var reader = new js.html.FileReader();
		reader.onload = function(event) {
			if (ext == "lvl") onFileLoad(event.target.result);
			else onMapLoad(haxe.Json.parse(event.target.result), name);
		}
		e.preventDefault();
		if (ext == "lvl") reader.readAsArrayBuffer(file);
		else reader.readAsText(file);
	}
	
	inline function onFileLoad(file:Dynamic) {
		var bytes = haxe.io.Bytes.ofData(file);
		var blob = kha.Blob.fromBytes(bytes);
		var map = Old.loadMap(blob);
		onMapLoad(map);
	}
	#end
	
	inline function onMapLoad(map:GameMap, ?name:String) {
		if (name != null) map.name = name;
		lvl.loadCustomMap(map);
		clearHistory();
	}
	
	inline function clearHistory() {
		arrow.clearHistory();
		brush.clearHistory();
		fillRect.clearHistory();
		pipette.clearHistory();
		hand.clearHistory();
	}
	
	inline function updateCursor(pointer):Void {
		cursor.x = pointer.x;
		cursor.y = pointer.y;
		x = Std.int(cursor.x / tsize - lvl.camera.x / tsize);
		y = Std.int(cursor.y / tsize - lvl.camera.y / tsize);
		if (x < 0) x = 0;
		if (y < 0) y = 0;
		if (x > lvl.w-1) x = lvl.w-1;
		if (y > lvl.h-1) y = lvl.h-1;
	}
	
	override function onMouseDown(id:Int):Void {
		var pointer = pointers[id];
		if (Button.onDown(this, buttons, pointer)) return;
		
		updateCursor(pointer);
		tool.onMouseDown(id, layer, x, y, tiles[layer]);
	}
	
	override function onMouseMove(id:Int):Void {
		var pointer = pointers[id];
		if (Button.onMove(this, buttons, pointer)) return;
		updateCursor(pointer);
		tool.onMouseMove(id, layer, x, y, tiles[layer]);
	}
	
	override function onMouseUp(id:Int):Void {
		var pointer = pointers[id];
		if (Button.onUp(this, buttons, pointer)) return;
		tool.onMouseUp(id, layer, x, y, tiles[layer]);
	}
	
	override function onResize():Void {
		var newScale = Std.int(Utils.getScale());
		if (newScale < 1) newScale = 1;
		
		if (newScale != scale) setScale(newScale);
		else {
			lvl.resize();
		}
	}
	
	override function onRescale(scale:Float):Void {
		lvl.rescale(scale);
	}
	
	override function onUpdate():Void {
		tool.onUpdate();
		
		if (lvl.w * tsize < Screen.w
			&& lvl.h * tsize < Screen.h) return;
		
		var sx = 0.0, sy = 0.0, s = tsize/5;
		if (keys[KeyCode.Left] || keys[KeyCode.A]) sx += s;
		if (keys[KeyCode.Right] || keys[KeyCode.D]) sx -= s;
		if (keys[KeyCode.Up] || keys[KeyCode.W]) sy += s;
		if (keys[KeyCode.Down] || keys[KeyCode.S]) sy -= s;
		if (keys[KeyCode.Shift]) {
			sx *= 2; sy *= 2;
		}
		if (sx != 0) lvl.camera.x += sx;
		if (sy != 0) lvl.camera.y += sy;
		updateCamera();
	}
	
	inline function updateCamera():Void {
		var w = Screen.w;
		var h = Screen.h;
		var pw = lvl.map.w * tsize;
		var ph = lvl.map.h * tsize;
		var camera = lvl.camera;
		var offset = tsize;
		
		if (camera.x > offset) camera.x = offset;
		if (camera.x < w - pw - offset) camera.x = w - pw - offset;
		if (camera.y > offset) camera.y = offset;
		if (camera.y < h - ph - offset) camera.y = h - ph - offset;
		if (pw < w) camera.x = w/2 - pw/2;
		if (ph < h) camera.y = h/2 - ph/2;
		camera.x = Std.int(camera.x);
		camera.y = Std.int(camera.y);
	}
	
	override function onRender(frame:Framebuffer):Void {
		var g = frame.g2;
		g.begin(true, 0xFFBDC3CD);
		lvl.drawLayers(g);
		
		tool.onRender(g);
		drawCursor(g);
		for (b in buttons) b.draw(g);
		
		g.color = 0xFF000000;
		g.font = Assets.fonts.OpenSans_Regular;
		g.fontSize = 24;
		g.fontGlyphs = Lang.fontGlyphs;
		var s = ""+layer+" | "+tiles[layer]+" | "+lvl.countObjects(layer)+" | "+toolName;
		g.drawString(s, 0, 0);
		var fh = g.font.height(g.fontSize, Lang.fontGlyphs);
		g.drawString(""+x+", "+y, 0, fh);
		
		#if debug
		for (i in 0...10) {
			if (!pointers[i].used) continue;
			if (pointers[i].isDown) g.color = 0xFFFF0000;
			else g.color = 0xFFFFFFFF;
			g.fillRect(pointers[i].x-1, pointers[i].y-1, 2, 2);
		}
		#end
		debugScreen(g);
		g.end();
	}
	
	inline function drawCursor(g:Graphics):Void {
		if (tool == hand) return;
		g.color = 0x88000000;
		var px = x * tsize + lvl.camera.x;
		var py = y * tsize + lvl.camera.y;
		g.drawRect(px, py-1, tsize+1, tsize+1);
		if (tool == arrow) return;
		
		if (tiles[layer] == 0) {
			g.color = 0x88FF0000;
			g.drawLine(px, py, px + tsize, py + tsize);
			g.drawLine(px + tsize, py, px, py + tsize);
		}
		if (tiles[layer] < 1) return;
		g.color = 0xFFFFFFFF;
		lvl.drawTile(g, layer, x, y, tiles[layer]);
	}
	
}
