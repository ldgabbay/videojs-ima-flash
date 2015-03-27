
    // Expose Widget identifier, even in AMD
    // and CommonJS for browser emulators
    if ( typeof noGlobal === typeof undefined ) {
    	Widget._old;
    	Widget.noConflict = function() {
    		window.Widget = Widget._old;
    		delete Widget._old;
    		return Widget;
    	};
		window.Widget = Widget;
    }

    return Widget;

}));
