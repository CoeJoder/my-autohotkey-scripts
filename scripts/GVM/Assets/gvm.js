GVM = window.GVM || {};

(function($) {
	// detect when the "params" section becomes wrapped
	GVM.$container = $("#container");
	GVM.$sections = $(".section");
	GVM.$macros = GVM.$sections.eq(0);
	GVM.$params = GVM.$sections.eq(1);
	
	// resizes the params section depending on it's location
	GVM.checkForWrapping = function() {
		var macrosTop = GVM.$macros.offset().top;
		var paramsTop = GVM.$params.offset().top;
		if (macrosTop < paramsTop) {
			GVM.$params.css({"width": GVM.$macros.width(), "height": ""});
		}
		else {
			GVM.$params.css({"width": "", "height": GVM.$macros.height()});
		}
	};
	
	// called on console window resize
	GVM.onConsoleResize = function() {
		GVM.$params.css({'width': '', 'height': ''});
		GVM.checkForWrapping();
	};

	GVM.checkForWrapping();
})(jQuery);
