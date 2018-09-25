package khm.editor;

import kha.Canvas;
import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.Assets;
import khm.editor.ui.Button;
import khm.editor.Interfaces.Tool;
import khm.tilemap.Tilemap;
import khm.tilemap.Tilemap.GameMap;
import khm.tilemap.Tilemap.GameMapJSON;
import khm.tilemap.Tile;
import khm.tilemap.Tileset;
import khm.Screen;
import khm.Screen.Pointer;
import khm.utils.FileReference;
import khm.Lang;
import khm.Types.IPoint;
import khm.Types.Point;
import khm.Types.ISize;
import haxe.Json;

class Editor extends Screen {

	var tilemap:Tilemap;
	var tsize(get, never):Int;
	function get_tsize():Int return tilemap.tileSize;
	static inline var BTN_SIZE = 48;
	var tilePanel:TilePanel;
	var buttons:Array<Button>;
	var arrow:Arrow;
	var brush:Brush;
	var fillRect:FillRect;
	var pipette:Pipette;
	var hand:Hand;
	var toolName:String;
	var tool(default, set):Tool;
	function set_tool(tool):Tool {
		this.tool = tool;
		var arr = Type.getClassName(Type.getClass(tool)).split(".");
		toolName = arr[arr.length - 1];
		return tool;
	}
	public var tilesLengths(get, never):Array<Int>;
	function get_tilesLengths():Array<Int> {
		return @:privateAccess tilemap.tileset.tilesLengths;
	}
	public var layer = 0;
	public var tile(get, set):Int;
	function get_tile():Int return tiles[layer];
	function set_tile(tile):Int {
		tiles[layer] = tile;
		return tile;
	}
	var tiles:Array<Int> = [];
	var cursor:IPoint = {x: 0, y: 0};
	var eraserMode = {tile: 0, layer: 0};
	var isGridEnabled = false;
	var x = 0;
	var y = 0;

	public function init():Void {
		FileReference.onDrop(onFileLoad, false);

		tilemap = new Tilemap();
		var tileset = new Tileset(Assets.blobs.tiles_json);
		tilemap.init(tileset);
		var map = newMap({w: 10, h: 10});
		tilemap.loadMap(map);

		tilePanel = new TilePanel(this, tilemap);
		arrow = new Arrow(this, tilemap);
		brush = new Brush(this, tilemap);
		fillRect = new FillRect(this, tilemap);
		pipette = new Pipette(this, tilemap);
		hand = new Hand(this, tilemap);
		tool = brush;

		for (i in tilesLengths) tiles.push(0);
		initButtons();
		onResize();
	}

	function initButtons():Void {
		var i = Assets.images;
		var h = BTN_SIZE;

		buttons = [
			new Button({x: 0, y: h, img: i.icons_arrow, keys: [KeyCode.M]}),
			new Button({x: 0, y: h * 2, img: i.icons_paint_brush, keys: [KeyCode.B]}),
			new Button({x: 0, y: h * 3, img: i.icons_assembly_area, keys: [KeyCode.R]}),
			new Button({x: 0, y: h * 4, img: i.icons_pipette, keys: [KeyCode.P]}),
			new Button({x: Screen.w - h - tilePanel.w * tsize, y: 0, img: i.icons_play, keys: [KeyCode.Zero]})
		];
		if (Screen.isTouch) buttons = buttons.concat([
			new Button({x: 0, y: h * 5, img: i.icons_hand, keys: [KeyCode.H]}),
			new Button({x: 0, y: Screen.h - h, img: i.icons_undo, keys: [KeyCode.Control, KeyCode.Z]}),
			new Button({x: h, y: Screen.h - h, img: i.icons_redo, keys: [KeyCode.Control, KeyCode.Y]})
		]);
	}

	@:allow(khm.editor.Hand)
	function moveCamera(speed:Point):Void {
		tilemap.camera.x += speed.x;
		tilemap.camera.y += speed.y;
		updateCamera();
	}

