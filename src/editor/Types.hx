package editor;

import Lvl.Object;

typedef History = {
	layer:Int,
	x:Int,
	y:Int,
	tile:Int,
	?obj:Object,
	?objType:Int
}

typedef ArrHistory = {
	layer:Int,
	x:Int,
	y:Int,
	tiles:Array<Array<Int>>
}
