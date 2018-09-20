package game;

import kha.Canvas;
import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.Image;
import kha.Assets;
import kha.math.Vector2;
import khm.editor.Editor;
import khm.tilemap.Tilemap;
import khm.tilemap.Tileset;
import khm.tilemap.Tilemap.GameMap;
import khm.tilemap.Tilemap.GameMapJSON;
import khm.Screen;
import khm.Screen.Pointer;
import khm.Settings;
import khm.Lang;
import khm.Types.IPoint;
import khm.Types.Rect;

typedef AutoSave = {
	map:GameMap,
	player:IPoint
}

class Game extends Screen {

	var player:Player;
	var touch:Touch;
	var tilemap:Tilemap;
	var editor:Editor;
	var viewMode = false;
	var autoSave:AutoSave;
	var textField = new TextField();
	var currentLevel:Int;
	var levelProgress:Int;
	var particlers:Array<Particler> = [];

	public function new() {
		super();
	}

	public function init(?editor:Editor):Void {
		this.editor = editor;
		tilemap = new Tilemap();
		CustomData.init();
		var tileset = new Tileset(Assets.blobs.tiles_json);
		tilemap.init(tileset);
		textField.init(scale);
		player = new Player();

		var sets = Settings.read();
		currentLevel = -1;
		levelProgress = sets.levelProgress;
	}

	public function playCompany():Void {
		currentLevel = levelProgress;
		loadMapId(levelProgress);
		newGame();
	}

	public function playLevel(id:Int):Void {
		currentLevel = id;
		loadMapId(id);
		newGame();
	}

	public function playCustomLevel(map:GameMapJSON):Void {
		tilemap.loadJSON(map);
		newGame();
	}

	public static inline function isMapExists(id:Int):Bool {
		return Assets.blobs.get("maps_" + id + "_json") != null;
	}

	public function loadMapId(id:Int):Void {
		var data = Assets.blobs.get("maps_" + id + "_json");
		tilemap.loadJSON(haxe.Json.parse(data.toString()));
	}

	function getPlayer():IPoint {
		for (iy in 0...tilemap.map.h) {
			for (ix in 0...tilemap.map.w) {
				if (tilemap.getTile(2, ix, iy).id == 1) return {x: ix, y: iy};
			}
		}
		return {x: 0, y: 0};
	}

	function newGame():Void {
		player.init(this, tilemap);
		restart();
		autoSave = {
			map: tilemap.copyMap(tilemap.map),
			player: getPlayer()
		};
		if (Screen.isTouch) {
			touch = new Touch(this);
			touch.init();
		}

		onResize();
	}

	public function restart():Void {
		var spawn = getPlayer();
		if (autoSave != null) {
			spawn.x = autoSave.player.x;
			spawn.y = autoSave.player.y;
			tilemap.loadMap(autoSave.map);
		}
		var rect = player.rect;
		rect.x = spawn.x * tilemap.tileSize + (tilemap.tileSize - rect.w)/2;
		rect.y = spawn.y * tilemap.tileSize + (tilemap.tileSize - rect.h);
		if (player.speed.x != 0)
			player.speed.x = Math.abs(player.speed.x)/player.speed.x;
		if (player.speed.y != 0)
			player.speed.y = Math.abs(player.speed.y)/player.speed.y;
		player.rotate = 0;
		Portal.removeAll();
		particlers = [];
		textField.close(true);
		for (i in keys.keys()) keys[i] = false;
	}

	public function checkpoint(x:Int, y:Int):Void {
		if (autoSave != null) {
			if (autoSave.player.x == x || autoSave.player.y == y) return;
		}
		autoSave = {
			map: tilemap.copyMap(tilemap.map),
			player: {x: x, y: y}
		};
	}

	public function showText(x:Int, y:Int):Void {
		var obj = tilemap.getObject(2, x, y, "text");
		if (obj == null) return;
		var tf = Reflect.field(obj.data.text, Lang.iso);
		if (tf == null) {
			if (Lang.iso == "en") return;
			tf = Reflect.field(obj.data.text, "en");
			if (tf == null) return;
		}

		textField.show(tf.text, tf.author);
		tilemap.setTileId(2, x, y, 0);
	}

	public function closeText():Void {
		textField.close();
	}

	public function showEditor():Void {
		editor.show();
	}

	public function transferParticles(particler:Particler):Void {
		if (particler.particles.length == 0) return;
		var p:Particler = particler;
		p.loop = false;
		var wobble = p.particles[0].wobble;
		var max = Math.max(Math.abs(wobble.x), Math.abs(wobble.y));
		for (i in p.particles) {
			i.speed = new Vector2();
			i.wobble = new Vector2(Math.abs(max), Math.abs(max));
		}
		particlers.push(p);
	}

