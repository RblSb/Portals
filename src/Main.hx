package;

import kha.System;
import kha.SystemImpl;
import kha.input.KeyCode;
#if kha_html5
import js.html.CanvasElement;
import js.Browser.document;
import js.Browser.window;
#end

class Main {
	
	//static var hxt = new hxtelemetry.HxTelemetry();
	
	static function main():Void {
		#if kha_html5 //make html5 canvas resizable
		document.documentElement.style.padding = "0";
		document.documentElement.style.margin = "0";
		document.body.style.padding = "0";
		document.body.style.margin = "0";
		var canvas = cast(document.getElementById("khanvas"), CanvasElement);
		canvas.style.display = "block";
		
		var resize = function() {
			canvas.width = Std.int(window.innerWidth * window.devicePixelRatio);
			canvas.height = Std.int(window.innerHeight * window.devicePixelRatio);
			canvas.style.width = document.documentElement.clientWidth + "px";
			canvas.style.height = document.documentElement.clientHeight + "px";
		}
		window.onresize = resize;
		resize();
		#end
		
		System.init({title: "Portals! 2D", width: 800, height: 600}, init);
	}
	
	static function init():Void {
		khacks();
		var loader = new Loader();
		loader.init();
	}
	
	static inline function khacks():Void {
		#if kha_html5 //block browser hotkeys and fix meta key
		var meta_key = false;
		var keyDown = SystemImpl.khanvas.onkeydown;
		SystemImpl.khanvas.onkeydown = function(e) {
			if (e.keyCode == KeyCode.Meta) meta_key = true;
			else if (meta_key) SystemImpl.khanvas.onkeyup(e);
			if (e.keyCode == KeyCode.Backspace) e.preventDefault();
			keyDown(e);
		}
		
		var keyUp = SystemImpl.khanvas.onkeyup;
		SystemImpl.khanvas.onkeyup = function(e) {
			if (e.keyCode == KeyCode.Meta) meta_key = false;
			keyUp(e);
		}
		
		var keyPress = SystemImpl.khanvas.onkeypress;
		SystemImpl.khanvas.onkeypress = function(e) {
			if (meta_key) e.preventDefault();
			keyPress(e);
		}
		#end
	}
	
}
