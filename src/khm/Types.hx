package khm;

typedef Point = {
	x:Float,
	y:Float
}

typedef IPoint = {
	x:Int,
	y:Int
}

typedef Size = {
	w:Float,
	h:Float
}

typedef ISize = {
	w:Int,
	h:Int
}

typedef Rect = {
	> Point,
	> Size,
}

typedef IRect = {
	> IPoint,
	> ISize,
}

typedef Range = {
	min:Float,
	max:Float
}

enum Position {
	TOP;
	BOTTOM;
	LEFT;
	RIGHT;
}