	public function levelComplete():Void {
		if (editor != null) {
			showEditor();
			return;
		}

		currentLevel++;
		if (currentLevel > levelProgress && isMapExists(currentLevel)) {
			autoSave = null;
			levelProgress = currentLevel;
			Settings.set({
				levelProgress: levelProgress
			});
			setScale(1);
			playCompany();
			return;
		}

		var menu = new Menu();
		menu.show();
		menu.init(1);
	}

	override function onKeyDown(key:KeyCode):Void {
		if (key == KeyCode.Q) {
			viewMode = !viewMode;

		} else if (key == KeyCode.Zero) {
			setScale(1);

		} else if (key == 189 || key == KeyCode.HyphenMinus) {
			if (scale > 1) setScale(scale - 0.5);

		} else if (key == 187 || key == KeyCode.Equals) {
			if (scale < 9) setScale(scale + 0.5);

		} else if (key == KeyCode.Escape) {
			var bg = Image.createRenderTarget(Screen.w, Screen.h);
			onRender(bg);
			var menu = new PauseMenu(this, editor, bg);
			menu.show();
			menu.init();
			menu.setScale(scale);
		}
	}

	override function onMouseDown(p:Pointer):Void {
		if (Screen.isTouch) if (touch.onDown(p)) return;
		player.onMouseDown(p);
	}

	override function onMouseMove(p:Pointer):Void {
		if (Screen.isTouch) if (touch.onMove(p)) return;
	}

	override function onMouseUp(p:Pointer):Void {
		if (Screen.isTouch) if (touch.onUp(p)) return;
		player.onMouseUp(p);
	}

	override function onResize():Void {
		tilemap.camera.w = Screen.w;
		tilemap.camera.h = Screen.h;
		if (Screen.isTouch) touch.resize();
		if (true) return;
		var min = Math.min(Screen.w, Screen.h);
		var newScale = Std.int(min / 500 * 2) / 2;
		if (newScale < 1) newScale = 1;
		if (newScale != scale) setScale(newScale);
	}

	override function onRescale(scale:Float):Void {
		tilemap.scale = scale;
		if (Screen.isTouch) touch.resize();
	}

	override function onUpdate():Void {
		player.update();
		Sprite.updateAll();
		Portal.updateAll();
		for (p in particlers) {
			p.update();
			if (p.particles.length == 0) particlers.remove(p);
		}
		if (!viewMode) {
			player.keys();
			tilemap.camera.center(player.rect);
		} else viewModeCamera();
	}

	function viewModeCamera():Void {
		if (tilemap.w * tilemap.tileSize < Screen.w
			&& tilemap.h * tilemap.tileSize < Screen.h) viewMode = false;

		var sx = 0.0, sy = 0.0, s = tilemap.tileSize/5;
		if (keys[KeyCode.Left] || keys[KeyCode.A]) sx += s;
		if (keys[KeyCode.Right] || keys[KeyCode.D]) sx -= s;
		if (keys[KeyCode.Up] || keys[KeyCode.W]) sy += s;
		if (keys[KeyCode.Down] || keys[KeyCode.S]) sy -= s;
		if (keys[KeyCode.Shift]) {
			sx *= 2; sy *= 2;
		}
		if (sx != 0) tilemap.camera.x += sx;
		if (sy != 0) tilemap.camera.y += sy;
	}

	override function onRender(frame:Canvas):Void {
		var g = frame.g2;
		g.begin(true, 0xFFBDC3CD);
		tilemap.drawLayer(g, 0);
		Portal.renderAllEffects(g);
		player.draw(g);
		tilemap.drawLayer(g, 1);
		Portal.renderAll(g);
		for (p in particlers) p.draw(g, tilemap.camera.x, tilemap.camera.y);
		textField.draw(g);

		if (viewMode) {
			g.color = 0xFFFFFFFF;
			g.drawRect(1, 0, Screen.w-1, Screen.h-2);
		}
		if (Screen.isTouch) touch.draw(g);

		//tilemap.drawLayer(g, 2);
		//drawTileset(g);
		//drawPointers(g);
		g.end();
	}

	function drawPointers(g:Graphics):Void {
		#if debug
		for (p in pointers) {
			if (!p.isActive) continue;
			if (p.isDown) g.color = 0xFFFF0000;
			else g.color = 0xFFFFFFFF;
			g.fillRect(p.x-1, p.y-1, 2, 2);
		}
		#end
	}

	function drawTileset(g:Graphics):Void {
		#if debug
		var tileset = @:privateAccess tilemap.tileset;
		var scale = 1;
		var x = tilemap.camera.w - tileset.img.width * scale;
		g.color = 0xFFFFFFFF;
		g.drawScaledImage(
			tileset.img, x, 0,
			tileset.img.width * scale,
			tileset.img.height * scale
		);
		#end
	}

}
