package;

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
	>Point,
	>Size, //need , compiler bug
}

typedef IRect = {
	>IPoint,
	>ISize,
}

typedef Range = {
	min:Float,
	max:Float
}
