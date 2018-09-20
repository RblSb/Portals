package khm.editor;

import khm.Types.IRect;
import khm.tilemap.Tilemap.GameObject;

typedef History = {
	layer:Int,
	x:Int,
	y:Int,
	tile:Int,
	objs:Array<GameObject>
}

typedef ArrHistory = {
	layer:Int,
	rect:IRect,
	tiles:Array<Array<Int>> // TODO objs
}
