package game;

import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.math.Vector2;
import kha.Image;
import kha.System;
import kha.Assets;
import Interfaces.Body;
import Types.IPoint;
import Types.Point;
import Types.Rect;
import Types.Size;

typedef Player_json = {
	frames:Array<{
		?set:String
	}>
};

typedef Consts = {
	friction:Float,
	gravity:Float,
	jump:Float,
	landSX:Float,
	airSX:Float,
	maxRunSX:Float,
	maxSpeed:Float
};

class Player implements Body {
	
	var game:Game;
	var lvl:Lvl;
	var origSprite:Image; //for rescaling
	var origFrameW:Array<Int>;
	var origSize:Size;
	var origConsts:Consts = {
		friction: 0.20,
		gravity: 0.2,
		jump: -5,
		landSX: 0.6,
		airSX: 0.30,
		maxRunSX: 4,
		maxSpeed: 200
	}
	var oldTsize:Int;
	var tsize(get, never):Int;
	function get_tsize() return lvl.tsize;
	var sprite:Image;
	var clone:Image;
	var frameW:Array<Int>;
	var frame = 0;
	var frameDelay = 0;
	var frameDelayMax = 5;
	var frameSets:Map<String, Array<Int>> = new Map();
	var frameType:String;
	var frameTypeId:Int;
	
	static inline var airHack = false;
	public var dir = 1; //frame direction
	public var rotate = 0.0;
	public var rect:Rect;
	public var speed = new Vector2();
	public var onLand = false;
	var aimMode:AimMode;
	var aimType = 0;
	var aRotate = 0.0; //easing
	var consts:Consts;
	
	public function new() {}
	
	public function init(game:Game, lvl:Lvl):Void {
		this.game = game;
		this.lvl = lvl;
		aimMode = new AimMode(this, lvl);
		
		oldTsize = tsize;
		var tileset = makeSet();
		
		origSize = {
			w: frameW[1],
			h: tileset.h
		};
		rect = {
			x: 0, y: 0,
			w: origSize.w,
			h: origSize.h
		}
		consts = Reflect.copy(origConsts);
	}
	
	function makeSet():Rect {
		var text = Assets.blobs.player_json.toString();
		var json:Player_json = haxe.Json.parse(text);
		var w = 0, h = 0;
		for (i in 0...json.frames.length) {
			var img:Image = Reflect.field(Assets.images, "player_"+i);
			if (h < img.height) h = img.height;
			w += img.width;
		}
		origSprite = Image.createRenderTarget(w, h * 2);
		var g = origSprite.g2;
		g.begin(true, 0x0);
		Screen.pipeline(g);
		
		var offset = 0;
		var curSet = "none";
		origFrameW = [0];
		for (i in 0...json.frames.length) {
			var img = Reflect.field(Assets.images, "player_"+i);
			g.transformation = Utils.matrix();
			g.drawImage(img, offset, 0);
			g.transformation = Utils.matrix(-1, 0, offset+img.width);
			g.drawImage(img, 0, h);
			
			var frame = json.frames[i];
			origFrameW.push(offset + img.width);
			offset += img.width;
			
			if (frame.set != null) {
				curSet = frame.set;
				frameSets[curSet] = [];
			}
			frameSets[curSet].push(i);
		}
		g.end();
		
		var len = origFrameW.length;
		origFrameW[len] = origSprite.width - origFrameW[len-1];
		frameW = origFrameW.copy();
		sprite = origSprite;
		clone = Image.createRenderTarget(tsize, tsize);
		
		return {x: 0, y: 0, w: w, h: h};
	}
	
	public function rescale(scale:Float):Void {
		speed = speed.div(consts.jump);
		var fields = Reflect.fields(origConsts);
		for (field in fields) {
			var value:Float = Reflect.field(origConsts, field);
			Reflect.setField(consts, field, value * scale);
		}
		
		var w = Std.int(origSprite.width * scale);
		var h = Std.int(origSprite.height * scale);
		sprite = Image.createRenderTarget(w, h);
		var g = sprite.g2;
		g.begin(true, 0x0);
		Screen.pipeline(g);
		g.drawScaledImage(origSprite, 0, 0, w, h);
		g.end();
		
		clone = Image.createRenderTarget(tsize, tsize);
		
		rect.x = rect.x/oldTsize * tsize;
		rect.y = rect.y/oldTsize * tsize;
		rect.w = origSize.w * scale;
		rect.h = origSize.h * scale;
		speed = speed.mult(consts.jump);
		for (i in 0...origFrameW.length)
			frameW[i] = Std.int(origFrameW[i] * scale);
		oldTsize = tsize;
	}
	
