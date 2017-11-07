package;

import kha.Framebuffer;
import kha.System;
import kha.Font;
import kha.Assets;
import game.Game;

class Loader {
	
	public function new() {}
	
	public function init():Void {
		System.notifyOnRender(onRender);
		Assets.loadEverything(loadComplete);
	}
	
	public function loadComplete():Void {
		System.removeRenderListener(onRender);

		var sets = Settings.read();
		Screen._init(sets.touchMode);
		if (sets.lang == null) Lang.init();
		else Lang.set(sets.lang);
		
		#if kha_html5
		var nav = js.Browser.window.location.hash.substr(1);
		switch(nav) {
		case "editor":
			var editor = new editor.Editor();
			editor.show();
			editor.init();
		case "game":
			var game = new Game();
			game.show();
			game.init();
			game.playCompany();
		default: newMenu();
		}
		#else
		newMenu();
		#end
	}
	
	inline function newMenu():Void {
		var menu = new Menu();
		menu.show();
		menu.init();
	}
	
	function onRender(framebuffer:Framebuffer):Void {
		var g = framebuffer.g2;
		g.begin(true, 0xFFFFFFFF);
		var h = System.windowHeight() / 20;
		var w = Assets.progress * System.windowWidth();
		var y = System.windowHeight() / 2 - h;
		g.color = 0xFF000000;
		g.fillRect(0, y, w, h * 2);
		g.end();
	}
	
}
