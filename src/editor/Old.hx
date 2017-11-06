package editor;

import kha.Assets;
import kha.Blob;
import haxe.io.BytesInput;
import haxe.io.Bytes;
import Types.IPoint;
import Lvl.Objects;
import Lvl.GameMap;

class Old {
	
	public static function loadMap(res:Blob):GameMap {
		var bytes:Bytes = res.toBytes();
		var file = new BytesInput(bytes);
		var w = file.readByte()+1;
		var h = file.readByte()+1;
		var v = file.readByte();
		switch(v) {
			case 6: return V6(bytes, file, w, h);
			case 5, 51: return V5(file, w, h);
		}
		throw("Unsupported map format (v"+v+") or broken file");
		//return null;
	}
	
	static inline function V6(bytes:Bytes, file:BytesInput, w:Int, h:Int):GameMap {
		var plen = file.readByte();
		var params:Array<Int> = [];
		trace(w, h, plen);
		for (i in 0...plen) params[i] = file.readByte();
		//trace(params);
		//trace(file.readByte());
		delemiter(file);
		
		var data = file;
		if (params[0] == 1) data = new RleInput(file, bytes);
		
		var layers:Array<Array<Array<Int>>> = [
			for (layer in 0...3) [
				for (y in 0...h) []
			]
		];
		
		for (iy in 0...h) //bg
		for (ix in 0...w) {
			layers[0][iy][ix] = data.readByte();
		}
		
		//trace(data.readByte());
		delemiter(data);
		
		var objects:Objects = {
			buttons: [],
			panels: [],
			texts: []
		};
		
		for (iy in 0...h) //tg
		for (ix in 0...w) {
			var id = data.readByte();
			if (id == 9) id = 11;
			if (id == 10) id = 9;
			layers[1][iy][ix] = id;
			
			if (id > 4 && id < 12 && id != 7) {
				var pid = id;
				if (id > 7) id = 7; //panels
				var len = data.readByte(); //bytes in object
				var obj:Array<Int> = [];
				for (i in 0...len) obj[i] = data.readByte();
				
				switch(id) {
					case 5: //door
						
					case 6: //button
						if (obj[0] == 5) objects.buttons.push(
							{x:ix, y:iy, doors: [{x:obj[1], y:obj[2]}]}
						);
					case 7: //panels
						//trace(ix, iy, pid, obj);
						for (i in 0...2) {
							if (obj[i] > 199) obj[i] = 115;
							if (obj[i] > 100) obj[i] = (100 - obj[i]);
						}
						if (pid == 8) obj[0] = Std.int(-Math.abs(obj[0]));
						if (pid == 9) obj[1] = Std.int(Math.abs(obj[1]));
						if (pid == 11) obj[1] = Std.int(-Math.abs(obj[1]));
						obj[0] = Std.int(-Math.abs(obj[0]));
						//trace(pid, obj);
						objects.panels.push(
							{x:ix, y:iy, speed: {x:obj[1], y:obj[0]}}
						);
					default: trace(id, obj);
				}
			}
		}
		
		//trace(data.readByte());
		delemiter(data);
		
		for (iy in 0...h) //objects
		for (ix in 0...w) {
			var id = data.readByte();
			switch(id) {
				case 0:
				case 1:
					//objects.player = {x: ix, y: iy};
				case 2: //end
					//objects.ends.push({x:ix, y:iy});
				case 3: //death
					//objects.deaths.push({x:ix, y:iy});
				case 4: //save
					//objects.saves.push({x:ix, y:iy});
				case 5: //text
					objects.texts.push({x:ix, y:iy});
				default: trace(id, ix, iy);
			}
			layers[2][iy][ix] = id;
		}
		//layers[2][6][4] = 4;
		
		//trace(data.readByte());
		delemiter(data);
		
		//texts | space 20 | enter 0A
		for (i in 0...objects.texts.length) {
			objects.texts[i].text = {
				ru: {
					text: getText(file),
					author: getText(file)
				}
			}
		}
		
		var map:GameMap = {
			w:w, h:h,
			layers:layers,
			objects:objects
		}
		
		return map;
	}
	
	static inline function delemiter(data:BytesInput):Void {
		var temp = data.readByte();
		if (temp != 255) trace("error", temp);
	}
	
