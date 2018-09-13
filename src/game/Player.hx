package game;

import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.math.Vector2;
import kha.math.FastMatrix3;
import kha.FastFloat;
import kha.Image;
import kha.System;
import kha.Assets;
import Interfaces.Body;
import khm.tilemap.Tilemap;
import khm.tilemap.Tile;
import khm.Screen;
import khm.Screen.Pointer;
import khm.utils.Easing;
import khm.utils.Utils;
import khm.Types.IPoint;
import khm.Types.Point;
import khm.Types.IRect;
import khm.Types.Rect;
import khm.Types.Size;

private typedef Player_json = {
	frames:Array<{
		?set:String
	}>
};

private typedef Consts = {
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
	var lvl:Tilemap;
	var consts:Consts = {
		friction: 0.20,
		gravity: 0.2,
		jump: -5,
		landSX: 0.6,
		airSX: 0.30,
		maxRunSX: 4,
		maxSpeed: 200
	}
	var tileSize(get, never):Int;
	function get_tileSize() return lvl.tileSize;
	var sprite:Image;
	var spriteH:Int;
	var clone:Image;
	var frameW:Array<Int>;
	var frame = 0;
	var frameDelay = 0;
	var frameDelayMax = 5;
	var frameSets = new Map<String, Array<Int>>();
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

	public function new() {}

	public function init(game:Game, lvl:Tilemap):Void {
		this.game = game;
		this.lvl = lvl;
		aimMode = new AimMode(this, lvl);

		var sprite:IRect = makeSet();
		spriteH = sprite.h;

		rect = {
			x: 0, y: 0,
			w: frameW[1],
			h: spriteH - 1
		}
	}

	function makeSet():IRect {
		var text = Assets.blobs.player_json.toString();
		var json:Player_json = haxe.Json.parse(text);
		var w = 0, h = 0;
		for (i in 0...json.frames.length) {
			var img:Image = Assets.images.get("player_"+i);
			if (h < img.height) h = img.height;
			w += img.width;
		}
		sprite = Image.createRenderTarget(w, h * 2);
		var g = sprite.g2;
		g.begin(true, 0x0);

		var offset = 0;
		var curSet = "none";
		frameW = [0];
		for (i in 0...json.frames.length) {
			var img = Assets.images.get("player_"+i);
			g.transformation = Utils.matrix();
			g.drawImage(img, offset, 0);
			g.transformation = Utils.matrix(-1, 0, offset+img.width);
			g.drawImage(img, 0, h);

			var frame = json.frames[i];
			frameW.push(offset + img.width);
			offset += img.width;

			if (frame.set != null) {
				curSet = frame.set;
				frameSets[curSet] = [];
			}
			frameSets[curSet].push(i);
		}
		g.end();

		var len = frameW.length;
		frameW[len] = sprite.width - frameW[len-1];
		clone = Image.createRenderTarget(tileSize, tileSize);

		return {x: 0, y: 0, w: w, h: h};
	}

	public function update():Void {
		speed.y += consts.gravity;

		var sx = Math.abs(speed.x);
		var sy = Math.abs(speed.y);
		var vx = sx / speed.x; //direction
		var vy = sy / speed.y;
		var min = tileSize/4;

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
		if (rect.x > lvl.w * tileSize - rect.w) {
			rect.x = lvl.w * tileSize - rect.w;
			speed.x = 0;
		}
		if (rect.y < 0) {
			rect.y = 0;
			speed.y = 0;
		}
		if (rect.y > lvl.h * tileSize) game.restart();

		if (aimMode.state) aim();
		setAnim();
	}

	function collision(body:Body, dir:Int):Bool {
		if (Portal.collidePlayer(body)) return true;
		var collide = false;
		var rect = body.rect;
		var x = Std.int(rect.x / tileSize);
		var y = Std.int(rect.y / tileSize);
		var maxX = Math.ceil((rect.x + rect.w) / tileSize);
		var maxY = Math.ceil((rect.y + rect.h) / tileSize);

		for (iy in y...maxY)
		for (ix in x...maxX) {
			if (lvl.getTile(1, ix, iy).props.collide) {
				block(ix, iy, body, dir);
				collide = true;
			}
		}

		for (iy in y...maxY)
		for (ix in x...maxX) {
			if (!lvl.getTile(1, ix, iy).props.collide) {
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
				rect.x = ix * tileSize - rect.w;
				speed.x = 0;
			} else if (speed.x < 0) { //left
				rect.x = ix * tileSize + tileSize;
				speed.x = 0;
			}
		} else if (dir == 1) { //y-motion
			if (speed.y > 0) { //down
				body.onLand = true;
				rect.y = iy * tileSize - rect.h;
				speed.y = 0;
			} else if (speed.y < 0) { //up
				rect.y = iy * tileSize + tileSize;
				speed.y = 0;
			}
		}
	}

	inline function object(ix:Int, iy:Int, body:Body, dir:Int):Bool {
		var tile = lvl.getTile(1, ix, iy);
		var id = tile.id;
		var rect = body.rect;
		var speed = body.speed;
		var collide = false;

		switch(id) {
		case 3: game.restart();
		case 5: //door
			if (tile.frame == 0 && dir == 0) { //x-motion
				if (speed.x > 0) { //right
					if (rect.x + rect.w - speed.x < ix * tileSize + tileSize/2)
					if (rect.x + rect.w + speed.x > ix * tileSize + tileSize/2) {
						rect.x = ix * tileSize + tileSize/2 - rect.w - 1;
						speed.x = 0;
						collide = true;
					}
				} else if (speed.x < 0) { //left
					if (rect.x - speed.x > ix * tileSize + tileSize/2)
					if (rect.x + speed.x < ix * tileSize + tileSize/2) {
						rect.x = ix * tileSize + tileSize/2 + 1;
						speed.x = 0;
						collide = true;
					}
				}
			}
		case 7: //grill
			if (dir == 0) { //x-motion
				if (speed.x > 0) { //right
					if (rect.x + rect.w - speed.x < ix * tileSize + tileSize/2)
					if (rect.x + rect.w + speed.x > ix * tileSize + tileSize/2) Portal.removeAll();
				} else if (speed.x < 0) { //left
					if (rect.x - speed.x > ix * tileSize + tileSize/2)
					if (rect.x + speed.x < ix * tileSize + tileSize/2) Portal.removeAll();
				}
			}
		case 8, 9, 10, 11: //panels
			if (dir == 1 &&
				((id == 8 && rect.y + rect.h > (iy+1) * tileSize - tileSize/4) ||
				(id == 9 && rect.x < ix * tileSize + tileSize/4) ||
				(id == 10 && rect.y < iy * tileSize + tileSize/4) ||
				(id == 11 && rect.x + rect.w > (ix+1) * tileSize - tileSize/4)
			)) {
				var obj = lvl.getObjects(1, ix, iy)[0]; //TODO
				if (obj != null && obj.data.speed != null) {
					collide = true;
					var start = 0;
					var end = Std.int(tile.frameCount / 3);
					switch(id) {
					case 8, 10:
						if (obj.data.speed.x != 0) speed.x = obj.data.speed.x;
						if (id == 8 && speed.y > obj.data.speed.y ||
							id == 10 && speed.y < obj.data.speed.y) speed.y = obj.data.speed.y;
					case 9, 11:
						if (id == 9 && speed.x < obj.data.speed.x ||
							id == 11 && speed.x > obj.data.speed.x) speed.x = obj.data.speed.x;
						if (obj.data.speed.y != 0) speed.y = obj.data.speed.y;
					}
					var s = (id == 8 || id == 10) ? obj.data.speed.x : obj.data.speed.y;
					if (id == 8 || id == 9) {
						if (s < 0) {start += end; end *= 2;}
						else if (s > 0) {start += end * 2; end *= 3;}

					} else if (id == 10 || id == 11) {
						if (s > 0) {start += end; end *= 2;}
						else if (s < 0) {start += end * 2; end *= 3;}
					}
					if (Math.abs(s) < 5) end--;

					Sprite.add(new Sprite(lvl, 1, {x: ix, y: iy}, id, start, end, true));
				}
			}
		}
		return collide;
	}

	inline function trigger(ix:Int, iy:Int, body:Body, dir:Int):Bool {
		var id = lvl.getTile(2, ix, iy).id;
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
		var keys = game.keys;
		var sx = onLand ? consts.landSX : consts.airSX;
		if ((keys[KeyCode.Left] || keys[KeyCode.A]) && speed.x > -consts.maxRunSX) speed.x -= sx;
		if ((keys[KeyCode.Right] || keys[KeyCode.D]) && speed.x < consts.maxRunSX) speed.x += sx;
		if ((keys[KeyCode.Up] || keys[KeyCode.W] || keys[KeyCode.Space]) && (onLand || airHack)) {
			onLand = false;
			speed.y = consts.jump;
		}
		if (keys[KeyCode.Down] || keys[KeyCode.S]) {
			keys[KeyCode.Down] = false;
			keys[KeyCode.S] = false;
			//speed.y += tileSize;
			game.closeText();
		}

		if (keys[KeyCode.E]) {
			keys[KeyCode.E] = false;
			action();
			/*speed.x = tileSize * 3;
			speed.y = -tileSize * 3;*/

		} else if (keys[KeyCode.R]) {
			keys[KeyCode.R] = false;
			Portal.removeAll();
		}
	}

	inline function action():Void {
		var x = Std.int((rect.x + rect.w/2) / tileSize);
		var y = Std.int((rect.y + rect.h/2) / tileSize);
		var tile = lvl.getTile(1, x, y);
		var id = lvl.getTile(1, x, y).id;
		if (id == 6) button(x, y, tile);
	}

	inline function button(x:Int, y:Int, tile:Tile):Void {
		if (tile.frame == 0) tile.setFrame(tile.frameCount);
		else if (tile.frame == tile.frameCount) tile.setFrame(0);
		var obj = lvl.getObject(1, x, y, "button");
		if (obj == null) return;

		var doors:Array<Any> = obj.data.doors;
		if (doors != null) {
			for (i in doors) door(i);
		}
	}

	inline function door(p:IPoint):Void {
		var tile = lvl.getTile(1, p.x, p.y);
		var frame = tile.frame;
		var last = tile.frameCount;
		if (frame == last) {
			frame = tile.frameCount;
			last = 0;
		} else {
			frame = 0;
			last = tile.frameCount;
		}
		Sprite.add(new Sprite(lvl, 1, p, 5, frame, last));
	}

	public function onMouseDown(p:Pointer):Void {
		aimType = p.type;
		aimMode.state = true;
	}

	public function onMouseUp(p:Pointer):Void {
		if (!aimMode.state) return;
		aim();
		aimMode.state = false;
		var portal = makePortal();
		if (portal == null) return;
		if (Screen.isTouch) Touch.swapAimType(p);
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
		else if (ang < 0) max = Utils.dist(p, {x: lvl.w * tileSize, y:0});
		else if (ang > Math.PI/2) max = Utils.dist(p, {x: 0, y: lvl.h * tileSize});
		else max = Utils.dist(p, {x: lvl.w * tileSize, y: lvl.h * tileSize});
		if (wh < max) wh = max;

		var p2:Point = {
			x: p.x + Math.cos(ang) * wh,
			y: p.y + Math.sin(ang) * wh
		};

		aimMode.aim(p, p2);
	}

	function makePortal():Portal {
		if (aimMode.tile == null) return null;
		var props = lvl.getTile(1, aimMode.tile.x, aimMode.tile.y).props;
		if (!props.portalize) return null;
		return new Portal(game, this, lvl, aimMode.tile, aimMode.side, aimType);
	}

	var tempMatrix = FastMatrix3.identity();

	public function draw(g:Graphics):Void {
		//g.drawImage(sprite, 0, 0);
		//g.drawRect(rect.x + lvl.camera.x, rect.y + lvl.camera.y, rect.w, rect.h);
		aimMode.draw(g, aimType);

		var sy = dir == 1 ? 0 : spriteH;
		var w = frameW[frame + 1] - frameW[frame];
		var offx = rect.w / 2 - w / 2;
		var x = Math.round(rect.x + lvl.camera.x + offx);
		var y = Math.round(rect.y + lvl.camera.y - (spriteH - rect.h));
		g.color = 0xFFFFFFFF;
		tempMatrix.setFrom(g.transformation);
		g.transformation = g.transformation.multmat(
			FastMatrix3.identity()
			//FastMatrix3.translation(lvl.camera.x, lvl.camera.y)
		).multmat(
			rotation(aRotate * Math.PI / 180, x + rect.w / 2, y + rect.h / 2)
		);
		g.drawSubImage(
			sprite,
			x, y,
			frameW[frame], sy,
			frameW[frame+1] - frameW[frame], spriteH
		);
		g.transformation = tempMatrix;
	}

	inline function rotation(angle: FastFloat, centerx: FastFloat, centery: FastFloat): FastMatrix3 {
	return FastMatrix3.translation(centerx, centery)
		.multmat(FastMatrix3.rotation(angle))
		.multmat(FastMatrix3.translation(-centerx, -centery));
	}

	public function setClone(px:Float, py:Float, ang:Float, dir:Int, tile:IPoint):Void {
		var w = frameW[frame + 1] - frameW[frame];
		var offx = rect.w / 2 - w / 2;
		var x = Math.round(px + offx);
		var y = Math.round(py - (spriteH - rect.h));
		var sx = frameW[frame];
		var dr = dir == -1 ? this.dir : (this.dir+1)%2;
		var sy = dr == 1 ? 0 : spriteH;
		var ex = frameW[frame+1] - frameW[frame];
		var ey = spriteH;

		var g = clone.g2;
		g.begin(true, 0x0);
		//fix scissor
		g.scissor(tile.x * tileSize - x, tile.y * tileSize - y, tileSize, tileSize);
		g.rotate((rotate + ang) * Math.PI/180, tileSize/2, tileSize/2);
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
		var x = Math.round(px + lvl.camera.x + offx);
		var y = Math.round(py + lvl.camera.y - (spriteH - rect.h));

		g.color = 0xFFFFFFFF;
		g.drawImage(clone, x, y);
	}

	function setAnim():Void {
		if (rotate < 5 && rotate > -5) rotate = 0;
		if (rotate != 0) {
			var dist = Utils.distAng(0, rotate);
			if (dist != 0) rotate -= dist / Math.abs(dist) * 5;
		}
		aRotate = Easing.easeInOutQuad(rotate / 360) * 360;

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
			if (speed.y < -1) setAnimType("jump");
			else if (speed.y > 1) setAnimType("fall");
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
