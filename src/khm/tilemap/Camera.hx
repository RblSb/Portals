package khm.tilemap;

import kha.System;
import khm.Types.Rect;

class Camera {

	var tilemap:Tilemap;
	public var x = 0.0;
	public var y = 0.0;
	public var w = 0.0;
	public var h = 0.0;

	public function new(tilemap:Tilemap) {
		this.tilemap = tilemap;
		w = Screen.w;
		h = Screen.h;
	}

	public function set(rect:Rect):Void {
		x = rect.x;
		y = rect.y;
		w = rect.w;
		h = rect.h;
	}

	public function center(rect:Rect):Void {
		var centerX = w / 2 - rect.x - rect.w / 2;
		var centerY = h / 2 - rect.y - rect.h / 2;
		var pw = tilemap.map.w * tilemap.tileSize;
		var ph = tilemap.map.h * tilemap.tileSize;

		if (pw < w) x = w / 2 - pw / 2;
		else if (x != centerX) {
			x = centerX;
			if (x > 0) x = 0;
			if (x < w - pw) x = w - pw;
		}
		if (ph < h) y = h / 2 - ph / 2;
		else if (y != centerY) {
			y = centerY;
			if (y > 0) y = 0;
			if (y < h - ph) y = h - ph;
		}
	}

	public function strictCenter(rect:Rect):Void {
		x = w / 2 - rect.x - rect.w / 2;
		y = h / 2 - rect.y - rect.h / 2;
	}

}

private class Screen { // TODO use camera

	public static var w(get, never):Int;
	public static var h(get, never):Int;
	inline static function get_w():Int return System.windowWidth();
	inline static function get_h():Int return System.windowHeight();

}
