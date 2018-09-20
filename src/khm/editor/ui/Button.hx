package khm.editor.ui;

import haxe.Constraints.Function;
import kha.graphics2.Graphics;
import kha.math.FastMatrix3;
import kha.FastFloat;
import kha.Image;
import kha.input.KeyCode;
import khm.Types.Rect;
import khm.Screen;
import khm.Screen.Pointer;
import khm.utils.Utils;

private typedef ButtonSets = {
	x:Float,
	y:Float,
	?w:Float,
	?h:Float,
	?clickMode:Bool,
	?img:Image,
	?angle:Float,
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
	var angle = 0.0;

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

		if (sets.angle != null) angle = sets.angle;
		if (sets.keys != null) keys = sets.keys;
		onDownFunc = sets.onDown;
	}

	var transformation = FastMatrix3.identity();

	public function draw(g:Graphics):Void {
		if (isDown) {
			g.color = 0x50FFFFFF;
			g.fillRect(rect.x, rect.y, rect.w, rect.h);
		}
		g.color = 0xFFFFFFFF;
		if (angle != 0) {
			transformation.setFrom(g.transformation);
			g.transformation = g.transformation.multmat(
				rotation(angle * Math.PI / 180, rect.x + rect.w / 2, rect.y + rect.h / 2)
			);
		}
		if (img != null) g.drawScaledImage(img, rect.x, rect.y, rect.w, rect.h);
		if (angle != 0) {
			g.transformation = transformation;
		}
	}

	inline function rotation(angle:FastFloat, centerX:FastFloat, centerY:FastFloat): FastMatrix3 {
	return FastMatrix3.translation(centerX, centerY)
		.multmat(FastMatrix3.rotation(angle))
		.multmat(FastMatrix3.translation(-centerX, -centerY));
	}

	public static function onDown(screen:Screen, buttons:Array<Button>, p:Pointer):Bool {
		var result = false;
		// down pressed button
		for (b in buttons)
			if (b.check(p.x, p.y)) {
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
		// down current button and up all others
		for (b in buttons)
			if (b.isDown && !b.check(p.x, p.y)) {
				for (i in b.keys) screen.keys[i] = false;
				b.isDown = false;
			}

		for (b in buttons)
			if (b.check(p.x, p.y)) {
				if (!b.isDown) { // !b.clickMode ||
					for (i in b.keys) screen.keys[i] = true;
					b.isDown = true;
				}
			}

		return true;
	}

	public static function onUp(screen:Screen, buttons:Array<Button>, p:Pointer):Bool {
		if (!isActive(buttons, p)) return false;
		// up latest pressed button
		for (b in buttons)
			if (b.check(p.x, p.y)) {
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
		var active = false; // if you pressed buttons
		for (b in buttons)
			if (b.check(p.startX, p.startY)) {
				active = true;
				break;
			}
		return active;
	}

}
