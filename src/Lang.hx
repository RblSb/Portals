package;

class Lang {

	static var EN:Map<String, String> = [
		"portals" => "Portals! 2D",
		"loading" => "Loading...",
		"yes" => "Yes",
		"no" => "No",
		"on" => "On",
		"off" => "Off",
		
		"game" => "Game",
		"level_editor" => "Level Editor",
		"settings" => "Settings",
		"info" => "Info",
		"exit" => "Exit",
		
		"continue" => "Continue",
		"new_game" => "New Game",
		"level_select" => "Level Select",
		"levels_online" => "Levels Online",
		"back" => "Back",
		
		"play_traning" => "Play Training?",
		"are_you_sure" => "Are you sure?",
		"reset_warning" => "The data will be lost.",
		"training" => "Training",
		"level" => "Level",
		
		"path" => "Path",
		"width" => "Width",
		"height" => "Height",
		"create" => "Create",
		
		"music" => "Music",
		"control_type" => "Control Type",
		"language" => "Language",
		"touch" => "Touch",
		"other" => "Other",
		
		"reset_data" => "Reset Data",
		
		"about_game" => "About Game",
		"about_editor" => "About Editor",
		"about_authors" => "About Authors",
		"github" => "Github",
		
		"restart" => "Restart",
		"main_menu" => "Main Menu",
		
		"file" => "File",
		"edit" => "Edit",
		"view" => "View",
		"help" => "Help",
		"about" => "About",
		"new" => "New",
		"open" => "Open",
		"save" => "Save",
		"file_sets" => "File Sets",
		"write_gif" => "Write GIF",
		"undo" => "Undo",
		"redo" => "Redo",
		"grid" => "Grid",
		"toggle_theme" => "Toggle Theme",
		"reset_scale" => "Reset Scale"
	];
	static var RU:Map<String, String> = [
		"loading" => "Загрузка...",
		"yes" => "Да",
		"no" => "Нет",
		"on" => "Вкл",
		"off" => "Выкл",
		
		"game" => "Игра",
		"level_editor" => "Редактор карт",
		"settings" => "Настройки",
		"info" => "Инфо",
		"exit" => "Выход",
		
		"continue" => "Продолжить",
		"new_game" => "Новая игра",
		"level_select" => "Выбор уровня",
		"levels_online" => "Онлайн-список",
		"back" => "Назад",
		
		"play_traning" => "Пройти обучение?",
		"are_you_sure" => "Вы уверены?",
		"reset_warning" => "Данные будут потеряны.",
		"training" => "Обучение",
		"level" => "Уровень",
		
		"path" => "Путь",
		"width" => "Ширина",
		"height" => "Высота",
		"create" => "Создать",
		
		"music" => "Музыка",
		"control_type" => "Тип управления",
		"language" => "Язык",
		"touch" => "Тачскрин",
		"other" => "Прочее",
		
		"reset_data" => "Сбросить данные",
		
		"about_game" => "Об игре",
		"about_editor" => "О редакторе",
		"about_authors" => "Об авторах",
		
		"restart" => "Рестарт",
		"main_menu" => "Главное меню",
		
		"file" => "Файл",
		"edit" => "Правка",
		"view" => "Вид",
		"help" => "Помощь",
		"about" => "Об игре",
		"new" => "Новый",
		"open" => "Открыть",
		"save" => "Сохранить",
		"file_sets" => "Настройки проекта",
		"write_gif" => "Записать в GIF",
		"undo" => "Отменить",
		"redo" => "Повторить",
		"grid" => "Сетка",
		"toggle_theme" => "Сменить тему",
		"reset_scale" => "Сбросить масштаб"
	];
	static var current(default, null):Map<String, String>;
	public static var langs(default, null) = ["en", "ru"];
	public static var iso(default, null):String;
	public static var fontGlyphs(default, null):Array<Int>;
	
	public static function init() {
		var iso = "en";
		#if kha_html5
		iso = js.Browser.navigator.language;
		#elseif cpp
		//iso = untyped __cpp__('std::locale("").name()');
		#end
		var exist = false;
		for (lang in langs)
			if (lang == iso) exist = true;
		
		if (!exist) iso = "en";
		iso = iso.substring(0, 2);
		set(iso);
	}
	
	public static function get(id:String) {
		var s = current[id];
		if (s == null) {
			s = EN[id];
			if (s == null) return id;
		}
		return s;
	}
	
	public static function set(id:String) {
		iso = id;
		fontGlyphs = [];
		for (i in 32...256) {
			fontGlyphs.push(i);
		}
		
		switch(iso) {
			case "ru": current = RU;
			for (i in 1024...1106) { //1024...1280
				fontGlyphs.push(i);
			}
			default: current = EN;
		}
	}
	
	public static inline function fastGet(id:String) {
		return current[id];
	}
	
}
