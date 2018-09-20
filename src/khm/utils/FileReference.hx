package khm.utils;

#if kha_html5
import js.Browser.window;
import js.Browser.document;
#end

private typedef FileLoadFunc = Any->String->Void;

class FileReference {

	public static function onDrop(onFileLoad:FileLoadFunc, isBinary = true):Void {
		#if kha_html5
		function drop(e:js.html.DragEvent):Void {
			var file = e.dataTransfer.files[0];
			var reader = new js.html.FileReader();
			reader.onload = function(event) {
				onFileLoad(event.target.result, file.name);
			}
			e.preventDefault();
			if (isBinary) reader.readAsArrayBuffer(file);
			else reader.readAsText(file);
		}

		window.ondragenter = function(e) {
			e.preventDefault();
		};
		window.ondragover = function(e) {
			e.preventDefault();
		};
		window.ondrop = drop;
		#end
	}

	public static function browse(onFileLoad:FileLoadFunc, isBinary = true):Void {
		#if kha_html5
		var input = document.createElement("input");
		input.style.visibility = "hidden";
		input.setAttribute("type", "file");
		input.id = "browse";
		input.onclick = function(e) {
			e.cancelBubble = true;
			e.stopPropagation();
		}
		input.onchange = function() {
			var file:Dynamic = (input:Dynamic).files[0];
			var reader = new js.html.FileReader();
			reader.onload = function(e) {
				onFileLoad(e.target.result, file.name);
				document.body.removeChild(input);

				/*var b = new js.html.Uint8ClampedArray(e.target.result);
				var blob = new js.html.Blob([b]);
				var url = js.html.URL.createObjectURL(blob);
				document.body.innerHTML = '<img src="'+url+'"/>';*/
			}
			if (isBinary) reader.readAsArrayBuffer(file);
			else reader.readAsText(file);
		}
		document.body.appendChild(input);
		input.click();
		#else
		#end
	}

	public static function saveJSON(name:String, json:String):Void {
		#if kha_html5
		var blob = new js.html.Blob([json], {
			type: "application/json"
		});
		var url = js.html.URL.createObjectURL(blob);
		var a = document.createElement("a");
		untyped a.download = name + ".json";
		untyped a.href = url;
		a.onclick = function(e) {
			e.cancelBubble = true;
			e.stopPropagation();
		}
		document.body.appendChild(a);
		a.click();
		document.body.removeChild(a);
		js.html.URL.revokeObjectURL(url);
		#else
		// TODO select path and write file
		#end
	}

	public static function saveCanvas(name:String, w:Int, h:Int, pixels:haxe.io.Bytes):Void {
		#if kha_html5
		var canvas = document.createCanvasElement();
		canvas.width = w;
		canvas.height = h;
		var g = canvas.getContext("2d");
		g.imageSmoothingEnabled = false;
		var imgData = new js.html.ImageData(
			new js.html.Uint8ClampedArray(pixels.getData()), w, h
		);
		g.putImageData(imgData, 0, 0);
		var url = canvas.toDataURL("image/png");
		// document.body.innerHTML = '<img src="'+url+'"/>';
		var a = document.createElement("a");
		untyped a.download = name + ".png";
		untyped a.href = url;
		a.onclick = function(e) {
			e.cancelBubble = true;
			e.stopPropagation();
		}
		document.body.appendChild(a);
		a.click();
		document.body.removeChild(a);
		js.html.URL.revokeObjectURL(url);
		#end
	}

	#if format
	public static function savePNG(name:String, w:Int, h:Int, pixels:haxe.io.Bytes):Void {
		var out = new haxe.io.BytesOutput();
		var writer = new format.png.Writer(out);
		var argb = format.png.Tools.build32ARGB(w, h, pixels);
		writer.write(argb);
		var data = out.getBytes().getData();
	}

	#elseif upng
	public static function savePNG(name:String, w:Int, h:Int, pixels:haxe.io.Bytes):Void {
		#if kha_html5
		var buffer = new js.html.Uint8ClampedArray(pixels.getData());
		var data = UPNG.encodeLL([buffer.buffer], w, h, 3, 1, 8);

		var blob = new js.html.Blob([data], {
			type: "image/png"
		});
		var url = js.html.URL.createObjectURL(blob);
		var a = document.createElement("a");
		untyped a.download = name + ".png";
		untyped a.href = url;
		a.onclick = function(e) {
			e.cancelBubble = true;
			e.stopPropagation();
		}
		document.body.appendChild(a);
		a.click();
		document.body.removeChild(a);
		js.html.URL.revokeObjectURL(url);
		#end
	}
	#end

}
