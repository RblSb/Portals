package khm.utils;

import khm.Types.Point;
import khm.Types.Rect;

class Collision {

	public static inline function aabb(a:Rect, b:Rect):Bool {
		return !(
			a.y + a.h < b.y || a.y > b.y + b.h ||
			a.x + a.w < b.x || a.x > b.x + b.w
		);
	}

	public static inline function aabb2(a:Rect, b:Rect):Bool {
		return !(
			a.y + a.h <= b.y || a.y >= b.y + b.h ||
			a.x + a.w <= b.x || a.x >= b.x + b.w
		);
	}

	function doPolygonsIntersect(a:Array<Point>, b:Array<Point>) {
		var polygons = [a, b];

		for (polygon in polygons) {
			for (i in 0...polygon.length) {
				// get points for normal
				var i2 = (i + 1) % polygon.length;
				var p1 = polygon[i];
				var p2 = polygon[i2];
				var normal = {
					x: p2.y - p1.y,
					y: p1.x - p2.x
				};

				var minA = Math.POSITIVE_INFINITY;
				var maxA = Math.NEGATIVE_INFINITY;
				for (point in a) {
					var projected = normal.x * point.x + normal.y * point.y;
					if (projected < minA) minA = projected;
					if (projected > maxA) maxA = projected;
				}

				var minB = Math.POSITIVE_INFINITY;
				var maxB = Math.NEGATIVE_INFINITY;
				for (point in b) {
					var projected = normal.x * point.x + normal.y * point.y;
					if (projected < minB) minB = projected;
					if (projected > maxB) maxB = projected;
				}

				if (maxA < minB || maxB < minA) return false;
			}
		}
		return true;
	}

	public static function doLinesIntersect(p:Point, p2:Point, p3:Point, p4:Point):Point {
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
		return u >= 0 && v >= 0 && u + v < 1;
	}

}