	static inline function V5(file:BytesInput, w:Int, h:Int):GameMap {
		var data = file;
		
		var layers:Array<Array<Array<Int>>> = [
			for (layer in 0...3) [
				for (y in 0...h) []
			]
		];
		
		for (iy in 0...h) //bg
		for (ix in 0...w) {
			layers[0][iy][ix] = data.readByte();
		}
		
		var objects:Objects = {
			buttons: [],
			panels: [],
			texts: []
		};
		
		for (iy in 0...h) //tg
		for (ix in 0...w) {
			var id = data.readByte();
			if (id == 9) id = 11;
			if (id == 10) id = 9;
			layers[1][iy][ix] = id;
			
			if (id > 4 && id < 12 && id != 7) {
				var pid = id;
				if (id > 8) id = 8; //panels
				var len = data.readByte(); //bytes in object
				//if (v == 51) if (bytes==0) throw("v51 map nooo");
				
				var obj:Array<Int> = [];
				for (i in 0...len) obj[i] = data.readByte();
				
				var fix = 0;
				if (id == 8) fix = 1;
				
				switch(id-fix) {
					case 6: //button
						if (obj[0] == 5) objects.buttons.push(
							{x:ix, y:iy, doors: [{x:obj[1], y:obj[2]}]}
						);
					case 7: //panels
						trace(ix, iy, pid, obj);
						if (obj[0] > 100) obj[0] = (100 - obj[0]);
						if (obj[1] > 100) obj[1] = (100 - obj[1]);
						if (pid == 8) obj[0] = Std.int(-Math.abs(obj[0]));
						if (pid == 9) obj[1] = Std.int(Math.abs(obj[1]));
						if (pid == 11) obj[1] = Std.int(-Math.abs(obj[1]));
						obj[0] = Std.int(-Math.abs(obj[0]));
						trace(pid, obj);
						objects.panels.push(
							{x:ix, y:iy, speed: {x:obj[1], y:obj[0]}}
						);
					default: trace(id, obj);
				}
			}
		}
		
		for (iy in 0...h)
			for (ix in 0...w)
				layers[2][iy][ix] = 0;
		
		while(true) {
			var ix = data.readByte();
			if (ix == 255) break;
			var iy = data.readByte();
			var id = data.readByte();
			if (id > 5) id = 0; //заглушка
			else { //тайлы
				if (id == 5) { //текст
					objects.texts.push({x:ix, y:iy});
				}
			}
			layers[2][iy][ix] = id;
		}
		
		//texts | space 20 | enter 0A
		for (i in 0...objects.texts.length) {
			objects.texts[i].text = {
				ru: {
					text: getText(file),
					author: getText(file)
				}
			}
		}
		
		var map:GameMap = {
			w:w, h:h,
			layers:layers,
			objects:objects
		}
		
		return map;
	}
	
	public static function getText(file:BytesInput):String { //win-1252
		//var buffer = new StringBuf();
		var buffer = new haxe.Utf8();
		try {
			while(true) {
				var ch = file.readByte();
				if (ch == 10) break;
				buffer.addChar((ch >= 0xc0 && ch <= 0xFF) ? ch + 0x350 : ch);
			}
		} catch (ex:String) {trace(buffer);}
		
		var text = buffer.toString();
		var ereg = ~/\\ /g;
		text = ereg.replace(text, "\n");
		if (text.substring(text.length - 1) == " ")
			text = text.substring(0, text.length - 1);
		return text;
	}
	
}

class RleInput extends BytesInput {
	
	var frle:Bool;
	var bb:Int;
	var count:Int;
	var current:Int;
	var input:BytesInput;
	
	public function new(input:BytesInput, bytes:Bytes) {
		this.input = input;
		super(bytes);
	}
	
	override public function readByte():Int {
		if (!frle) { //rle inactive
			bb = input.readByte();
			if (bb == 253) frle = true;
			else current = bb;
		}
		
		if (frle) { //find end
			if (count < 1) bb = input.readByte();
			if (bb == 254) {
				frle = false;
				bb = input.readByte();
				
				if (bb == 253) {
					frle = true;
					bb = input.readByte();
				} else current = bb;
			}
		}
		
		if (frle) {
			if (count < 1) {
				count = bb;
				current = input.readByte();
			}
			count--;
		}
		
		return current;
	}
	
}
