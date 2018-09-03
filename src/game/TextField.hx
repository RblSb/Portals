package game;

import kha.graphics2.Graphics;
import kha.Color;
import kha.Font;
import kha.Assets;
import kha.SuperString;
import khm.Screen;

class TextField {

	static inline var alphaMax = 50;
	var alpha:Int;
	var state = 0;
	var h:Float;

	var fontH:Float;
	var font:Font;
	var fontSize:Int;

	var text:SuperString;
	var author:SuperString;
	var lines:Array<SuperString>;
	var offset:Int;
	var txx:Int;
	var txy:Int;

	public function new() {}

	public function init(scale:Float):Void {
		font = Assets.fonts.OpenSans_Regular;
		rescale(scale);
	}

	public function show(text:SuperString, author:SuperString):Void {
		if (text == "" && author == "") return;
		//trace(text+"| "+author);
		this.text = text;
		this.author = author;
		parseTextField(text, author);
		offset = 0;
		alpha = 0;
		state = 1;
	}

	public function rescale(scale:Float):Void {
		fontSize = 24 * Std.int(scale);
		fontH = font.height(fontSize);
		h = fontH * 4;
		if (state == 0) return;

		parseTextField(text, author);
		offset = 0;
		alpha = alphaMax;
		state = 3;
	}

	public function close(force=false):Void {
		if (force) {state = 0; return;}
		if (state == 3) {
			if (offset + h / fontH < lines.length) {
				offset += Std.int(h / fontH);
				state = 2;
				txy = 0;
				txx = 0;
			} else state = 0;
		} else if (state == 2) state = 3;
	}

	inline function parseTextField(text:SuperString, author:SuperString):Void {
		lines = parseText(text, Screen.w, true);
	}

	function parseText(text:SuperString, width:Float, wordWrap:Bool):Array<String> {
		var lines:Array<String> = [];
		var lastChance = -1;
		var lastBreak = 0;
		var i = 0;
		var origWidth = width;

		while (i < text.length) {
			var line = text.substring(lastBreak, i + 1);
			var fw = font.width(fontSize, line);

			if (lines.length % (h / fontH) == h / fontH - 1) //last line offset
				width = origWidth - font.width(fontSize, author);
			else width = origWidth;

			if (fw > width) {
				if (lastChance < 0 || !wordWrap) lastChance = i - 1;
				lines.push(text.substring(lastBreak, lastChance + 1));
				i = lastBreak = lastChance + 1;
				lastChance = -1;
			}

			var char = text.substring(i, i + 1);
			if (char == " ") lastChance = i;
			else if (char == "\n") {
				lines.push(text.substring(lastBreak, i + 1));
				lastBreak = i + 1;
				lastChance = -1;
			}
			i++;
		}
		var end = text.substring(lastBreak);
		if (end != "" && end != " ") lines.push(end);
		return lines;
	}

	function animBG(g:Graphics):Void {
		alpha += 2;
		drawBG(g);

		if (alpha >= alphaMax) {
			state = text.length > 0 ? 2 : 3;
			txy = 0;
			txx = 0;
			alpha = 50;
		}
	}

	inline function drawBG(g:Graphics):Void {
		var color:Color = 0xFFFFFFFF;
		color.A = alpha / 100;
		g.color = color;
		g.fillRect(0, 0, Screen.w, h);
		g.color = 0xFF000000;
		g.drawLine(0, h, Screen.w / alphaMax * alpha, h);
	}

	function animText(g:Graphics):Void {
		drawBG(g);

		for (i in 0...txy) g.drawString(lines[offset+i], 0, i * fontH);
		var substr = lines[offset+txy].substring(0, txx);
		g.drawString(substr, 0, txy * fontH);

		if (txx < lines[offset+txy].length) txx++;
		else { //new line
			if ((txy + 1 < h / fontH) && (offset + txy + 1 < lines.length)) {
				txx = 0;
				txy++;
			} else state = 3;
		}

		drawAuthor(g);
	}


	inline function drawAuthor(g:Graphics):Void {
		var autw = font.width(fontSize, author);
		g.fillRect(Screen.w - autw, h - fontH, autw, fontH);
		g.color = 0xFFFFFFFF;
		g.drawString(author, Screen.w - autw, h - fontH);
	}

	function showing(g:Graphics):Void {
		drawBG(g);
		var len = Std.int(h / fontH);
		for (i in 0...len) {
			if (offset+i < lines.length)
				g.drawString(lines[offset+i], 0, i * fontH);
		}
		drawAuthor(g);
	}

	public function draw(g:Graphics):Void {
		if (state == 0) return;
		g.font = font;
		g.fontSize = fontSize;
		switch(state) {
			case 1: animBG(g);
			case 2: animText(g);
			case 3: showing(g);
		}
	}

}
