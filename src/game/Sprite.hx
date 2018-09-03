package game;

import khm.tilemap.Tilemap as Lvl;
import khm.Types.IPoint;

class Sprite {

	var lvl:Lvl;
	static var sprites:Array<Sprite> = [];
	static inline var delayMax = 1;
	var delay = 0;
	var layer:Int;
	var tile:IPoint;
	var type:Int;
	var current:Int;
	var start:Int;
	var end:Int;
	var reverse:Bool;
	var reset:Bool;

	public function new(lvl:Lvl, layer:Int, tile:IPoint, type:Int, start:Int, end:Int, reverse=false, reset=false) {
		this.lvl = lvl;
		this.layer = layer;
		this.tile = tile;
		this.type = type;
		this.current = start;
		this.start = start;
		this.end = end;
		this.reverse = reverse;
		this.reset = reset;
	}

	public static function add(sprite:Sprite):Void {
		for (s in sprites) {
			if (sprite.layer == s.layer && sprite.tile.x == s.tile.x && sprite.tile.y == s.tile.y) {
				s.remove();
				break;
			}
		}
		sprites.push(sprite);
	}

	public static function removeAll():Void {
		while(sprites.length > 0) sprites[0].remove();
	}

	public function remove():Void {
		sprites.remove(this);
		if (reverse) Sprite.add(new Sprite(lvl, layer, tile, type, end, start, false, true));
	}

	public static function updateAll():Void {
		for (s in sprites) s.update();
	}

	function update():Void {
		if (delay > 0) {delay--; return;}
		delay = delayMax;

		if (current != end) {
			if (end < current) current--;
			else current++;
			if (reset && current == end) current = end = 0;
			var tile = lvl.getTile(layer, tile.x, tile.y);
			tile.setFrame(current);
			//lvl.setTileAnim(layer, tile.x, tile.y, type, current);
		} else remove();
	}

}
