package game;

import kha.graphics2.Graphics;
import kha.math.Vector2;
import kha.Color;
import Interfaces.Body;
import Types.IPoint;
import Types.Point;
import Types.Rect;

typedef Insides = {
	clones:Array<{
		>Point,
		rotate:Float,
		body:Body,
		dir:Int
	}>
}

class Portal {
	
	//var game:Game;
	var lvl:Lvl;
	var player:Player;
	public static var colors = [0xFFFF8000, 0xFF0032FF];
	var insides:Insides = { //to render
		clones: []
	};
	static var portals:Array<Portal> = [];
	static var oldScale:Float;
	public var rect:Rect; //portal line
	public var type:Int; //portal type
	var side:Int; //portal type
	var tile:IPoint; //removed tile cords
	//var tileId:Int; //removed tile id
	//var tiles:Array<Array<Int>>; //tiles inside portal
	var particles:Array<Particle> = [];
	
	
	var tsize(get, never):Int;
	function get_tsize() return lvl.tsize;
	
	public function new(player:Player, lvl:Lvl, tile:IPoint, side:Int, type:Int) {
		this.player = player;
		this.lvl = lvl;
		oldScale = lvl.scale;
		
		var tx = tile.x * tsize;
		var ty = tile.y * tsize;
		var wh = lvl.scale;
		var sides:Array<Rect> = [
			{x: tx, y: ty, w: tsize, h: wh}, //top of tile
			{x: tx, y: ty + tsize-wh, w: tsize, h: wh}, //bottom
			{x: tx, y: ty, w: wh, h: tsize}, //left
			{x: tx + tsize-wh, y: ty, w: wh, h: tsize} //right
		];
		rect = sides[side];
		this.type = type;
		this.side = side;
		
		initInside(tile);
		initParticles();
	}
	
	inline function initInside(tile):Void {
		this.tile = tile;
		//tileId = lvl.getTile(1, tile.x, tile.y);
	}
	
	inline function initParticles():Void {
		var speed = sideVector(side);
		var scale = lvl.scale;
		for(i in 0...30) {
			particles.push(new Particle(
				rect.x + rect.w * Math.random(),
				rect.y + rect.h * Math.random(),
				new Vector2(speed.x / 2 * scale, speed.y / 2 * scale),
				new Vector2(speed.y / 2 * scale, speed.x / 2 * scale),
				colors[type], 30, Std.random(30), scale
			));
		}
	}
	
	public static function add(portal:Portal):Void {
		for (p in portals)
			if (portal.rect.x == p.rect.x && portal.rect.y == p.rect.y
				&& portal.rect.w == p.rect.w && portal.rect.h == p.rect.h) return;
		for (p in portals)
			if (portal.type == p.type) p.remove();
		portals.push(portal);
	}
	
	public static function removeAll():Void {
		while(portals.length > 0) portals[0].remove();
	}
	
	public function remove():Void {
		pushOut();
		portals.remove(this);
	}
	
	function pushOut():Void {
		var off = lvl.scale;
		for (i in insides.clones) {
			var p = i.body.rect;
			//if (!Utils.AABB2(p, rect)) continue;
			switch(side) {
				case 0: if (p.y + p.h > rect.y) p.y = rect.y - p.h;
				case 1: if (p.y < rect.y) p.y = rect.y + off + 1;
				case 2: if (p.x + p.w > rect.x) p.x = rect.x - p.w;
				case 3: if (p.x < rect.x) p.x = rect.x + off + 1;
			}
		}
		insides.clones = [];
	}
	
	public static function rescaleAll():Void {
		for (p in portals) p.rescale();
		if (portals.length > 0) oldScale = portals[0].lvl.scale;
	}
	
	function rescale():Void {
		rect = {
			x: rect.x / oldScale * lvl.scale,
			y: rect.y / oldScale * lvl.scale,
			w: rect.w / oldScale * lvl.scale,
			h: rect.h / oldScale * lvl.scale
		}
		Particle.rescaleAll(particles, lvl.scale);
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
		var offx = body.rect.w/2;
		var offy = body.rect.h/2;
		if (side < 2) {crect.x += offx; crect.w -= offx * 2;}
		else {crect.y += offy; crect.h -= offy * 2;}
		
		//fix need to use closest portal
		if (!Utils.AABB2(body.rect, crect)) {
			return resolveInsides(out);
		}
		
		//animation mode only
		if (effectMode(body, out)) return true;
		//move body to another side
		portalMode(body, out);
		
		return true;
	}
	