	public function update():Void {
		speed.y += consts.gravity;
		
		var sx = Math.abs(speed.x);
		var sy = Math.abs(speed.y);
		var vx = sx / speed.x; //direction
		var vy = sy / speed.y;
		var min = tsize/4;
		
		while(sx > min || sy > min) { //speed > min dist
			if (sx > min) {
				rect.x += min * vx;
				sx -= min;
			}
			if (collision(this, 0)) sx = 0;
			
			if (sy > min) {
				rect.y += min * vy;
				sy -= min;
			}
			if (collision(this, 1)) sy = 0;
		}
		
		if (sx > 0) rect.x += sx * vx;
		collision(this, 0);
		
		if (sy > 0) {
			onLand = false;
			rect.y += sy * vy;
		}
		collision(this, 1);
		
		//x-deceleration
		if (onLand) {
			if (speed.x >= consts.friction) speed.x -= consts.friction;
			//fix 0.0 hack to hxjava bug (float is int)
			if (speed.x <= 0.0-consts.friction) speed.x += consts.friction;
			if (Math.abs(speed.x) < consts.friction) speed.x = 0;
		}
		
		if (speed.x > consts.maxSpeed) speed.x = consts.maxSpeed;
		if (speed.x < -consts.maxSpeed) speed.x = -consts.maxSpeed;
		if (speed.y > consts.maxSpeed) speed.y = consts.maxSpeed;
		if (speed.y < -consts.maxSpeed) speed.y = -consts.maxSpeed;
		if (rect.x < 0) {
			rect.x = 0;
			speed.x = 0;
		}
		if (rect.x > lvl.w * tsize - rect.w) {
			rect.x = lvl.w * tsize - rect.w;
			speed.x = 0;
		}
		if (rect.y < 0) {
			rect.y = 0;
			speed.y = 0;
		}
		if (rect.y > lvl.h * tsize) game.restart();
		
		if (aimMode.state) aim();
		setAnim();
	}
	
	function collision(body:Body, dir:Int):Bool {
		if (Portal.collidePlayer(body)) return true;
		var collide = false;
		var rect = body.rect;
		var x = Std.int(rect.x / tsize);
		var y = Std.int(rect.y / tsize);
		var maxX = Math.ceil((rect.x + rect.w) / tsize);
		var maxY = Math.ceil((rect.y + rect.h) / tsize);
		
		for (iy in y...maxY)
		for (ix in x...maxX) {
			if (lvl.getProps(1, ix, iy).collide) {
				block(ix, iy, body, dir);
				collide = true;
			}
		}
		
		for (iy in y...maxY)
		for (ix in x...maxX) {
			if (!lvl.getProps(1, ix, iy).collide) {
				if (object(ix, iy, body, dir)) collide = true;
			}
		}
		
		for (iy in y...maxY)
		for (ix in x...maxX) {
			if (trigger(ix, iy, body, dir)) return collide;
		}
		
		return collide;
	}
	
	inline function block(ix:Int, iy:Int, body:Body, dir:Int):Void {
		var rect = body.rect;
		var speed = body.speed;
		
		if (dir == 0) { //x-motion
			if (speed.x > 0) { //right
				rect.x = ix * tsize - rect.w;
				speed.x = 0;
			} else if (speed.x < 0) { //left
				rect.x = ix * tsize + tsize;
				speed.x = 0;
			}
		} else if (dir == 1) { //y-motion
			if (speed.y > 0) { //down
				body.onLand = true;
				rect.y = iy * tsize - rect.h;
				speed.y = 0;
			} else if (speed.y < 0) { //up
				rect.y = iy * tsize + tsize;
				speed.y = 0;
			}
		}
	}
	
