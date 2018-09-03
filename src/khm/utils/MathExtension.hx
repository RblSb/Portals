package khm.utils;

class MathExtension {

	public static inline function toRad(degrees:Float):Float {
		return degrees * Math.PI / 180;
	}

	public static inline function toDeg(radians:Float):Float {
		return radians * 180 / Math.PI;
	}

}
