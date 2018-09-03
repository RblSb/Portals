package khm.utils;

import kha.math.FastMatrix3;
import kha.FastFloat;
import kha.System;
import khm.Types.Point;
import khm.Types.Rect;

class Utils {

	public static inline function getScale():Float {
		var w = System.windowWidth();
		var h = System.windowHeight();
		var min = w < h ? w : h;
		var scale = Std.int(min / 500);
		return scale;
	}

	public static inline function dist(p:Point, p2:Point):Float {
		return Math.sqrt(Math.pow(p.x - p2.x, 2) + Math.pow(p.y - p2.y, 2));
	}

	public static inline function distAng(ang:Float, toAng:Float):Float {
		var a = toAng - ang;
		if (a < -180) a += 360;
		if (a > 180) a -= 360;
		return a;
	}

	public static inline function matrix(
		scaleX = 1.0, skewX = 0.0,
		moveX = 0.0, skewY = 0.0,
		scaleY = 1.0, moveY = 0.0
	):FastMatrix3 {
		return new FastMatrix3(
			scaleX, skewX, moveX,
			skewY, scaleY, moveY,
			0, 0, 1
		);
	}

	public static inline function rotation(angle: FastFloat, centerx: FastFloat, centery: FastFloat):FastMatrix3 {
		return FastMatrix3.translation(centerx, centery).multmat(FastMatrix3.rotation(angle)).multmat(FastMatrix3.translation(-centerx, -centery));
	}

	public static function shuffle<T>(arr:Array<T>):Array<T> {
		for (i in 0...arr.length) {
			var j = Std.random(arr.length);
			var a = arr[i];
			var b = arr[j];
			arr[i] = b;
			arr[j] = a;
		}
		return arr;
	}

}
