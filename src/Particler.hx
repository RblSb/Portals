package;

import kha.graphics2.Graphics;
import kha.math.Vector2;
import kha.Color;
import khm.Types.Rect;

private typedef ParticleSets = {
	x:Float,
	y:Float,
	?speed:Vector2,
	?wobble:Vector2,
	?gravity:Vector2,
	lifeTime:Int,
	?delay:Int,
	color:Int
}

private typedef ParticlerSets = {
	> ParticleSets,
	count:Int,
	?loop:Bool,
	?w:Float,
	?h:Float
}

class Particler {

	public var particles:Array<Particle> = [];
	public var rect:Rect;
	public var lifeTime:Int;
	public var loop:Bool;

	public function new(sets:ParticlerSets) {
		rect = {x: sets.x, y: sets.y, w: 0, h: 0};
		if (sets.w != null) rect.w = sets.w;
		if (sets.h != null) rect.h = sets.h;
		loop = sets.loop == null ? true : sets.loop;
		lifeTime = sets.lifeTime;

		var delay = Std.int(60 / lifeTime);
		var addDelay = sets.delay == null ? 0 : sets.delay;
		addDelay = addDelay * delay;

		for (i in 0...sets.count) {
			sets.x = rect.x + Math.random() * rect.w;
			sets.y = rect.y + Math.random() * rect.h;
			sets.delay = (delay + addDelay) * i;
			particles.push(new Particle(this, sets));
		}
	}

	public function update():Void {
		for (p in particles) p.update();
	}

	public function draw(g:Graphics, cx:Float, cy:Float):Void {
		for (p in particles) p.draw(g, cx, cy);
	}

}

class Particle {

	public var ctx:Particler;
	public var x:Float;
	public var y:Float;
	public var speed:Vector2;
	public var wobble:Vector2;
	public var gravity:Vector2;
	public var color:Color;
	public var lifeTime:Int;
	public var delay:Int;

	public function new(ctx:Particler, sets:ParticleSets) {
		this.ctx = ctx;
		x = sets.x;
		y = sets.y;
		speed = sets.speed == null ? new Vector2() : sets.speed;
		wobble = sets.wobble == null ? new Vector2() : sets.wobble;
		gravity = sets.gravity == null ? new Vector2() : sets.gravity;
		color = sets.color;
		lifeTime = sets.lifeTime;
		delay = sets.delay;
	}

	public function update():Void {
		if (delay > 0) {
			if (!ctx.loop) ctx.particles.remove(this);
			delay--;
			return;
		}
		x += speed.x + gravity.x - wobble.x * 2 * Math.random() + wobble.x;
		y += speed.y + gravity.y - wobble.y * 2 * Math.random() + wobble.y;
		lifeTime--;

		if (lifeTime == 0) recreate();
	}

	inline function recreate() {
		if (!ctx.loop) {
			ctx.particles.remove(this);
			return;
		}
		lifeTime = ctx.lifeTime;
		x = ctx.rect.x + Math.random() * ctx.rect.w;
		y = ctx.rect.y + Math.random() * ctx.rect.h;
	}

	public function draw(g:Graphics, cx:Float, cy:Float):Void {
		if (delay > 0) return;
		color.A = lifeTime / ctx.lifeTime;
		g.color = color;
		g.fillRect(x + cx, y + cy, 1, 1);
	}

}
