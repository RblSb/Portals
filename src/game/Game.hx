package game;

import kha.Framebuffer;
import kha.input.KeyCode;
import kha.Image;
import kha.math.Vector2;
import editor.Editor;
import Types.IPoint;
import Types.Rect;

typedef AutoSave = {
	map:Lvl.GameMap,
	player:IPoint
}

class Game extends Screen {
	
	//var backbuffer = Image.create(1, 1);
	var player:Player;
	var touch:Touch;
	var lvl:Lvl;
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
		lvl = new Lvl();
		lvl.init();
		textField.init(scale);
		player = new Player();
		
		var sets = Settings.read();
		currentLevel = -1;
		levelProgress = sets.levelProgress;
	}
	
	public function playCompany():Void {
		currentLevel = levelProgress;
		lvl.loadMap(levelProgress);
		newGame();
	}
	
	public function playLevel(id:Int):Void {
		currentLevel = id;
		lvl.loadMap(id);
		newGame();
	}
	
	public function playCustomLevel(map:Lvl.GameMap):Void {
		lvl.loadCustomMap(map);
		newGame();
	}
	
	function newGame():Void {
		player.init(this, lvl);
		restart();
		autoSave = {
			map: lvl.copyMap(lvl.map),
			player: lvl.getPlayer()
		};
		if (Screen.touch) {
			touch = new Touch(this);
			touch.init();
		}
		
		onResize();
	}
	
	public function restart():Void {
		var spawn = lvl.getPlayer();
		if (autoSave != null) {
			spawn.x = autoSave.player.x;
			spawn.y = autoSave.player.y;
			lvl.loadCustomMap(autoSave.map);
		}
		var rect = player.rect;
		rect.x = spawn.x * lvl.tsize + (lvl.tsize - rect.w)/2;
		rect.y = spawn.y * lvl.tsize + (lvl.tsize - rect.h);
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
			map: lvl.copyMap(lvl.map),
			player: {x: x, y: y}
		};
	}
	
	public function showText(x:Int, y:Int):Void {
		var obj = lvl.getObject(2, x, y);
		if (obj == null) return;
		var tf = Reflect.field(obj.text, Lang.iso);
		if (tf == null) {
			if (Lang.iso == "en") return;
			tf = Reflect.field(obj.text, "en");
			if (tf == null) return;
		}
		
		textField.show(tf.text, tf.author);
		lvl.setTile(2, x, y, 0);
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
		if (currentLevel > levelProgress && Lvl.exists(currentLevel)) {
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
			if (scale > 1) setScale(scale - 1);
			
		} else if (key == KeyCode.Equals) {
			if (scale < 9) setScale(scale + 1);
			
		} else if (key == KeyCode.Escape) {
			var menu = new PauseMenu(this, editor);
			menu.show();
			menu.init();
		}
	}
	
	override function onMouseDown(id:Int):Void {
		if (Screen.touch) if (touch.onDown(id)) return;
		player.onMouseDown(id);
	}
	
	override function onMouseMove(id:Int):Void {
		if (Screen.touch) if (touch.onMove(id)) return;
	}
	
	override function onMouseUp(id:Int):Void {
		if (Screen.touch) if (touch.onUp(id)) return;
		player.onMouseUp(id);
	}
	
	override function onResize():Void {
		var newScale = Std.int(Utils.getScale());
		if (newScale < 1) newScale = 1;
		
		if (newScale != scale) setScale(newScale);
		else {
			lvl.resize();
		}
		if (Screen.touch) touch.resize();
		
		//if (Std.int(w/scale) != backbuffer.width || Std.int(h/scale) != backbuffer.height)
			//backbuffer = Image.createRenderTarget(Std.int(w/scale), Std.int(h/scale));
	}
	
	override function onRescale(scale:Float):Void {
		lvl.rescale(scale);
		player.rescale(scale);
		Portal.rescaleAll();
		textField.rescale(scale);
		for (particler in particlers)
			particler.rescale(scale);
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
			lvl.setCamera(player.rect);
		} else viewModeCamera();
	}
	
	function viewModeCamera():Void {
		if (lvl.w * lvl.tsize < Screen.w
			&& lvl.h * lvl.tsize < Screen.h) viewMode = false;
		
		var sx = 0.0, sy = 0.0, s = lvl.tsize/5;
		if (keys[KeyCode.Left] || keys[KeyCode.A]) sx += s;
		if (keys[KeyCode.Right] || keys[KeyCode.D]) sx -= s;
		if (keys[KeyCode.Up] || keys[KeyCode.W]) sy += s;
		if (keys[KeyCode.Down] || keys[KeyCode.S]) sy -= s;
		if (keys[KeyCode.Shift]) {
			sx *= 2; sy *= 2;
		}
		if (sx != 0) lvl.camera.x += sx;
		if (sy != 0) lvl.camera.y += sy;
		lvl.updateCamera();
	}
	
	override function onRender(frame:Framebuffer):Void {
		var g = frame.g2;
		g.begin(true, 0xFFBDC3CD);
		g.fontGlyphs = Lang.fontGlyphs;
		lvl.drawLayer(g, 0);
		Portal.renderAllEffects(g);
		player.draw(g);
		lvl.drawLayer(g, 1);
		Portal.renderAll(g);
		for (p in particlers) p.draw(g, lvl.camera.x, lvl.camera.y);
		textField.draw(g);
		
		if (viewMode) {
			g.color = 0xFFFFFFFF;
			g.drawRect(1, 0, Screen.w-1, Screen.h-2, scale);
		}
		if (Screen.touch) touch.draw(g);
		
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
		
		/*var g = frame.g2;
		g.begin();
		Scaler.scale(backbuffer, frame, System.screenRotation);
		g.end();*/
	}
	
}