	inline function object(ix:Int, iy:Int, body:Body, dir:Int):Bool {
		var id = lvl.getTile(1, ix, iy);
		var rect = body.rect;
		var speed = body.speed;
		var collide = false;
		
		switch(id) {
		case 3: game.restart();
		case 5: //door
			if (dir == 0) { //x-motion
				if (speed.x > 0) { //right
					if (rect.x + rect.w - speed.x < ix * tsize + tsize/2)
					if (rect.x + rect.w + speed.x > ix * tsize + tsize/2) {
						rect.x = ix * tsize + tsize/2 - rect.w - 1;
						speed.x = 0;
						collide = true;
					}
				} else if (speed.x < 0) { //left
					if (rect.x - speed.x > ix * tsize + tsize/2)
					if (rect.x + speed.x < ix * tsize + tsize/2) {
						rect.x = ix * tsize + tsize/2 + 1;
						speed.x = 0;
						collide = true;
					}
				}
			}
		case 7: //grill
			if (dir == 0) { //x-motion
				if (speed.x > 0) { //right
					if (rect.x + rect.w - speed.x < ix * tsize + tsize/2)
					if (rect.x + rect.w + speed.x > ix * tsize + tsize/2) Portal.removeAll();
				} else if (speed.x < 0) { //left
					if (rect.x - speed.x > ix * tsize + tsize/2)
					if (rect.x + speed.x < ix * tsize + tsize/2) Portal.removeAll();
				}
			}
		case 8, 9, 10, 11: //panels
			if (dir == 1 &&
				((id == 8 && rect.y + rect.h > (iy+1) * tsize - tsize/4) ||
				(id == 9 && rect.x < ix * tsize + tsize/4) ||
				(id == 10 && rect.y < iy * tsize + tsize/4) ||
				(id == 11 && rect.x + rect.w > (ix+1) * tsize - tsize/4)
			)) {
				var obj = lvl.getObject(1, ix, iy);
				if (obj != null && obj.speed != null) {
					collide = true;
					var start = 0;
					var end = Std.int(lvl.getSpriteLength(1, id) / 3);
					switch(id) {
					case 8, 10:
						if (obj.speed.x != 0) speed.x = obj.speed.x * lvl.scale;
						if (id == 8 && speed.y > obj.speed.y ||
							id == 10 && speed.y < obj.speed.y) speed.y = obj.speed.y * lvl.scale;
					case 9, 11:
						if (id == 9 && speed.x < obj.speed.x ||
							id == 11 && speed.x > obj.speed.x) speed.x = obj.speed.x * lvl.scale;
						if (obj.speed.y != 0) speed.y = obj.speed.y * lvl.scale;
					}
					var s = (id == 8 || id == 10) ? obj.speed.x : obj.speed.y;
					if (id == 8 || id == 9) {
						if (s < 0) {start += end; end *= 2;}
						else if (s > 0) {start += end * 2; end *= 3;}
						
					} else if (id == 10 || id == 11) {
						if (s > 0) {start += end; end *= 2;}
						else if (s < 0) {start += end * 2; end *= 3;}
					}
					if (Math.abs(s) < 5 * lvl.scale) end--;
					
					Sprite.add(new Sprite(lvl, 1, {x: ix, y: iy}, id, start, end, true));
				}
			}
		}
		return collide;
	}
	
	inline function trigger(ix:Int, iy:Int, body:Body, dir:Int):Bool {
		var id = lvl.getTile(2, ix, iy);
		var rect = body.rect;
		var speed = body.speed;
		var collide = false;
		var stop = false;
		
		switch(id) {
			case 2:
				game.levelComplete();
				stop = true;
			case 3:
				game.restart();
				stop = true;
			case 4: game.checkpoint(ix, iy);
			case 5: game.showText(ix, iy);
		}
		return stop;
	}
	
