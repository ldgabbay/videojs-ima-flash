// @require "swfobject-2.2.js"
/* global swfobject */

/**
 * Register the ad integration plugin.
 * To initialize for a player, call player.ima_flash(options).
 *
 * @param {mixed} options Hash of options for the ima_flash plugin.
 */
videojs.plugin("ima_flash", function(options) {

	var player = this;

	var flashvars = {};
	var params = {
		allowScriptAccess: "always",
		allowNetworking: "all",
		wmode: "opaque",
		bgcolor: "#ff0000"
	};


        // <object type="application/x-shockwave-flash" data="http://vjs.zencdn.net/4.12/video-js.swf" width="100%" height="100%" id="video_id_flash_api" name="video_id_flash_api" class="vjs-tech" style="display: block;">
        //     <param name="movie" value="http://vjs.zencdn.net/4.12/video-js.swf">
        //     <param name="flashvars" value="readyFunction=videojs.Flash.onReady&amp;eventProxyFunction=videojs.Flash.onEvent&amp;errorEventProxyFunction=videojs.Flash.onError&amp;autoplay=undefined&amp;preload=undefined&amp;loop=undefined&amp;muted=undefined&amp;">
        //     <param name="allowScriptAccess" value="always">
        //     <param name="allowNetworking" value="all">
        //     <param name="wmode" value="opaque">
        //     <param name="bgcolor" value="#000000">
        // </object>


	swfobject.embedSWF("videojs.ima_flash.swf", options.id, "640", "360", "10.1", null, flashvars, params);

	// player.ads(); // initialize the ad framework

	// // request ads whenever there's new video content
	// player.on('contentupdate', function(){
	// 	// fetch ad inventory asynchronously, then ...
	// 	player.trigger('adsready');
	// });

	// player.on('readyforpreroll', function() {
	// 	player.ads.startLinearAdMode();
	// 	// play your linear ad content
	// 	swfobject.embedSWF("videojs.ima_flash.swf", "flash_target", "640", "360", "10.1");

	// 	// player.src('http://url/to/your/ad.content');
	// 	// player.one('durationchange', function(){
	// 	// 	player.play();
	// 	// });

	// 	// // when all your linear ads have finished...
	// 	// player.one('ended', function() {
	// 	// 	player.ads.endLinearAdMode();
	// 	// });
	// });

/*
	var options = {
		id: 'video_id',
		adTagUrl: 'http://cdn.daxee.com/vpaid/vast.xml'
	};

	player.ima(options);

	// Remove controls from the player on iPad to stop native controls from stealing
	// our click
	var contentPlayer =  document.getElementById('content_video_html5_api');
	if ((navigator.userAgent.match(/iPad/i) || navigator.userAgent.match(/Android/i)) && contentPlayer.hasAttribute('controls')) {
		contentPlayer.removeAttribute('controls');
	}

	// Initialize the ad container when the video player is clicked, but only the
	// first time it's clicked.
	var clickedOnce = false;
	var startEvent = 'click';
	if (navigator.userAgent.match(/iPhone/i) || navigator.userAgent.match(/iPad/i) || navigator.userAgent.match(/Android/i)) {
		startEvent = 'tap';
	}
	player.on(startEvent, function() {
		if (!clickedOnce) {
			player.ima.initializeAdDisplayContainer();
			player.ima.requestAds();
			player.play();
			clickedOnce = true;
		}
	});
*/
});
