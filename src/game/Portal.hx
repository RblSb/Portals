package game;

import kha.graphics2.Graphics;
import kha.math.Vector2;
import kha.Color;
import Interfaces.Body;
import khm.tilemap.Tilemap;
import khm.Types.IPoint;
import khm.Types.Point;
import khm.Types.Rect;
import khm.Screen;
import khm.utils.Collision;

private typedef Insides = {
	clones:Array<{
		> Point,
		rotate:Float,
		body:Body,
		dir:Int
	}>
}

class Portal {

	var game:Game;
	var lvl:Tilemap;
	var player:Player;
	public static var colors = [0xFFFF8000, 0xFF0032FF];
	var insides:Insides = { // to render
		clones: []
	};
	static var portals:Array<Portal> = [];
	static var oldScale:Float;
	public var rect:Rect; // portal line
	public var type:Int; // portal type
	var side:Int; // portal side type
	var tile:IPoint; // tile cords
	var particler:Particler;

	var tileSize(get, never):Int;
	function get_tileSize() return lvl.tileSize;

	public function new(game:Game, player:Player, lvl:Tilemap, tile:IPoint, side:Int, type:Int) {
		this.game = game;
		this.player = player;
		this.lvl = lvl;

		var tx = tile.x * tileSize;
		var ty = tile.y * tileSize;
		var wh = 1;
		var sides:Array<Rect> = [
			{x: tx, y: ty, w: tileSize, h: wh}, // top of tile
			{x: tx, y: ty + tileSize - wh, w: tileSize, h: wh}, // bottom
			{x: tx, y: ty, w: wh, h: tileSize}, // left
			{x: tx + tileSize - wh, y: ty, w: wh, h: tileSize} // right
		];
		rect = sides[side];
		this.type = type;
		this.side = side;

		initInside(tile);
		initParticles();
	}

	inline function initInside(tile):Void {
		this.tile = tile;
		// tileId = lvl.getTile(1, tile.x, tile.y).id;
	}

	inline function initParticles():Void {
		var speed = sideVector(side);
		particler = new Particler({
			x: rect.x, y: rect.y, w: rect.w, h: rect.h,
			speed: new Vector2(speed.x / 2, speed.y / 2),
			wobble: new Vector2(speed.y / 2, speed.x / 2),
			lifeTime: 30,
			color: colors[type],
			count: 30
		});
	}

	public static function add(portal:Portal):Void {
		for (p in portals)
			if (portal.rect.x == p.rect.x &&
				portal.rect.y == p.rect.y &&
				portal.rect.w == p.rect.w &&
				portal.rect.h == p.rect.h) return;
		for (p in portals)
			if (portal.type == p.type) p.remove();
		portals.push(portal);
	}

	public static function removeAll():Void {
		while (portals.length > 0)
			portals[0].remove();
	}

	public function remove():Void {
		pushOut();
		game.transferParticles(particler);
		portals.remove(this);
	}

	function pushOut():Void {
		var off = 1;
		for (i in insides.clones) {
			var p = i.body.rect;
			// if (!Utils.AABB2(p, rect)) continue;
			switch (side) {
				case 0:
					if (p.y + p.h > rect.y) p.y = rect.y - p.h;
				case 1:
					if (p.y < rect.y) p.y = rect.y + off + 1;
				case 2:
					if (p.x + p.w > rect.x) p.x = rect.x - p.w;
				case 3:
					if (p.x < rect.x) p.x = rect.x + off + 1;
			}
		}
		insides.clones = [];
	}

	public static function collidePlayer(body:Body):Bool {
		for (p in portals) {
			if (p.collision(body)) return true;
		}
		return false;
	}

	function getOutPortal():Portal {
		var outType = type == 0 ? 1 : 0;
		for (p in portals) {
			if (p.type == outType) return p;
		}
		return null;
	}

	public function collision(body:Body):Bool {
		var out = getOutPortal();
		if (out == null) return false;

		var crect = {x: rect.x, y: rect.y, w: rect.w, h: rect.h};
		var offx = body.rect.w / 2;
		var offy = body.rect.h / 2;
		if (side < 2) {
			crect.x += offx;
			crect.w -= offx * 2;
		}
		else {
			crect.y += offy;
			crect.h -= offy * 2;
		}

		// fix need to use closest portal
		if (!Collision.aabb2(body.rect, crect)) {
			return resolveInsides(out);
		}

		// animation mode only
		if (effectMode(body, out)) return true;
		// move body to another side
		portalMode(body, out);

		return true;
	}

	function resolveInsides(out:Portal):Bool {
		for (i in insides.clones) {
			var p = i.body.rect;
			var s = i.body.speed;
			switch (side) {
				case 0:
					if (s.y > 0 && p.y > rect.y) portalMode(i.body, out);
					insides.clones = [];
					return true;
				case 1: // 1-3 not tested
					if (s.y < 0 && p.y + p.h < rect.y) portalMode(i.body, out);
					insides.clones = [];
					return true;
				case 2:
					if (s.x > 0 && p.x > rect.x) portalMode(i.body, out);
					insides.clones = [];
					return true;
				case 3:
					if (s.x < 0 && p.x + p.w < rect.x) portalMode(i.body, out);
					insides.clones = [];
					return true;
			}
		}
		if (insides.clones.length > 0) insides.clones = [];
		return false;
	}

