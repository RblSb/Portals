package ui;

import haxe.Constraints.Function;
import kha.graphics2.Graphics;
import kha.Image;
import kha.math.FastMatrix3;
import kha.input.KeyCode;
import kha.Color;
import Types.Point;
import Types.Rect;
import Screen.Pointer;

typedef ButtonSets = {
	x:Float,
	y:Float,
	?w:Float,
	?h:Float,
	?clickMode:Bool,
	?img:Image,
	?ang:Float,
	?keys:Array<KeyCode>,
	?onDown:Function
}

class Button {
	
	public var rect:Rect;
	var keys:Array<KeyCode> = [];
	var isDown = false;
	var onDownFunc:Function;
	var clickMode = false;
	var img:Image;
	var ang = 0.0;
	
	public function new(sets:ButtonSets) {
		rect = {x: sets.x, y: sets.y, w: 10, h: 10};
		if (sets.w != null) rect.w = sets.w;
		if (sets.h != null) rect.h = sets.h;
		
		if (sets.clickMode != null) clickMode = sets.clickMode;
		if (sets.img != null) img = sets.img;
		
		if (sets.w == null || sets.h == null) {
			if (img != null) {
				rect.w = img.width;
				rect.h = img.height;
			}
		}
		
		if (sets.ang != null) ang = sets.ang;
		if (sets.keys != null) keys = sets.keys;
		onDownFunc = sets.onDown;
	}
	
	public function draw(g:Graphics):Void {
		if (isDown) {
			g.color = 0x50FFFFFF;
			g.fillRect(rect.x, rect.y, rect.w, rect.h);
		}
		g.color = 0xFFFFFFFF;
		g.rotate(ang * Math.PI/180, rect.x + rect.w/2, rect.y + rect.h/2);
		if (img != null) g.drawScaledImage(img, rect.x, rect.y, rect.w, rect.h);
		g.transformation = Utils.matrix();
	}
	
	public static function onDown(screen:Screen, buttons:Array<Button>, p:Pointer):Bool {
		var result = false;
		//down pressed button
		for (b in buttons) if (b.check(p.x, p.y)) {
			for (i in b.keys) {
				screen.onKeyDown(i);
				screen.keys[i] = true;
			}
			if (b.onDownFunc != null) b.onDownFunc(p);
			b.isDown = true;
			result = true;
			/*if (b.clickMode) {
				onUp(screen, buttons, p);
			}*/
		}
		
		return result;
	}
	
	public static function onMove(screen:Screen, buttons:Array<Button>, p:Pointer):Bool {
		if (!p.isDown) return false;
		if (!isActive(buttons, p)) return false;
		//down current button and up all others
		for (b in buttons)
			if (b.isDown && !b.check(p.x, p.y)) {
				for (i in b.keys) screen.keys[i] = false;
				b.isDown = false;
			}
		
		for (b in buttons)
			if (b.check(p.x, p.y)) {
				if (!b.isDown) { //!b.clickMode ||
					for (i in b.keys) screen.keys[i] = true;
					b.isDown = true;
				}
			}
		
		return true;
	}
	
	public static function onUp(screen:Screen, buttons:Array<Button>, p:Pointer):Bool {
		if (!isActive(buttons, p)) return false;
		//up latest pressed button
		for (b in buttons) if (b.check(p.x, p.y)) {
			for (i in b.keys) {
				screen.onKeyUp(i);
				screen.keys[i] = false;
			}
			b.isDown = false;
		}
		
		return true;
	}
	
	inline function check(x:Int, y:Int):Bool {
		if (x < rect.x || x >= rect.x + rect.w || y < rect.y || y >= rect.y + rect.h) return false;
		return true;
	}
	
	static inline function isActive(buttons:Array<Button>, p:Pointer):Bool {
		var active = false; //if you pressed buttons
		for (b in buttons) if (b.check(p.startX, p.startY)) {
			active = true;
			break;
		}
		return active;
	}
	
	/*static inline function sendCommand(screen:Screen, keys:Array<KeyCode>):Void {
		if (keys.length < 1) return;
		for (i in keys) screen.keys[i] = true;
		var id = keys.length - 1;
		screen.onKeyDown(keys[id]);
		for (i in keys) screen.keys[i] = false;
	}*/
	
	/*public static function onMove(screen:Screen, buttons:Array<Button>, p:Pointer):Bool {
		if (!p.isDown) return false;
		if (!isActive(buttons, p)) return false;
		//down current button and up all others
		for (b in buttons) {
			if (b.check(p.x, p.y)) {
				if (!b.isDown) { //!b.clickMode ||
					for (i in b.keys) screen.keys[i] = true;
					b.isDown = true;
				}
			} else if (b.isDown) {
				for (i in b.keys) screen.keys[i] = false;
				b.isDown = false;
			}
		}
		
		return true;
	}*/
	
}
