package;

import kha.Framebuffer;
import kha.graphics2.Graphics;
import kha.input.Keyboard;
import kha.input.KeyCode;
import kha.input.Surface;
import kha.input.Mouse;
import kha.Scheduler;
import kha.System;
import kha.Assets;
#if kha_g4
import kha.Shaders;
import kha.graphics4.BlendingFactor;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
#end

//Сlass to unify mouse/touch events and setup game screens

typedef Pointer = {
	id:Int,
	startX:Int,
	startY:Int,
	x:Int,
	y:Int,
	moveX:Int,
	moveY:Int,
	type:Int,
	isDown:Bool,
	used:Bool
}

class Screen {
	
	public static var screen:Screen; //current screen
	public static var w(default, null):Int; //for resize event
	public static var h(default, null):Int;
	public static var touch(default, null) = false;
	static var lastTime = 0.0; //for fps counter
	static var taskId:Int;
	
	public var scale(default, null) = 1.0;
	public var keys:Map<Int, Bool> = new Map();
	public var pointers:Map<Int, Pointer> = [
		for (i in 0...10) i => {id: i, startX: 0, startY: 0, x: 0, y: 0, moveX: 0, moveY: 0, type: 0, isDown: false, used: false}
	];
	#if kha_g4
	static var _pipeline:PipelineState;
	static var _struct:VertexStructure;
	#end
	
	public function new() {}
	
	public static function _init(?touchMode:Bool):Void {
		w = System.windowWidth();
		h = System.windowHeight();
		#if kha_html5
		touch = untyped __js__('"ontouchstart" in window');
		#elseif (kha_android || kha_ios)
		touch = true;
		#end
		if (touchMode != null) touch = touchMode;
		
		#if kha_g4
		_struct = new VertexStructure();
		_struct.add("vertexPosition", VertexData.Float3);
		_struct.add("texPosition", VertexData.Float2);
		_struct.add("vertexColor", VertexData.Float4);
		
		_pipeline = new PipelineState();
		_pipeline.inputLayout = [_struct];
		_pipeline.vertexShader = Shaders.painter_image_vert;
		_pipeline.fragmentShader = Shaders.painter_image_frag;
		_pipeline.blendSource = BlendingFactor.BlendOne;
		_pipeline.blendDestination = BlendingFactor.BlendZero;
		_pipeline.alphaBlendSource = BlendingFactor.BlendOne;
		_pipeline.alphaBlendDestination = BlendingFactor.BlendZero;
		_pipeline.compile();
		#end
	}
	
	public static inline function pipeline(g:Graphics):Void {
		#if kha_g4
		g.pipeline = _pipeline;
		#end
	}
	
	public function show():Void {
		if (screen != null) screen.hide();
		screen = this;
		
		taskId = Scheduler.addTimeTask(onUpdate, 0, 1/60);
		System.notifyOnRender(_onRender);
		
		if (Keyboard.get() != null) Keyboard.get().notify(_onKeyDown, _onKeyUp);
		
		if (touch && Surface.get() != null) {
			Surface.get().notify(_onTouchDown, _onTouchUp, _onTouchMove);
		} else if (Mouse.get() != null) {
			Mouse.get().notify(_onMouseDown, _onMouseUp, _onMouseMove, null);
		}
		for (k in keys) k = false;
		for (p in pointers) p.isDown = false;
	}
	
	public function hide():Void {
		Scheduler.removeTimeTask(taskId);
		System.removeRenderListener(_onRender);
		
		if (Keyboard.get() != null) Keyboard.get().remove(_onKeyDown, _onKeyUp, null);
		
		if (touch && Surface.get() != null) {
			Surface.get().remove(_onTouchDown, _onTouchUp, _onTouchMove);
		} else if (Mouse.get() != null) {
			Mouse.get().remove(_onMouseDown, _onMouseUp, _onMouseMove, null);
		}
	}
	
	inline function _onRender(framebuffer:Framebuffer):Void {
		if (System.windowWidth() != w || System.windowHeight() != h) _onResize();
		onRender(framebuffer);
	}
	
	inline function _onResize():Void {
		w = System.windowWidth();
		h = System.windowHeight();
		onResize();
	}
	
	inline function _onKeyDown(key:KeyCode):Void {
		keys[key] = true;
		onKeyDown(key);
	}
	
	inline function _onKeyUp(key:KeyCode):Void {
		keys[key] = false;
		onKeyUp(key);
	}
	
	inline function _onMouseDown(button:Int, x:Int, y:Int):Void {
		pointers[0].startX = x;
		pointers[0].startY = y;
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].type = button;
		pointers[0].isDown = true;
		pointers[0].used = true;
		onMouseDown(pointers[0]);
	}
	
	inline function _onMouseMove(x:Int, y:Int, mx:Int, my:Int):Void {
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].moveX = mx;
		pointers[0].moveY = my;
		pointers[0].used = true;
		onMouseMove(pointers[0]);
	}
	
	inline function _onMouseUp(button:Int, x:Int, y:Int):Void {
		if (!pointers[0].used) return;
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].type = button;
		pointers[0].isDown = false;
		onMouseUp(pointers[0]);
	}
	
	inline function _onTouchDown(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		pointers[id].startX = x;
		pointers[id].startY = y;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isDown = true;
		pointers[id].used = true;
		onMouseDown(pointers[id]);
	}
	
	inline function _onTouchMove(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		pointers[id].moveX = x - pointers[id].x;
		pointers[id].moveY = y - pointers[id].y;
		pointers[id].x = x;
		pointers[id].y = y;
		onMouseMove(pointers[id]);
	}
	
	inline function _onTouchUp(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		if (!pointers[id].used) return;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isDown = false;
		onMouseUp(pointers[id]);
	}
	
	function debugScreen(g:Graphics):Void {
		var fps = Math.floor(1 / (Scheduler.realTime() - lastTime));
		lastTime = Scheduler.realTime();
		g.color = 0xFFFFFFFF;
		g.font = Assets.fonts.OpenSans_Regular;
		g.fontSize = 24;
		var txt = fps+" | "+System.windowHeight()+"x"+System.windowWidth();
		var x = System.windowWidth() - g.font.width(g.fontSize, txt);
		var y = System.windowHeight() - g.font.height(g.fontSize);
		g.drawString(txt, x, y);
	}
	
	function setScale(scale:Float):Void {
		onRescale(scale);
		this.scale = scale;
	}
	
	//functions to override
	
	function onRescale(scale:Float):Void {}
	function onResize():Void {}
	function onUpdate():Void {}
	function onRender(framebuffer:Framebuffer):Void {}
	
	public function onKeyDown(key:KeyCode):Void {}
	public function onKeyUp(key:KeyCode):Void {}
	
	public function onMouseDown(p:Pointer):Void {}
	public function onMouseMove(p:Pointer):Void {}
	public function onMouseUp(p:Pointer):Void {}
	
}
