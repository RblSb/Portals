package khm.editor.ui;

#if kha_html5
import js.Browser.document;
import js.html.Event;
#end

class Modal {

	public static function prompt(name:String, data:String, callback:String->Void):Void {
		var modal = document.createElement("div");
		var form = document.createTextAreaElement();
		var style = document.createStyleElement();

		inline function onClose(e:Event):Void {
			document.body.removeChild(modal);
			document.body.removeChild(style);
			e.stopPropagation();
		}
		function onCancel(e:Event):Void {
			onClose(e);
			callback(null);
		}
		function onSave(e:Event):Void {
			onClose(e);
			callback(form.value);
		}
		modal.className = "modal";
		modal.onclick = onCancel;

		var content = document.createElement("div");
		content.className = "modal-content";
		content.onclick = function(e) {
			e.stopPropagation();
		}

		var title = document.createElement("div");
		title.textContent = name;
		form.style.width = "100%";
		form.rows = 15;
		form.value = data;
		var cancel = document.createButtonElement();
		cancel.innerHTML = "Cancel";
		cancel.onclick = onCancel;
		var save = document.createButtonElement();
		save.innerHTML = "Save";
		save.onclick = onSave;

		content.appendChild(title);
		content.appendChild(form);
		content.appendChild(document.createElement("br"));
		content.appendChild(cancel);
		content.appendChild(save);
		modal.appendChild(content);
		document.body.appendChild(modal);
		style.innerHTML = "
		.modal {
			position: absolute;
			z-index: 1;
			padding-top: 100px;
			left: 0;
			top: 0;
			width: 100%;
			height: 100%;
			overflow: auto;
			background-color: rgb(0, 0, 0);
			background-color: rgba(0, 0, 0, 0.4);
		}

		.modal-content {
			background-color: #fefefe;
			margin: auto;
			padding: 20px;
			border: 1px solid #888;
			width: 80%;
		}
		";
		document.body.appendChild(style);
	}

}
