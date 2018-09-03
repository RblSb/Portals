package;

import kha.System;
import kha.Window;
import khm.Macro;
#if kha_html5
import js.html.CanvasElement;
import js.Browser.document;
import js.Browser.window;
#end

class Main {

	static function main():Void {
		trace(Macro.getBuildTime());
		setFullWindowCanvas();

		System.start({title: "Portals! 2D", width: 800, height: 600}, init);
	}

	static function init(window:Window):Void {
		var loader = new Loader();
		loader.init();
	}

	static function setFullWindowCanvas():Void {
		#if kha_html5
		//make html5 canvas resizable
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
	}

}
