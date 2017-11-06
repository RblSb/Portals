package;

import kha.System;
import Types.Point;
import Types.Rect;

class Utils {
	
	public function new() {}
	
	public static inline function getScale():Float {
		var w = System.windowWidth();
		var h = System.windowHeight();
		var min = w < h ? w : h;
		var scale = Std.int(min/500);
		return scale;
	}
	
	public static inline function dist(p:Point, p2:Point):Float {
		return Math.sqrt(Math.pow(p.x - p2.x, 2) + Math.pow(p.y - p2.y, 2));
	}
	
	public static inline function matrix(scaleX=1, skewX=0, moveX=0, scaleY=1, skewY=0, moveY=0) {
		return new kha.math.FastMatrix3(
			scaleX, skewX, moveX,
			skewY, scaleY, moveY,
			0, 0, 1
		);
	}
	
	public static inline function AABB(a:Rect, b:Rect) {
		return !(
			(a.y + a.h < b.y) || (a.y > b.y + b.h) ||
			(a.x + a.w < b.x) || (a.x > b.x + b.w)
		);
	}
	
	public static inline function AABB2(a:Rect, b:Rect) {
		return !(
			(a.y + a.h <= b.y) || (a.y >= b.y + b.h) ||
			(a.x + a.w <= b.x) || (a.x >= b.x + b.w)
		);
	}
	
	public static function linesIntersect(p:Point, p2:Point, p3:Point, p4:Point):Point {
		var x = p2.x - p.x;
		var y = p2.y - p.y;
		var x2 = p4.x - p3.x;
		var y2 = p4.y - p3.y;
		
		var s = (-y * (p.x - p3.x) + x * (p.y - p3.y)) / (-x2 * y + x * y2);
		var t = (x2 * (p.y - p3.y) - y2 * (p.x - p3.x)) / (-x2 * y + x * y2);
		
		if (s >= 0 && s <= 1 && t >= 0 && t <= 1) {
			return {x: p.x + t * x, y: p.y + t * y};
		}
		return null;
	}
	
	public static function inTriangle(p:Point, a:Point, b:Point, c:Point):Bool {
		var v0 = [c.x - a.x, c.y - a.y];
		var v1 = [b.x - a.x, b.y - a.y];
		var v2 = [p.x - a.x, p.y - a.y];
		var dot00 = v0[0] * v0[0] + v0[1] * v0[1];
		var dot01 = v0[0] * v1[0] + v0[1] * v1[1];
		var dot02 = v0[0] * v2[0] + v0[1] * v2[1];
		var dot11 = v1[0] * v1[0] + v1[1] * v1[1];
		var dot12 = v1[0] * v2[0] + v1[1] * v2[1];
		
		var invDenom = 1 / (dot00 * dot11 - dot01 * dot01);
		var u = (dot11 * dot02 - dot01 * dot12) * invDenom;
		var v = (dot00 * dot12 - dot01 * dot02) * invDenom;
		return ((u >= 0) && (v >= 0) && (u + v < 1));
	}
	
}