	public function keys() {
		//controls
		var keys = game.keys;
		var sx = onLand ? consts.landSX : consts.airSX;
		if ((keys[KeyCode.Left] || keys[KeyCode.A]) && speed.x > -consts.maxRunSX) speed.x -= sx;
		if ((keys[KeyCode.Right] || keys[KeyCode.D]) && speed.x < consts.maxRunSX) speed.x += sx;
		if ((keys[KeyCode.Up] || keys[KeyCode.W]) && (onLand || airHack)) { //jump
			onLand = false;
			speed.y = consts.jump;
		}
		if (keys[KeyCode.Down] || keys[KeyCode.S]) {
			keys[KeyCode.Down] = false;
			keys[KeyCode.S] = false;
			//speed.y += tsize;
			game.closeText();
		}
		
		if (keys[KeyCode.E]) {
			keys[KeyCode.E] = false;
			action();
			/*speed.x = tsize * 3;
			speed.y = -tsize * 3;*/
			
		} else if (keys[KeyCode.R]) {
			keys[KeyCode.R] = false;
			Portal.removeAll();
		}
	}
	
	inline function action():Void {
		var x = Std.int((rect.x + rect.w/2) / tsize);
		var y = Std.int((rect.y + rect.h/2) / tsize);
		var id = lvl.getTile(1, x, y);
		if (id == 6 || id == lvl.getSpriteEnd(1, 6)) button(x, y, id);
	}
	
	inline function button(x:Int, y:Int, id:Int):Void {
		if (id == 6) lvl.setTileAnim(1, x, y, 6, 1);
		else if (id == lvl.getSpriteEnd(1, 6)) lvl.setTileAnim(1, x, y, 6, 0);
		var obj = lvl.getObject(1, x, y);
		if (obj == null) return;
		
		if (obj.doors != null) for (i in obj.doors) door(i);
	}
	
	inline function door(p:IPoint):Void {
		var id = lvl.getTile(1, p.x, p.y);
		var last = lvl.getSpriteEnd(1, 5);
		if (id == last) {
			id = lvl.getSpriteLength(1, 5);
			last = 0;
		} else {
			id = 0;
			last = lvl.getSpriteLength(1, 5);
		}
		Sprite.add(new Sprite(lvl, 1, p, 5, id, last));
	}
	
	public function onMouseDown(id:Int):Void {
		aimType = game.pointers[id].type;
		aimMode.state = true;
	}
	
	public function onMouseUp(id:Int):Void {
		if (!aimMode.state) return;
		aim();
		aimMode.state = false;
		var portal = makePortal();
		if (portal == null) return;
		if (Screen.touch) Touch.swapAimType(game.pointers[id]);
		Portal.add(portal);
		aimType = 0;
	}
	
	public function aim():Void {
		var w = Screen.w;
		var h = Screen.h;
		var p:Point = {
			x: rect.x + rect.w/2,
			y: rect.y + rect.h/3
		};
		var ang = Math.atan2(
			game.pointers[0].y - p.y - lvl.camera.y,
			game.pointers[0].x - p.x - lvl.camera.x
		);
		if (ang < -Math.PI/2 || ang > Math.PI/2) dir = 0;
		else dir = 1;
		
		var wh:Float = w > h ? w : h;
		var max = 0.0; //max line distance
		if (ang < -Math.PI/2) max = Utils.dist(p, {x: 0, y: 0});
		else if (ang < 0) max = Utils.dist(p, {x: lvl.w * tsize, y:0});
		else if (ang > Math.PI/2) max = Utils.dist(p, {x: 0, y: lvl.h * tsize});
		else max = Utils.dist(p, {x: lvl.w * tsize, y: lvl.h * tsize});
		if (wh < max) wh = max;
		
		var p2:Point = {
			x: p.x + Math.cos(ang) * wh,
			y: p.y + Math.sin(ang) * wh
		};
		
		aimMode.aim(p, p2);
	}
	
	function makePortal():Portal {
		if (aimMode.tile == null) return null;
		var props = lvl.getProps(1, aimMode.tile.x, aimMode.tile.y);
		if (!props.portalize) return null;
		return new Portal(this, lvl, aimMode.tile, aimMode.side, aimType);
	}
	
	inline function distAng(ang:Float, toAng:Float):Float {
		var a = toAng - ang;
		if (a < -180) a += 360;
		if (a > 180) a -= 360;
		return a;
	}
	
