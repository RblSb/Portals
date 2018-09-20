package;

import kha.Framebuffer;
import kha.graphics2.Graphics;
import kha.System;
import kha.Assets;
import khm.Settings;
import khm.Screen;
import khm.Lang;
import khm.editor.Editor;
import khm.tilemap.Tilemap;
import game.Game;

class Loader {

	public function new() {}

	public function init():Void {
		System.notifyOnFrames(onRender);
		Assets.loadEverything(loadComplete);
	}

	public function loadComplete():Void {
		System.removeFramesListener(onRender);

		var sets = Settings.read();
		Screen.init({isTouch: sets.touchMode});
		Lang.loadFolder("langs");
		Lang.set(sets.lang);
		Graphics.fontGlyphs = Lang.fontGlyphs;

		Editor.testMap = function(editor:Editor, tilemap:Tilemap) {
			var game = new Game();
			game.show();
			game.init(editor);
			var map = tilemap.toJSON(tilemap.map);
			game.playCustomLevel(map);
		};

		Editor.exit = function() {
			var menu = new Menu();
			menu.show();
			menu.init();
		};

		#if debug
		var game = new Game();
		game.show();
		game.init();
		game.playLevel(0);
		#else
		var menu = new Menu();
		menu.show();
		menu.init();
		#end

		/*var editor = new editor.Editor();
		editor.show();
		editor.init();*/
	}

	function onRender(fbs:Array<Framebuffer>):Void {
		var g = fbs[0].g2;
		g.begin(true, 0xFFFFFFFF);
		var h = System.windowHeight() / 20;
		var w = Assets.progress * System.windowWidth();
		var y = System.windowHeight() / 2 - h;
		g.color = 0xFF000000;
		g.fillRect(0, y, w, h * 2);
		g.end();
	}

}