	override function onKeyDown(key:KeyCode):Void {
		if (keys[KeyCode.Control] || keys[KeyCode.Meta]) {

			if (key == KeyCode.Z) {
				if (!keys[KeyCode.Shift]) tool.undo();
				else tool.redo();
			}
			if (key == KeyCode.Y) tool.redo();

			if (key == KeyCode.S) {
				keys[KeyCode.S] = false;
				keys[KeyCode.Control] = keys[KeyCode.Meta] = false;
				save(tilemap.map);
			}
		}

		if (key == KeyCode.Space) {
			eraserMode.layer = layer;
			eraserMode.tile = tile;
			tile = 0;

		} else if (key == KeyCode.M) {
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

		} else if (key == KeyCode.Nine) {
			resizeMap();

		} else if (key == KeyCode.Q) {
			prevTile();

		} else if (key == KeyCode.E) {
			nextTile();

		} else if (key == KeyCode.G) {
			isGridEnabled = !isGridEnabled;

		} else if (key == KeyCode.Zero) {
			testMap(this, tilemap);

		} else if (key - KeyCode.One >= 0 && key - KeyCode.One <= 9) {
			var newLayer = key - KeyCode.One;
			if (newLayer < tilemap.map.layers.length) layer = newLayer;

		} else if (key == 189 || key == KeyCode.HyphenMinus) {
			if (scale > 1) setScale(scale - 1);

		} else if (key == 187 || key == KeyCode.Equals) {
			if (scale < 9) setScale(scale + 1);

		} else if (key == KeyCode.Escape) {
			#if (kha_html5 || kha_debug_html5)
			var confirm = js.Browser.window.confirm;
			if (!confirm(Lang.get("reset_warning") + " " + Lang.get("are_you_sure"))) return;
			#end
			exit();
		}
	}

	public static dynamic function testMap(editor:Editor, tilemap:Tilemap):Void {}

	public static dynamic function exit():Void {}

	override function onKeyUp(key:KeyCode):Void {
		if (key == KeyCode.Space) {
			layer = eraserMode.layer;
			tile = eraserMode.tile;
		}
	}

	function prevTile():Void {
		tile--;
		if (tile < 0) tile = tilesLengths[layer];
		if (tile > tilesLengths[layer]) tile = 0;
	}

	function nextTile():Void {
		tile++;
		if (tile < 0) tile = tilesLengths[layer];
		if (tile > tilesLengths[layer]) tile = 0;
	}

	function createMap():Void {
		#if (kha_html5 || kha_debug_html5)
		var prompt = js.Browser.window.prompt;
		var newSize = Json.stringify({w: 20, h: 20});
		var size:ISize = Json.parse(prompt("Map Size:", newSize));
		if (size == null) return;
		var map = newMap(size);
		onMapLoad(map);
		#end
	}

	function newMap(size:ISize):GameMap {
		var layersLength = @:privateAccess tilemap.tileset.layersLength;
		var map:GameMap = {
			w: size.w,
			h: size.h,
			layers: [
				for (l in 0...layersLength) [
					for (iy in 0...size.h) [
						for (ix in 0...size.w) new Tile(tilemap, l, 0)
					]
				]
			],
			objects: [],
			floatObjects: []
		}
		return map;
	}

	function resizeMap():Void {
		#if (kha_html5 || kha_debug_html5)
		var prompt = js.Browser.window.prompt;
		var addSize = Json.stringify([0, 1, 0, 1]);
		var size:Array<Int> = Json.parse(
			prompt("Add Size [SX, EX, SY, EY]:", addSize)
		);
		if (size == null) return;
		var map = tilemap.map;
		for (l in 0...map.layers.length)
			resizeLayer(l, size, true);

		var sx = size[0];
		var ex = size[1];
		var sy = size[2];
		var ey = size[3];
		map.h += sy + ey;
		map.w += sx + ex;

		onMapLoad(map);
		#end
	}

