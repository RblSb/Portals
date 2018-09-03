package khm.utils;

class Easing {

	public static inline function easeInOutQuad(t:Float):Float {
		return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
	}

}