	public function draw(g:Graphics):Void {
		//g.drawImage(sprite, 0, 0);
		//g.drawRect(rect.x + lvl.camera.x, rect.y + lvl.camera.y, rect.w, rect.h);
		aimMode.draw(g, aimType);
		
		var sy = dir == 1 ? 0 : rect.h;
		var w = frameW[frame+1] - frameW[frame];
		var offx = rect.w/2 - w/2;
		var x = rect.x + lvl.camera.x + offx;
		var y = rect.y + lvl.camera.y;
		g.color = 0xFFFFFFFF;
		g.rotate(aRotate * Math.PI/180, x + rect.w/2, y + rect.h/2);
		g.drawSubImage(
			sprite,
			Std.int(x), Std.int(y), //fix del int cords
			frameW[frame], sy,
			frameW[frame+1] - frameW[frame], rect.h
		);
		g.transformation = Utils.matrix();
	}
	
	public function setClone(px:Float, py:Float, ang:Float, dir:Int, tile:IPoint):Void {
		var w = frameW[frame+1] - frameW[frame];
		var offx = rect.w/2 - w/2;
		var x = px + lvl.camera.x + offx;
		var y = py + lvl.camera.y;
		var sx = frameW[frame];
		var dr = dir == -1 ? this.dir : (this.dir+1)%2;
		var sy = dr == 1 ? 0 : rect.h;
		var ex = frameW[frame+1] - frameW[frame];
		var ey = rect.h;
		
		var g = clone.g2;
		g.begin(true, 0x0);
		//fix scissor
		g.scissor(tile.x * tsize - Std.int(px + offx), tile.y * tsize - Std.int(py), tsize, tsize);
		g.rotate((rotate + ang) * Math.PI/180, tsize/2, tsize/2);
		Screen.pipeline(g);
		g.drawSubImage(
			sprite,
			0, 0, //fix del int cords
			sx, sy,
			ex, ey
		);
		g.transformation = Utils.matrix();
		g.disableScissor();
		g.end();
	}
	
	public function drawClone(g:Graphics, px:Float, py:Float, ang:Float):Void {
		var w = frameW[frame+1] - frameW[frame];
		var offx = rect.w/2 - w/2;
		var x = px + lvl.camera.x + offx;
		var y = py + lvl.camera.y;
		
		g.color = 0xFFFFFFFF;
		g.drawImage(clone, Std.int(x), Std.int(y));
	}
	
	inline function easeInOutQuad(t:Float) {
		return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
	}
	
	function setAnim():Void {
		if (rotate < 5 && rotate > -5) rotate = 0;
		if (rotate != 0) {
			var dist = distAng(0, rotate);
			if (dist != 0) rotate -= dist/Math.abs(dist) * 5;
		}
		aRotate = easeInOutQuad(rotate / 360) * 360;
		
		var left = false, right = false, up = false;
		var keys = game.keys;
		if (keys[KeyCode.Left] || keys[KeyCode.A]) left = true;
		if (keys[KeyCode.Right] || keys[KeyCode.D]) right = true;
		if (keys[KeyCode.Up] || keys[KeyCode.W]) up = true;
		if (left != right) dir = left ? 0 : 1;
		
		if (onLand) {
			if (left == right) {
				if (speed.x != 0) {
					setAnimType("brake");
					if (speed.x < -consts.maxRunSX/2) dir = 0;
					else if (speed.x > consts.maxRunSX/2) dir = 1;
				} else setAnimType("stand");
			} else {
				if (Math.abs(speed.x) > consts.landSX) setAnimType("run");
				else setAnimType("stand");
			}
		} else {
			if (speed.y < -lvl.scale) setAnimType("jump");
			else if (speed.y > lvl.scale) setAnimType("fall");
			else setAnimType("soar");
		}
		playAnimType();
	}
	
	inline function setAnimType(type:String):Void {
		if (frameType == type) return;
		frameType = type;
		frameTypeId = 0;
		frame = frameSets[type][0];
		frameDelay = 0;
	}
	
	inline function playAnimType():Void {
		frameDelay++;
		if (frameDelay < frameDelayMax) return;
		frameTypeId++;
		var len = frameSets[frameType].length;
		if (frameTypeId == len) frameTypeId = 0;
		frame = frameSets[frameType][frameTypeId];
		frameDelay = 0;
	}
	
}