	function resizeLayer(l:Int, size:Array<Int>, isFill:Bool):Void {
		var layer = tilemap.map.layers[l];
		var sx = size[0];
		var ex = size[1];
		var sy = size[2];
		var ey = size[3];
		inline function newTile():Tile {
			return new Tile(tilemap, l, 0);
		}

		var len = Std.int(Math.abs(sy));
		for (i in 0...len) {
			if (sy < 0) layer.shift();
			else {
				layer.unshift([]);
				for (tile in layer[1]) {
					var newTile = isFill ? tile.copy() : newTile();
					layer[0].push(newTile);
				}
			}
		}

		var len = Std.int(Math.abs(ey));
		for (i in 0...len) {
			if (ey < 0) layer.pop();
			else {
				layer.push([]);
				var h = layer.length - 1;
				for (tile in layer[h - 1]) {
					var tile = isFill ? tile.copy() : newTile();
					layer[h].push(tile);
				}
			}
		}

		var len = Std.int(Math.abs(sx));
		for (i in 0...len)
			for (iy in 0...layer.length) {
				if (sx < 0) layer[iy].shift();
				else {
					var tile = isFill ? layer[iy][0].copy() : newTile();
					layer[iy].unshift(tile);
				}
			}

		var len = Std.int(Math.abs(ex));
		for (i in 0...len) {
			for (iy in 0...layer.length) {
				if (ex < 0) layer[iy].pop();
				else {
					var w = layer[iy].length - 1;
					var id = isFill ? layer[iy][w].copy() : newTile();
					layer[iy].push(id);
				}
			}
		}
	}

	function save(map:GameMap, name = "map"):Void {
		var data = tilemap.toJSON(map);
		#if (kha_html5 || kha_debug_html5)
		FileReference.saveJSON(name, Json.stringify(data));
		#else
		// TODO select path and write file
		#end
	}

	function browse():Void {
		#if (kha_html5 || kha_debug_html5)
		FileReference.browse(onFileLoad, false);
		#else
		// TODO browse path
		#end
	}

	function onFileLoad(file:Any, name:String):Void {
		var ext = name.split(".").pop();
		var name = name.split(".")[0];
		switch (ext) {
			case "json":
				onMapJSONLoad(Json.parse(file), name);
			// case "lvl":
			// 	var bytes = haxe.io.Bytes.ofData(file);
			// 	var blob = kha.Blob.fromBytes(bytes);
			// 	var map = Old.loadMap(blob);
			// 	onMapLoad(map);
			default:
				trace('unknown file extension $ext');
		}
	}

	function onMapJSONLoad(map:GameMapJSON, ?name:String):Void {
		onMapLoad(tilemap.fromJSON(map), name);
	}

	function onMapLoad(map:GameMap, ?name:String):Void {
		if (name != null) map.name = name;
		tilemap.loadMap(map);
		clearHistory();
	}

	function clearHistory():Void {
		arrow.clearHistory();
		brush.clearHistory();
		fillRect.clearHistory();
		pipette.clearHistory();
		hand.clearHistory();
	}

	function updateCursor(pointer):Void {
		cursor.x = pointer.x;
		cursor.y = pointer.y;
		x = Std.int(cursor.x / tsize - tilemap.camera.x / tsize);
		y = Std.int(cursor.y / tsize - tilemap.camera.y / tsize);
		if (x < 0) x = 0;
		if (y < 0) y = 0;
		if (x > tilemap.w - 1) x = tilemap.w - 1;
		if (y > tilemap.h - 1) y = tilemap.h - 1;
	}

	override function onMouseDown(p:Pointer):Void {
		if (tilePanel.onDown(p)) return;
		if (Button.onDown(this, buttons, p)) return;
		updateCursor(p);
		tool.onMouseDown(p, layer, x, y, tile);
	}

	override function onMouseMove(p:Pointer):Void {
		if (tilePanel.onMove(p)) return;
		if (Button.onMove(this, buttons, p)) return;
		updateCursor(p);
		tool.onMouseMove(p, layer, x, y, tile);
	}

	override function onMouseUp(p:Pointer):Void {
		if (tilePanel.onUp(p)) return;
		if (Button.onUp(this, buttons, p)) return;
		tool.onMouseUp(p, layer, x, y, tile);
	}

	override function onMouseWheel(delta:Int):Void {
		if (delta == 1) prevTile();
		else if (delta == -1) nextTile();
	}

	override function onResize():Void {
		tilePanel.resize();
		initButtons();
	}