	function resolveInsides(out:Portal):Bool {
		for (i in insides.clones) {
			var p = i.body.rect;
			var s = i.body.speed;
			switch(side) {
			case 0:
				if (s.y > 0 && p.y > rect.y) portalMode(i.body, out);
				insides.clones = [];
				return true;
			case 1: //1-3 not tested
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
		//var v = sideVector(out.side);
		var off = lvl.scale;
		var ax = out.rect.x, ay = out.rect.y, rotate = 0.0, dir = -1;
		switch(side) {
		case 0:
			if (body.rect.y + body.rect.h/2 < rect.y) {
				maxPortalX(body);
				switch(out.side) {
				case 0:
					ax += -tsize/2 + body.rect.w;
					ay += -body.rect.y%tsize;
					rotate = 180;
				case 1:
					ax += tsize/2 - body.rect.w/2;
					ay += body.rect.y%tsize - tsize;
				case 2:
					ax += -body.rect.y%tsize;
					rotate = 90;
				case 3:
					ax += (body.rect.y + body.rect.h)%tsize - body.rect.h;
					ay += -tsize + body.rect.h - off;
					rotate = 270;
				}
				setClone(body, out, ax, ay, rotate, dir);
				return true;
			}
		case 1:
			if (body.rect.y + body.rect.h/2 > rect.y) {
				maxPortalX(body);
				switch(out.side) {
				case 0:
					ax += tsize/2 - body.rect.w/2;
					ay += body.rect.y%tsize - tsize;
				case 1:
					ax += -tsize/2 + body.rect.w;
					ay += tsize - body.rect.y%tsize - body.rect.h;
					rotate = 180;
				case 2:
					ax += body.rect.y%tsize - body.rect.h;
					ay += -body.rect.w;
					rotate = 270;
				case 3:
					ax += -body.rect.y%tsize;
					rotate = 90;
				}
				setClone(body, out, ax, ay, rotate, dir);
				return true;
			}
		case 2:
			if (body.rect.x + body.rect.w/2 < rect.x) {
				if (lvl.getProps(1, tile.x-1, tile.y+1).collide) body.onLand = true;
				else if (Math.abs(body.speed.x) < off/2) body.speed.x -= off/2;
				maxPortalY(body);
				switch(out.side) {
				case 0:
					ax += tsize/2 - body.rect.h/2;
					ay += -(body.rect.x + body.rect.w + off)%tsize - body.rect.w - off;
					rotate = 270;
				case 1:
					ax += tsize/2 - body.rect.h/2;
					ay += (body.rect.x + body.rect.w)%tsize - body.rect.w;
					rotate = 90;
				case 2:
					ax += tsize - body.rect.x%tsize - body.rect.w;
					ay += body.rect.y - rect.y;
					dir = 0;
				case 3:
					ax += body.rect.x%tsize - tsize;
					ay += body.rect.y - rect.y;
				}
				setClone(body, out, ax, ay, rotate, dir);
				return true;
			}
		case 3:
			if (body.rect.x + body.rect.w/2 > rect.x) {
				if (lvl.getProps(1, tile.x+1, tile.y+1).collide) body.onLand = true;
				else if (Math.abs(body.speed.x) < off/2) body.speed.x += off/2;
				maxPortalY(body);
				switch(out.side) {
				case 0:
					ax += -off;
					ay += body.rect.x%tsize - tsize;
					rotate = 90;
				case 1:
					ax += tsize/2 - body.rect.w - off;
					ay += -body.rect.x%tsize;
					rotate = 270;
				case 2:
					ax += body.rect.x%tsize - tsize;
					ay += body.rect.y - rect.y;
				case 3:
					ax += tsize - body.rect.x%tsize - body.rect.w;
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
		//ang = 0;
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
		//reset effects
		if (insides.clones.length > 0) {
			body.rotate = insides.clones[0].rotate;
			var dir = insides.clones[0].dir;
			if (dir != -1) body.dir = dir;
			insides.clones = [];
		}
		
		teleport(body, out);
		invertSpeeds(body, side, out.side);
		out.collision(body);
		//effectMode(body, this);
		//throw {};
	}
	
	inline function teleport(body:Body, out:Portal):Void {
		var off = lvl.scale;
		var x = out.rect.x, y = out.rect.y;
		
		if (out.side == 0) {
			x += tsize/2 - body.rect.w/2;
			y += -body.rect.h/2 - off - 1;
			
		} else if (out.side == 1) {
			x += tsize/2 - body.rect.w/2;
			y += off + 1 - body.rect.h/2;
			
		} else if (out.side == 2) {
			x += -body.rect.w/2 - off; //fix -1?
			if (side == 2 || side == 3) y += (body.rect.y - rect.y);
			
		} else if (out.side == 3) {
			x += -body.rect.w/2 + off + 1;
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
		if (side != 1 && out == 0) { //speed-up
			var min = -lvl.scale * 4;
			if (body.speed.y > min) body.speed.y = min;
			if (side == 2 || side == 3) body.speed.x = 0;
		}
		
		//rotate speeds
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
		switch(side) {
			case 0: v = {x: 0, y: -1}; //up
			case 1: v = {x: 0, y: 1}; //down
			case 2: v = {x: -1, y: 0}; //left
			case 3: v = {x: 1, y: 0}; //right
			default: v = {x: 0, y: 0};
		}
		return v;
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
		//lvl.drawTile(1, tile.x, tile.y, g, tileId);
		g.color = colors[type];
		g.fillRect(
			rect.x + lvl.camera.x,
			rect.y + lvl.camera.y,
			rect.w, rect.h
		);
		drawLabel(g);
		drawParticles(g);
	}
	
	inline function drawLabel(g:Graphics):Void {
		var screen:Rect = {
			x: -lvl.camera.x, y: -lvl.camera.y,
			w: Screen.w, h: Screen.h
		};
		if (!Utils.AABB(rect, screen)) {
			var size = Std.int(lvl.tsize/8) * lvl.scale;
			var x = rect.x + lvl.camera.x - size/2 + rect.w/2;
			var y = rect.y + lvl.camera.y - size/2 + rect.h/2;
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
	
	inline function drawParticles(g:Graphics):Void {
		for (p in particles) p.draw(g, lvl.camera.x, lvl.camera.y);
	}
	
}