	function effectMode(body:Body, out:Portal):Bool {
		// var v = sideVector(out.side);
		var off = 1;
		var ax = out.rect.x, ay = out.rect.y, rotate = 0.0, dir = -1;
		switch (side) {
			case 0:
				if (body.rect.y + body.rect.h / 2 < rect.y) {
					maxPortalX(body);
					switch (out.side) {
						case 0:
							ax += -tileSize / 2 + body.rect.w;
							ay += -body.rect.y % tileSize;
							rotate = 180;
						case 1:
							ax += tileSize / 2 - body.rect.w / 2;
							ay += body.rect.y % tileSize - tileSize;
						case 2:
							ax += -body.rect.y % tileSize;
							rotate = 90;
						case 3:
							ax += (body.rect.y + body.rect.h) % tileSize - body.rect.h;
							ay += -tileSize + body.rect.h - off;
							rotate = 270;
					}
					setClone(body, out, ax, ay, rotate, dir);
					return true;
				}
			case 1:
				if (body.rect.y + body.rect.h / 2 > rect.y) {
					maxPortalX(body);
					switch (out.side) {
						case 0:
							ax += tileSize / 2 - body.rect.w / 2;
							ay += body.rect.y % tileSize - tileSize;
						case 1:
							ax += -tileSize / 2 + body.rect.w;
							ay += tileSize - body.rect.y % tileSize - body.rect.h;
							rotate = 180;
						case 2:
							ax += body.rect.y % tileSize - body.rect.h;
							ay += -body.rect.w;
							rotate = 270;
						case 3:
							ax += -body.rect.y % tileSize;
							rotate = 90;
					}
					setClone(body, out, ax, ay, rotate, dir);
					return true;
				}
			case 2:
				if (body.rect.x + body.rect.w / 2 < rect.x) {
					if (lvl.getTile(1, tile.x - 1, tile.y + 1).props.collide) body.onLand = true;
					else if (Math.abs(body.speed.x) < off / 2) body.speed.x -= off / 2;
					maxPortalY(body);
					switch (out.side) {
						case 0:
							ax += tileSize / 2 - body.rect.h / 2;
							ay += -(body.rect.x + body.rect.w + off) % tileSize - body.rect.w - off;
							rotate = 270;
						case 1:
							ax += tileSize / 2 - body.rect.h / 2;
							ay += (body.rect.x + body.rect.w) % tileSize - body.rect.w;
							rotate = 90;
						case 2:
							ax += tileSize - body.rect.x % tileSize - body.rect.w;
							ay += body.rect.y - rect.y;
							dir = 0;
						case 3:
							ax += body.rect.x % tileSize - tileSize;
							ay += body.rect.y - rect.y;
					}
					setClone(body, out, ax, ay, rotate, dir);
					return true;
				}
			case 3:
				if (body.rect.x + body.rect.w / 2 > rect.x) {
					if (lvl.getTile(1, tile.x + 1, tile.y + 1).props.collide) body.onLand = true;
					else if (Math.abs(body.speed.x) < off / 2) body.speed.x += off / 2;
					maxPortalY(body);
					switch (out.side) {
						case 0:
							ax += -off;
							ay += body.rect.x % tileSize - tileSize;
							rotate = 90;
						case 1:
							ax += tileSize / 2 - body.rect.w - off;
							ay += -body.rect.x % tileSize;
							rotate = 270;
						case 2:
							ax += body.rect.x % tileSize - tileSize;
							ay += body.rect.y - rect.y;
						case 3:
							ax += tileSize - body.rect.x % tileSize - body.rect.w;
							ay += body.rect.y - rect.y;
							dir = 1;
					}
					setClone(body, out, ax, ay, rotate, dir);
					return true;
				}
		}
		return false;
	}

	inline function maxPortalX(body:Body):Void {
		if (body.speed.x > 0 && body.rect.x + body.rect.w > rect.x + rect.w) {
			body.rect.x = rect.x + rect.w - body.rect.w;
			body.speed.x = 0;
		} else if (body.speed.x < 0 && body.rect.x < rect.x) {
			body.rect.x = rect.x;
			body.speed.x = 0;
		}
	}

	inline function maxPortalY(body:Body):Void {
		if (body.speed.y > 0 && body.rect.y + body.rect.h > rect.y + rect.h) {
			body.rect.y = rect.y + rect.h - body.rect.h;
			body.speed.y = 0;
		} else if (body.speed.y < 0 && body.rect.y < rect.y) {
			body.rect.y = rect.y;
			body.speed.y = 0;
		}
	}