	override function onUpdate():Void {
		tilePanel.update();
		tool.onUpdate();

		var sx = 0.0;
		var sy = 0.0;
		var s = tsize / 5;
		if (keys[KeyCode.Left] || keys[KeyCode.A]) sx += s;
		if (keys[KeyCode.Right] || keys[KeyCode.D]) sx -= s;
		if (keys[KeyCode.Up] || keys[KeyCode.W]) sy += s;
		if (keys[KeyCode.Down] || keys[KeyCode.S]) sy -= s;
		if (keys[KeyCode.Shift]) {
			sx *= 2;
			sy *= 2;
		}
		if (sx != 0) tilemap.camera.x += sx;
		if (sy != 0) tilemap.camera.y += sy;
		updateCamera();
	}

	function updateCamera():Void {
		var w = Screen.w;
		var h = Screen.h;
		var pw = tilemap.w * tsize;
		var ph = tilemap.h * tsize;
		var camera = tilemap.camera;
		var offset = BTN_SIZE;
		var maxW = w - pw - offset - tilePanel.w * tsize;
		var maxH = h - ph - offset;

		if (camera.x > offset) camera.x = offset;
		if (camera.x < maxW) camera.x = maxW;
		if (camera.y > offset) camera.y = offset;
		if (camera.y < maxH) camera.y = maxH;
		if (pw < w - offset * 2 - tilePanel.w * tsize) camera.x = w / 2 - pw / 2;
		if (ph < h - offset * 2) camera.y = h / 2 - ph / 2;
		camera.x = Std.int(camera.x);
		camera.y = Std.int(camera.y);
	}

	override function onRender(frame:Canvas):Void {
		var g = frame.g2;
		g.begin(true, 0xFFBDC3CD);
		g.color = 0x50000000;
		g.drawRect(tilemap.camera.x, tilemap.camera.y - 1,
			tilemap.w * tsize + 1,
			tilemap.h * tsize + 1
		);
		tilemap.drawLayers(g);

		tool.onRender(g);
		drawGrid(g);
		drawCursor(g);
		for (b in buttons) b.draw(g);
		tilePanel.render(g);

		g.color = 0xFF000000;
		g.font = Assets.fonts.OpenSans_Regular;
		g.fontSize = 24;
		var s = 'Layer: ${layer + 1} | Tile: $tile | Objects: ${tilemap.map.objects.length}';
		g.drawString(s, 0, 0);
		var fh = g.font.height(g.fontSize);
		g.drawString('$toolName | $x, $y', 0, fh);

		g.end();
	}

	function drawGrid(g:Graphics):Void {
		if (!isGridEnabled) return;
		g.color = 0x15000000;
		for (ix in 0...tilemap.w) {
			for (iy in 0...tilemap.h) {
				g.drawRect(
					tilemap.camera.x + ix * tsize + 1,
					tilemap.camera.y + iy * tsize,
					tsize - 1, tsize - 1
				);
			}
		}
	}

	function drawCursor(g:Graphics):Void {
		if (tool == hand) return;
		g.color = 0x88000000;
		var px = x * tsize + tilemap.camera.x;
		var py = y * tsize + tilemap.camera.y - 1;
		g.drawRect(px, py, tsize + 1, tsize + 1);
		if (tool == arrow) return;

		if (tile == 0) {
			g.color = 0x88FF0000;
			g.drawLine(px, py + 1, px + tsize, py + tsize + 1);
			g.drawLine(px + tsize, py + 1, px, py + tsize + 1);
		}
		if (tile < 1) return;
		g.color = 0xFFFFFFFF;
		drawTile(
			g, layer,
			x * tsize + tilemap.camera.x,
			y * tsize + tilemap.camera.y,
			tile
		);
	}

	public function drawTile(g:Graphics, layer:Int, x:Float, y:Float, id:Int):Void {
		if (id <= 0) return;
		var tileset = @:privateAccess tilemap.tileset;
		id += tileset.layersOffsets[layer];
		var tx = (id % tileset.w) * tsize;
		var ty = Std.int(id / tileset.w) * tsize;
		g.drawSubImage(
			tileset.img, x, y,
			tx, ty, tsize, tsize
		);
	}

}
