package khm.tilemap;

import khm.tilemap.Data.Props;

class Tile {

	public var layer(default, set):Int;
	public var id(default, set):Int;
	public var frame(default, null):Int;
	public var props(default, null):Props;
	public var frameCount(get, never):Int;
	var tilemap:Tilemap;

	public function new(tilemap:Tilemap, layer:Int, id:Int, ?props:Props) {
		this.tilemap = tilemap;
		set(layer, id, props);
	}

	inline function set_layer(layer:Int):Int {
		this.layer = layer;
		setTileProps(layer, id);
		return this.layer;
	}

	inline function set_id(id:Int):Int {
		this.id = id;
		setTileProps(layer, id);
		return this.id;
	}

	inline function get_frameCount():Int {
		var tileset = @:privateAccess tilemap.tileset;
		return tileset.sprites[layer][id].length;
	}

	public function set(layer:Int, id:Int, ?props:Props):Void {
		this.layer = layer;
		this.id = id;
		frame = 0;
		if (props != null) setProps(props);
	}

	public function setProps(props:Props):Void {
		this.props = props;
	}

	public function setTileProps(layer:Int, id:Int):Void {
		this.props = @:privateAccess tilemap.tileset.props[layer][id];
	}

	public function setFrame(frame:Int):Void {
		this.frame = frame;

		var tileset = @:privateAccess tilemap.tileset;
		var frameId = tileset.tilesLengths[layer];
		frameId += tileset.sprites[layer][id].firstFrame + frame;
		this.props = tileset.props[layer][frameId];
	}

	public function setPrevFrame():Void {
		if (id > 1) setFrame(id - 1);
		else setFrame(frameCount);
	}

	public function setNextFrame():Void {
		if (id < frameCount) setFrame(id + 1);
		else setFrame(1);
	}

	public function copy():Tile {
		var newProps = Reflect.copy(props);
		return new Tile(tilemap, layer, id, newProps);
	}

}
