package game;

import kha.graphics2.Graphics;
import kha.Image;
import kha.Color;
import kha.math.FastMatrix3;
import kha.FastFloat;
import kha.input.KeyCode;
import ui.Button;
import ui.Trigger;
import Types.Rect;
import Screen.Pointer;

class Touch {
	
	var game:Game;
	var scale = 1.0;
	static inline var BG = 0x10FFFFFF;
	static inline var COLOR = 0xC0000000;
	var buttons:Array<Button>;
	var minusBtn:Image;
	var plusBtn:Image;
	var pauseBtn:Image;
	var actionBtn:Image;
	var mainArrow:Image;
	var subArrow:Image;
	var mainSize = 50;
	var size:Int;
	static var nextAimType = 0;
	
	public function new(game:Game) {
		this.game = game;
		//init();
	}
	
	public function init():Void {
		rescale();
		initImages();
		initButtons();
	}
	
	inline function rescale():Void {
		var min = Screen.w < Screen.h ? Screen.w : Screen.h;
		var scale = min / 300;
		if (scale < 1) scale = 1;
		size = Std.int(mainSize * scale);
	}
	
	inline function initImages():Void {
		actionBtn = Image.createRenderTarget(size, size);
		var g = actionBtn.g2;
		g.begin(true, 0x0);
		fillBG(g);
		g.color = COLOR;
		g.fillRect(
			size/4, size/4,
			size - size/2, size - size/2
		);
		g.end();
		
		mainArrow = Image.createRenderTarget(size, size);
		var g = mainArrow.g2;
		g.begin(true, 0x0);
		fillBG(g);
		g.color = COLOR;
		g.fillTriangle(
			size/2, size/4,
			0, size - size/4,
			size, size - size/4
		);
		g.end();
		
		subArrow = Image.createRenderTarget(size, size);
		var g = subArrow.g2;
		g.begin(true, 0x0);
		fillBG(g);
		g.color = COLOR;
		g.fillTriangle(
			size/2, size/2,
			size/2, size,
			size, size/2
		);
		g.end();
		
		minusBtn = Image.createRenderTarget(size, size);
		var g = minusBtn.g2;
		g.begin(true, 0x0);
		fillBG(g);
		g.color = COLOR;
		var off = size/4;
		var w = size - off * 2;
		var h = size/8;
		g.fillRect(off, size/2 - h/2, w, h);
		g.end();
		
		plusBtn = Image.createRenderTarget(size, size);
		var g = plusBtn.g2;
		g.begin(true, 0x0);
		fillBG(g);
		g.color = COLOR;
		var off = size/4;
		var w = size - off * 2;
		var h = size/8;
		g.fillRect(off, size/2 - h/2, w, h);
		g.fillRect(size/2 - h/2, off, h, w);
		g.end();
		
		pauseBtn = Image.createRenderTarget(size, size);
		var g = pauseBtn.g2;
		g.begin(true, 0x0);
		fillBG(g);
		g.color = COLOR;
		var off = size/4;
		var w = size/8;
		var h = size/2;
		g.fillRect(off, off, w, h);
		g.fillRect(size - off - w, off, w, h);
		g.end();
		
		var fix = Image.createRenderTarget(1, 1); //fix
	}
	
	inline function fillBG(g:Graphics):Void {
		g.color = BG;
		g.fillRect(0, 0, size, size);
	}
	
	inline function initButtons():Void {
		var sx = 0;
		var sy = Screen.h - size * 3;
		buttons = [
			new Button({x: sx + size, y: sy, img: mainArrow, keys: [KeyCode.Up], clickMode: true}),
			new Button({x: sx + size * 2, y: sy + size, img: mainArrow, ang: 90, keys: [KeyCode.Right]}),
			new Button({x: sx + size, y: sy + size * 2, img: mainArrow, ang: 180, keys: [KeyCode.Down]}),
			new Button({x: sx, y: sy + size, img: mainArrow, ang: 270, keys: [KeyCode.Left]}),
			new Button({x: sx + size, y: sy + size, img: actionBtn, keys: [KeyCode.E], clickMode: true}),
			
			new Button({x: sx, y: sy, img: subArrow, keys: [KeyCode.Left, KeyCode.Up]}),
			new Button({x: sx + size * 2, y: sy, img: subArrow, ang: 90, keys: [KeyCode.Right, KeyCode.Up]}),
			new Button({x: sx + size * 2, y: sy + size * 2, img: subArrow, ang: 180, keys: [KeyCode.R], clickMode: true}),
			new Button({x: sx, y: sy + size * 2, img: subArrow, ang: 270, keys: [KeyCode.Q], clickMode: true}),
			new Button({x: Screen.w - size * 3, y: 0, img: minusBtn, keys: [KeyCode.HyphenMinus], clickMode: true}),
			new Button({x: Screen.w - size * 2, y: 0, img: plusBtn, keys: [KeyCode.Equals], clickMode: true}),
			new Button({x: Screen.w - size, y: 0, img: pauseBtn, keys: [KeyCode.Escape], clickMode: true}),
			new Button({x: Screen.w - size, y: Screen.h - size, w: size, h: size, onDown: swapAimType})
		];
	}
	
	public static function swapAimType(p:Pointer):Void {
		nextAimType = nextAimType == 1 ? 0 : 1;
		p.type = nextAimType;
	}
	
	public function resize():Void {
		init();
	}
	
	public function onDown(id:Int):Bool {
		var pointer = game.pointers[id];
		if (Button.onDown(game, buttons, pointer)) return true;
		return false;
	}
	
	public function onMove(id:Int):Bool {
		var pointer = game.pointers[id];
		if (Button.onMove(game, buttons, pointer)) return true;
		return false;
	}
	
	public function onUp(id:Int):Bool {
		var pointer = game.pointers[id];
		if (Button.onUp(game, buttons, pointer)) return true;
		return false;
	}
	
	public function draw(g:Graphics):Void {
		for (b in buttons) b.draw(g);
		var color:Color = Portal.colors[nextAimType];
		color.A = 0.4;
		g.color = color;
		g.fillTriangle(
			Screen.w - size, Screen.h,
			Screen.w, Screen.h - size,
			Screen.w, Screen.h
		);
	}
	
}
