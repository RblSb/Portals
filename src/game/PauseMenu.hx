package game;

import kha.Framebuffer;
import kha.input.KeyCode;
import kha.Image;
import kha.Font;
import kha.Assets;
import kha.System;
import editor.Editor;
import Menu.MenuButton;
import Screen.Pointer;

class PauseMenu extends Screen {
	
	var game:Game;
	var editor:Editor;
	var inited:Bool;
	var items:Array<MenuButton> = [];
	public static var font:Font;
	public static var fontSize:Int;
	
	public function new(game:Game, ?editor:Editor) {
		this.game = game;
		this.editor = editor;
		super();
	}
	
	public function init():Void {
		font = Assets.fonts.OpenSans_Regular;
		setMenu();
	}
	
	function setMenu():Void {
		var menu = [
			"continue",
			"restart",
			editor == null ? "main_menu" : "level_editor"
		];
		
		items = [];
		for (i in 0...menu.length) {
			var item = Lang.get(menu[i]);
			items.push(new MenuButton(item, font, 1, {x: 0, y: 0}, 1));
		}
		onResize();
	}
	
	override function onResize():Void {
		var min = Screen.w < Screen.h ? Screen.w : Screen.h;
		fontSize = Std.int(min/10/2)*2;
		var maxW = 0.0;
		for (item in items) {
			var w = font.width(fontSize, item.text);
			if (maxW < w) maxW = w;
		}
		
		for (i in 0...items.length) {
			var fh = font.height(fontSize);
			var y = (Screen.h - items.length * fh) / 2 + i * fh;
			//items[i].rect.x = fh * (items.length - i);
			items[i].rect.y = y;
			//items[i].rect.w = maxW;
			items[i].rect.w = fh * (items.length - i) + maxW;
			items[i].rect.h = fh;
			items[i].fontSize = fontSize;
		}
	}
	
	function choose(id:Int):Void {
		switch(id) {
			case 0: game.show();
			case 1:
				game.show();
				game.restart();
			case 2:
				if (editor != null) {
					game.showEditor();
					return;
				}
				var menu = new Menu();
				menu.show();
				menu.init();
		}
	}
	
	override function onMouseMove(p:Pointer):Void {
		var state = true;
		for (i in items) {
			if (i.check(p.x, p.y)) {
				i.isOver = state;
				state = false;
			} else i.isOver = false;
		}
	}
	
	override function onMouseDown(p:Pointer):Void {
		onMouseMove(p);
		if (Screen.touch) return;
		for (i in 0...items.length) {
			if (items[i].check(p.x, p.y)) {
				choose(i);
				break;
			}
		}
	}
	
	override function onMouseUp(p:Pointer):Void {
		if (!Screen.touch) return;
		for (i in 0...items.length) {
			if (items[i].check(p.x, p.y)) {
				choose(i);
				break;
			}
		}
	}
	
	override function onKeyDown(key:KeyCode):Void {
		if (key == KeyCode.Escape) game.show();
		else if (key == KeyCode.R) {
			game.show();
			game.restart();
		}
	}
	
	override function onRender(frame:Framebuffer):Void {
		var g = frame.g2;
		g.begin(false, 0x0);
		
		if (!inited) {
			g.color = 0x77000000;
			g.fillRect(0, 0, Screen.w, Screen.h);
			inited = true;
		}
		
		var fh = font.height(fontSize);
		var last = items.length - 1;
		g.color = 0x05000000;
		g.fillRect(
			0, items[0].rect.y - fh/8,
			items[last].rect.x + items[last].rect.w + fh/16,
			items[last].rect.y + items[last].rect.h - items[0].rect.y + fh/4
		);
		g.fillTriangle(
			items[last].rect.x + items[last].rect.w + fh/16,
			items[0].rect.y - fh/8,
			
			items[0].rect.x + items[0].rect.w + fh + fh/4 + fh/16,
			items[0].rect.y - fh/8,
			
			items[last].rect.x + items[last].rect.w + fh/16,
			items[last].rect.y + items[last].rect.h + fh/8
		);
		g.color = 0xFFFFFFFF;
		
		for (item in items) {
			var rect = item.rect;
			g.fillRect(rect.x, rect.y, rect.w, rect.h);
			g.fillRect(0, rect.y, rect.x, rect.h);
			g.fillTriangle(
				rect.x + rect.w, rect.y,
				rect.x + rect.w, rect.y + rect.h,
				rect.x + rect.w + rect.h, rect.y
			);
		}
		
		
		for (i in items) i.draw(g);
		
		g.end();
	}
	
}