	inline function setClone(body:Body, out:Portal, ax:Float, ay:Float, ang:Float, dir:Int):Void {
		// ang = 0;
		if (insides.clones.length == 0) {
			insides.clones.push({body: body, x: ax, y: ay, rotate: ang, dir: dir});
		} else {
			insides.clones[0].x = ax;
			insides.clones[0].y = ay;
			insides.clones[0].rotate = ang;
			insides.clones[0].dir = dir;
		}
		var v = sideVector(out.side);
		body.setClone(ax, ay, ang, dir, {x: out.tile.x + v.x, y: out.tile.y + v.y});
	}

	inline function portalMode(body:Body, out:Portal):Void {
		// reset effects
		if (insides.clones.length > 0) {
			body.rotate = insides.clones[0].rotate;
			var dir = insides.clones[0].dir;
			if (dir != -1) body.dir = dir;
			insides.clones = [];
		}

		teleport(body, out);
		invertSpeeds(body, side, out.side);
		out.collision(body);
		// effectMode(body, this);
		// throw {};
	}

	inline function teleport(body:Body, out:Portal):Void {
		var off = 1;
		var x = out.rect.x, y = out.rect.y;

		if (out.side == 0) {
			x += tileSize / 2 - body.rect.w / 2;
			y += -body.rect.h / 2 - off - 1;

		} else if (out.side == 1) {
			x += tileSize / 2 - body.rect.w / 2;
			y += off + 1 - body.rect.h / 2;

		} else if (out.side == 2) {
			x += -body.rect.w / 2 - off; // fix -1?
			if (side == 2 || side == 3) y += (body.rect.y - rect.y);

		} else if (out.side == 3) {
			x += -body.rect.w / 2 + off + 1;
			if (side == 2 || side == 3) y += (body.rect.y - rect.y);
		}

		body.rect.x = x;
		body.rect.y = y;
	}

	inline function invertSpeeds(body:Body, side:Int, out:Int):Void {
		if (side == out) {
			if (side == 0) body.speed.y = -Math.abs(body.speed.y);
			else if (side == 1) body.speed.y = Math.abs(body.speed.y);
			else if (side == 2) body.speed.x = -Math.abs(body.speed.x);
			else if (side == 3) body.speed.x = Math.abs(body.speed.x);
		}
		if (side != 1 && out == 0) { // speed-up
			var min = -4;
			if (body.speed.y > min) body.speed.y = min;
			if (side == 2 || side == 3) body.speed.x = 0;
		}

		// rotate speeds
		if ((side == 0 && out == 2) || (side == 1 && out == 3)) {
			body.speed.x = -body.speed.y;
			body.speed.y = 0;

		} else if ((side == 0 && out == 3) || (side == 1 && out == 2)) {
			body.speed.x = body.speed.y;
			body.speed.y = 0;

		} else if ((side == 2 || side == 3) && out == 1) {
			body.speed.y = Math.abs(body.speed.x);
			body.speed.x = 0;
		}
	}

	public static inline function sideVector(side:Int):IPoint {
		var v:IPoint;
		switch (side) {
			case 0:
				v = {x: 0, y: -1}; // up
			case 1:
				v = {x: 0, y: 1}; // down
			case 2:
				v = {x: -1, y: 0}; // left
			case 3:
				v = {x: 1, y: 0}; // right
			default:
				v = {x: 0, y: 0};
		}
		return v;
	}

	public static function updateAll():Void {
		for (p in portals)
			p.particler.update();
	}

	public static function renderAllEffects(g:Graphics):Void {
		for (p in portals)
			for (i in p.insides.clones) p.player.drawClone(g, i.x, i.y, i.rotate);
	}

	public static function renderAll(g:Graphics):Void {
		for (p in portals) p.render(g);
	}

	function render(g:Graphics):Void {
		g.color = 0xFFFFFFFF;
		g.color = colors[type];
		g.fillRect(
			rect.x + lvl.camera.x,
			rect.y + lvl.camera.y,
			rect.w, rect.h
		);
		particler.draw(g, lvl.camera.x, lvl.camera.y);
		drawLabel(g);
	}

	inline function drawLabel(g:Graphics):Void {
		var screen:Rect = {
			x: -lvl.camera.x,
			y: -lvl.camera.y,
			w: Screen.w,
			h: Screen.h
		};
		if (!Collision.aabb(rect, screen)) {
			var size = Std.int(lvl.tileSize / 8);
			var x = rect.x + lvl.camera.x - size / 2 + rect.w / 2;
			var y = rect.y + lvl.camera.y - size / 2 + rect.h / 2;
			if (x > Screen.w) x = Screen.w - size;
			if (y > Screen.h) y = Screen.h - size;
			if (x < 0) x = 0;
			if (y < 0) y = 0;
			var color:Color = colors[type];
			color.A = 0.5;
			g.color = color;
			g.fillRect(x, y, size, size);
		}
	}

}
