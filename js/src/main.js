// @require "swfobject-2.2.js"
/* global swfobject */

/*
https://developers.google.com/interactive-media-ads/docs/sdks/flash/v3/quickstart
https://github.com/videojs/videojs-contrib-ads
https://raw.githubusercontent.com/videojs/videojs-contrib-ads/master/ad-states.png
https://github.com/videojs/video.js/blob/master/docs/api/vjs.Player.md
 */

// <object type="application/x-shockwave-flash" data="http://vjs.zencdn.net/4.12/video-js.swf" width="100%" height="100%" id="video_id_flash_api" name="video_id_flash_api" class="vjs-tech" style="display: block;">
//     <param name="movie" value="http://vjs.zencdn.net/4.12/video-js.swf">
//     <param name="flashvars" value="readyFunction=videojs.Flash.onReady&amp;eventProxyFunction=videojs.Flash.onEvent&amp;errorEventProxyFunction=videojs.Flash.onError&amp;autoplay=undefined&amp;preload=undefined&amp;loop=undefined&amp;muted=undefined&amp;">
//     <param name="allowScriptAccess" value="always">
//     <param name="allowNetworking" value="all">
//     <param name="wmode" value="opaque">
//     <param name="bgcolor" value="#000000">
// </object>


var
    extend = function(obj) {
        var arg;
        var index;
        var key;
        for (index = 1; index < arguments.length; index++) {
            arg = arguments[index];
            for (key in arg) {
                if (arg.hasOwnProperty(key)) {
                    obj[key] = arg[key];
                }
            }
        }
        return obj;
    },

    hasClass = function(element, cls) {
        return (' ' + element.className + ' ').indexOf(' ' + cls + ' ') > -1;
    },

    ima_defaults = {
        debug: false,
        timeout: 2000,
        prerollTimeout: 1000,
        swfUrl: "http://tout.queuecontinuum.com/videojs.ima_flash.swf"
    };


/**
 * SWF/JS bridge methods
 */

window.videojs_error = function(id, errorMessage) {
    console.error('videojs_ima_flash', id, errorMessage);
};

window.videojs_trigger = function(id, eventName) {
    console.log('videojs_trigger', id, eventName);
    videojs(id).trigger(eventName);
};

window.videojs_currentTime = function(id) {
    console.log('videojs_currentTime', id);
    return videojs(id).currentTime();
};

window.videojs_ima_flash_pauseContent = function(id) {
    console.log('videojs_ima_flash_pauseContent', id);
    videojs(id).ima_flash.pauseContent();
};

window.videojs_ima_flash_resumeContent = function(id) {
    console.log('videojs_ima_flash_resumeContent', id);
    videojs(id).ima_flash.resumeContent();
};


/**
 * Register the ad integration plugin.
 * To initialize for a player, call player.ima_flash(options).
 *
 * @param {mixed} options Hash of options for the ima_flash plugin.
 */
videojs.plugin("ima_flash", function(options, readyCallback) {

    var player = this;

    /**
     * Div used as an ad container.
     */
    var adContainerDiv;

    var swfDiv;
    var swfElement = null;


    /**
     * Stores user-provided settings.
     */
    var settings;

    /**
     * Boolean flag to show or hide the ad countdown timer.
     */
    var showCountdown;

    /**
     * Video.js control bar.
     */
    var vjsControls;

    /**
     * Div used to display ad controls.
     */
    var controlsDiv;

    /**
     * Div used to display ad countdown timer.
     */
    var countdownDiv;

    /**
     * Div used to display add seek bar.
     */
    var seekBarDiv;

    /**
     * Div used to display ad progress (in seek bar).
     */
    var progressDiv;

    /**
     * Div used to display ad play/pause button.
     */
    var playPauseDiv;

    /**
     * Div used to display ad mute button.
     */
    var muteDiv;

    /**
     * Div used to display ad fullscreen button.
     */
    var fullscreenDiv;

    /**
     * IMA SDK AdDisplayContainer.
     */
    var adDisplayContainer;

    /**
     * True if the AdDisplayContainer has been initialized. False otherwise.
     */
    var adDisplayContainerInitialized = false;

    /**
     * IMA SDK AdsLoader
     */
    var adsLoader;

    /**
     * IMA SDK AdsManager
     */
    var adsManager;

    /**
     * IMA SDK AdsRenderingSettings.
     */
    var adsRenderingSettings = null;

    /**
     * Current IMA SDK Ad.
     */
    var currentAd;

    /**
     * Timer used to track content progress.
     */
    var contentTrackingTimer;

    /**
     * Timer used to track ad progress.
     */
    var adTrackingTimer;

    /**
     * True if ads are currently displayed, false otherwise.
     * True regardless of ad pause state if an ad is currently being displayed.
     */
    var adsActive = false;

    /**
     * True if ad is currently playing, false if ad is paused or ads are not
     * currently displayed.
     */
    var adPlaying = false;

    /**
     * True if the ad is muted, false otherwise.
     */
    var adMuted = false;

    /**
     * True if our content video has completed, false otherwise.
     */
    var contentComplete = false;

    /**
     * Handle to interval that repeatedly updates current time.
     */
    var updateTimeIntervalHandle;

    /**
     * Handle to interval that repeatedly checks for seeking.
     */
    var seekCheckIntervalHandle;

    /**
     * Interval (ms) on which to check if the user is seeking through the
     * content.
     */
    var seekCheckInterval = 1000;

    /**
     * Threshold by which to judge user seeking. We check every 1000 ms to see
     * if the user is seeking. In order for us to decide that they are *not*
     * seeking, the content video playhead must only change by 900-1100 ms
     * between checks. Any greater change and we assume the user is seeking
     * through the video.
     */
    var seekThreshold = 100;

    /**
     * Stores data for the content playhead tracker.
     */
    var contentPlayheadTracker = {
        currentTime: 0,
        previousTime: 0,
        seeking: false,
        duration: 0
    };


    /**
     * Content ended listeners passed by the publisher to the plugin. Publishers
     * should allow the plugin to handle content ended to ensure proper support
     * of custom ad playback.
     */
    var contentEndedListeners = [];

    /**
     * Timer for updating displayed ad progress
     */
    var _adProgressTimer = null;










    player.ima_flash.setTag = function(tag) {
        console.log("setTag():", tag);
        swfElement.setTag(tag);
    };

    /**
     * Start ad playback, or content video playback in the absence of a
     * pre-roll.
     */
    player.ima_flash.start = function() {
        // TODO
        // try {
        //   adsManager.init(
        //       player.width(),
        //       player.height(),
        //       google.ima.ViewMode.NORMAL);
        //   adsManager.setVolume(player.muted() ? 0 : player.volume());
        //   adsManager.start();
        // } catch (adError) {
        //    player.ima_flash.onAdError_(adError);
        // }
    };

    /**
     * Listener for errors fired by the AdsLoader.
     * @param {google.ima.AdErrorEvent} event The error event thrown by the
     *     AdsLoader. See
     *     https://developers.google.com/interactive-media-ads/docs/sdks/html5/v3/apis#ima.AdError.Type
     * @ignore
     */
    player.ima_flash.onAdsLoaderError_ = function(event) {
        // TODO
        // window.console.log('AdsLoader error: ' + event.getError());
        // if (adsManager) {
        //   adsManager.destroy();
        // }
        // player.trigger('adserror');
    };

    /**
     * Listener for errors thrown by the AdsManager.
     * @param {google.ima.AdErrorEvent} adErrorEvent The error event thrown by
     *     the AdsManager.
     * @ignore
     */
    player.ima_flash.onAdError_ = function(adErrorEvent) {
        console.warn(adErrorEvent);
        // TODO
        // window.console.log('Ad error: ' + adErrorEvent.getError());
        // adsManager.destroy();
        // adContainerDiv.style.display = 'none'; // do not hide swf, it effectively destroys the object
        player.trigger('adserror');
    };


    player.on('swf_ready', function() {
        console.log('swf_ready');
    });

    player.ima_flash.pauseContent = function() {
        console.log('pauseContent');

        player.pause();

        adsActive = true;
        adPlaying = true;
        // player.off('ended', localContentEndedListener);
        // if (adEvent.getAd().getAdPodInfo().getPodIndex() != -1) {
        // Skip this call for post-roll ads
        player.ads.startLinearAdMode();
        // }
        vjsControls.hide();
        document.getElementById(player.id() + '_html5_api').style.display = 'none';
        // adContainerDiv.style.display = 'block'; // should always be visible
        controlsDiv.style.display = 'block';

        swfElement.setAdVolume(player.volume(), player.muted());

        _adProgressTimer = setInterval(function() {
            var remainingTime = swfElement.getRemainingTime();
            var remainingMinutes = Math.floor(remainingTime / 60);
            var remainingSeconds = Math.floor(remainingTime % 60);
            if (remainingSeconds.toString().length < 2) {
              remainingSeconds = '0' + remainingSeconds;
            }
            countdownDiv.innerHTML = 'Advertisement ' + remainingMinutes + ':' + remainingSeconds;
        }, 250);
    };

    player.ima_flash.resumeContent = function() {
        console.log('resumeContent');

        clearInterval(_adProgressTimer);
        _adProgressTimer = null;

        adsActive = false;
        adPlaying = false;
        // player.on('ended', localContentEndedListener);
        // adContainerDiv.style.display = 'none'; // do not hide swf, it effectively destroys the object
        controlsDiv.style.display = 'none';
        document.getElementById(player.id() + '_html5_api').style.display = 'inline-block';
        vjsControls.show();
        // if (!currentAd) {
        //   // Something went wrong playing the ad
        //   player.ads.endLinearAdMode();
        // } else if (!contentComplete &&
        //     // Don't exit linear mode after post-roll or content will auto-replay
        //     currentAd.getAdPodInfo().getPodIndex() != -1 ) {
        //   player.ads.endLinearAdMode();
        // }
        player.ads.endLinearAdMode();
        // countdownDiv.innerHTML = '';
    };


    //    /**
    //     * Starts the content video when a non-linear ad is loaded.
    //     * @param {google.ima.AdEvent} adEvent The AdEvent thrown by the AdsManager.
    //     * @ignore
    //     */
    //    player.ima_flash.onAdLoaded_ = function(adEvent) {
    //        if (!adEvent.getAd().isLinear()) {
    //            player.play();
    //        }
    //    };
    //
    //    /**
    //     * Starts the interval timer to check the current ad time when an ad starts
    //     * playing.
    //     * @param {google.ima.AdEvent} adEvent The AdEvent thrown by the AdsManager.
    //     * @ignore
    //     */
    //    player.ima_flash.onAdStarted_ = function(adEvent) {
    //        currentAd = adEvent.getAd();
    //        if (currentAd.isLinear()) {
    //            adTrackingTimer = setInterval(
    //                player.ima_flash.onAdPlayheadTrackerInterval_, 250);
    //            // Don't bump container when controls are shown
    //            adContainerDiv.className = '';
    //        } else {
    //            // Bump container when controls are shown
    //            adContainerDiv.className = 'bumpable-ima-flash-ad-container';
    //        }
    //    };
    //
    //    /**
    //     * Clears the interval timer for current ad time when an ad completes.
    //     * @param {google.ima.AdEvent} adEvent The AdEvent thrown by the AdsManager.
    //     * @ignore
    //     */
    //    player.ima_flash.onAdComplete_ = function(adEvent) {
    //        if (currentAd.isLinear()) {
    //            clearInterval(adTrackingTimer);
    //        }
    //    };
    //
    //    /**
    //     * Gets the current time and duration of the ad and calls the method to
    //     * update the ad UI.
    //     * @ignore
    //     */
    //    player.ima_flash.onAdPlayheadTrackerInterval_ = function() {
    //        var remainingTime = adsManager.getRemainingTime();
    //        var duration = currentAd.getDuration();
    //        var currentTime = duration - remainingTime;
    //        currentTime = currentTime > 0 ? currentTime : 0;
    //        var isPod = false;
    //        var adPosition, totalAds;
    //        if (currentAd.getAdPodInfo()) {
    //            isPod = true;
    //            adPosition = currentAd.getAdPodInfo().getAdPosition();
    //            totalAds = currentAd.getAdPodInfo().getTotalAds();
    //        }
    //
    //        // Update countdown timer data
    //        var remainingMinutes = Math.floor(remainingTime / 60);
    //        var remainingSeconds = Math.floor(remainingTime % 60);
    //        if (remainingSeconds.toString().length < 2) {
    //            remainingSeconds = '0' + remainingSeconds;
    //        }
    //        var podCount = ': ';
    //        if (isPod) {
    //            podCount = ' (' + adPosition + ' of ' + totalAds + '): ';
    //        }
    //        countdownDiv.innerHTML =
    //            'Advertisement' + podCount +
    //            remainingMinutes + ':' + remainingSeconds;
    //
    //        // Update UI
    //        var playProgressRatio = currentTime / duration;
    //        var playProgressPercent = playProgressRatio * 100;
    //        progressDiv.style.width = playProgressPercent + '%';
    //    };


    // TODO ensure midroll ads if user seeks
    //
    //    /**
    //     * Set up intervals to check for seeking and update current video time.
    //     */
    // //    player.ima_flash.setUpPlayerIntervals_ = function() {
    //        updateTimeIntervalHandle =
    //            setInterval(player.ima_flash.updateCurrentTime, seekCheckInterval);
    //        seekCheckIntervalHandle =
    //            setInterval(player.ima_flash.checkForSeeking, seekCheckInterval);
    //    };
    //
    //    /**
    //     * Updates the current time of the video
    //     */
    //    player.ima_flash.updateCurrentTime = function() {
    //        if (!contentPlayheadTracker.seeking) {
    //            contentPlayheadTracker.currentTime = player.currentTime();
    //        }
    //    };
    //
    //    /**
    //     * Detects when the user is seeking through a video.
    //     * This is used to prevent mid-rolls from playing while a user is seeking.
    //     *
    //     * There *is* a seeking property of the HTML5 video element, but it's not
    //     * properly implemented on all platforms (e.g. mobile safari), so we have to
    //     * check ourselves to be sure.
    //     */
    //    player.ima_flash.checkForSeeking = function() {
    //        var tempCurrentTime = player.currentTime();
    //        var diff = (tempCurrentTime - contentPlayheadTracker.previousTime) * 1000;
    //        if (Math.abs(diff) > seekCheckInterval + seekThreshold) {
    //            contentPlayheadTracker.seeking = true;
    //        } else {
    //            contentPlayheadTracker.seeking = false;
    //        }
    //        contentPlayheadTracker.previousTime = player.currentTime();
    //    };


    //    /**
    //     * Local content ended listener for contentComplete.
    //     */
    //    var localContentEndedListener = function() {
    //        if (adsLoader && !contentComplete) {
    //            adsLoader.contentComplete();
    //            contentComplete = true;
    //        }
    //        for (var index in contentEndedListeners) {
    //            contentEndedListeners[index]();
    //        }
    //        clearInterval(updateTimeIntervalHandle);
    //        clearInterval(seekCheckIntervalHandle);
    //        // player.one('play', player.ima_flash.setUpPlayerIntervals_);
    //    };

    settings = extend({}, ima_defaults, options || {});

    // Default showing countdown timer to true.
    showCountdown = true;
    if (settings['showCountdown'] == false) {
        showCountdown = false;
    }

    // player.one('play', player.ima_flash.setUpPlayerIntervals_);

    // player.on('ended', localContentEndedListener);

    var contrib_ads_defaults = {
        debug: settings.debug,
        timeout: settings.timeout,
        prerollTimeout: settings.prerollTimeout
    };

    var ads_plugin_settings =
        extend({}, contrib_ads_defaults, options['contribAdsSettings'] || {});

    player.ads(ads_plugin_settings);

    //    adsRenderingSettings = new google.ima.AdsRenderingSettings();
    //    adsRenderingSettings.restoreCustomPlaybackStateOnAdBreakComplete = true;
    //    if (settings['adsRenderingSettings']) {
    //        for (var setting in settings['adsRenderingSettings']) {
    //          adsRenderingSettings[setting] =
    //              settings['adsRenderingSettings'][setting];
    //        }
    //    }

    //    if (settings['locale']) {
    //        google.ima.settings.setLocale(settings['locale']);
    //    }


    //--------------------------------------------------------------------------------
    // Set up display elements
    //

    player.ima_flash.createAdContainer_ = function() {
        // The adContainerDiv is the DOM of the element that will house
        // the ads and ad controls.

        vjsControls = player.getChild('controlBar');

        adContainerDiv =
            vjsControls.el().parentNode.insertBefore(
                document.createElement('div'),
                vjsControls.el());
        adContainerDiv.id = player.id() + '-ima_flash-ad-container';
        adContainerDiv.style.width = player.width() + 'px';
        adContainerDiv.style.height = player.height() + 'px';
        swfDiv = adContainerDiv.appendChild(document.createElement('div'));
        swfDiv.id = player.id() + '-ima_flash-swf';
        swfDiv.style.width = player.width() + 'px';
        swfDiv.style.height = player.height() + 'px';

        adContainerDiv.addEventListener(
            'mouseover',
            player.ima_flash.showAdControls_,
            false);
        adContainerDiv.addEventListener(
            'mouseout',
            player.ima_flash.hideAdControls_,
            false);
        player.ima_flash.createControls_();
    };

    player.ima_flash.createControls_ = function() {
        controlsDiv = document.createElement('div');
        controlsDiv.id = 'ima-controls-div';
        controlsDiv.style.width = '100%';
        countdownDiv = document.createElement('div');
        countdownDiv.id = 'ima-countdown-div';
        countdownDiv.innerHTML = 'Advertisement';
        countdownDiv.style.display = showCountdown ? 'block' : 'none';
        seekBarDiv = document.createElement('div');
        seekBarDiv.id = 'ima-seek-bar-div';
        seekBarDiv.style.width = player.width() + 'px';
        progressDiv = document.createElement('div');
        progressDiv.id = 'ima-progress-div';
        playPauseDiv = document.createElement('div');
        playPauseDiv.id = 'ima-play-pause-div';
        playPauseDiv.className = 'ima-playing';
        playPauseDiv.addEventListener(
            'click',
            player.ima_flash.onAdPlayPauseClick_,
            false);
        muteDiv = document.createElement('div');
        muteDiv.id = 'ima-mute-div';
        muteDiv.className = 'ima-non-muted';
        muteDiv.addEventListener(
            'click',
            player.ima_flash.onAdMuteClick_,
            false);
        fullscreenDiv = document.createElement('div');
        fullscreenDiv.id = 'ima-fullscreen-div';
        fullscreenDiv.className = 'ima-non-fullscreen';
        fullscreenDiv.addEventListener(
            'click',
            player.ima_flash.onAdFullscreenClick_,
            false);
        adContainerDiv.appendChild(controlsDiv);
        controlsDiv.appendChild(countdownDiv);
        controlsDiv.appendChild(seekBarDiv);
        controlsDiv.appendChild(playPauseDiv);
        controlsDiv.appendChild(muteDiv);
        controlsDiv.appendChild(fullscreenDiv);
        seekBarDiv.appendChild(progressDiv);
    };

    player.ima_flash.hideAdControls_ = function() {
        playPauseDiv.style.display = 'none';
        muteDiv.style.display = 'none';
        fullscreenDiv.style.display = 'none';
        controlsDiv.style.height = '14px';
    };

    player.ima_flash.showAdControls_ = function() {
        controlsDiv.style.height = '37px';
        playPauseDiv.style.display = 'block';
        muteDiv.style.display = 'block';
        fullscreenDiv.style.display = 'block';
    };

    player.ima_flash.onAdPlayPauseClick_ = function() {
        if (player.ima_flash.adPaused()) {
            player.ima_flash.resumeAd();
        } else {
            player.ima_flash.pauseAd();
        }
    };

    player.ima_flash.onAdMuteClick_ = function() {
        player.muted(!player.muted());
    };

    player.ima_flash.onAdFullscreenClick_ = function() {
        if (player.isFullscreen()) {
            player.exitFullscreen();
        } else {
            player.requestFullscreen();
        }
    };

    player.ima_flash.setShowCountdown = function(showCountdownIn) {
        showCountdown = showCountdownIn;
        countdownDiv.style.display = showCountdown ? 'block' : 'none';
    };

    player.ima_flash.createAdContainer_();

    //
    // done with display elements
    //--------------------------------------------------------------------------------


    if (!readyCallback) {
        readyCallback = player.ima_flash.start;
    }
    player.on('readyforpreroll', readyCallback);


    player.on('fullscreenchange', function() {
        if (player.isFullscreen()) {
            // fullscreenDiv.className = 'ima-fullscreen';
            player.ima_flash.resizeAd(window.screen.width, window.screen.height, "fullscreen");
        } else {
            // fullscreenDiv.className = 'ima-non-fullscreen';
            // TODO what was state before? normal or thumbnail?
            player.ima_flash.resizeAd(player.width(), player.height(), "normal");
        }
    });
    player.on('resize', function() {
        console.log('event: player: resize');

        // TODO what is state if not fullscreen? normal or thumbnail?
        player.ima_flash.resizeAd(player.width(), player.height(), player.isFullscreen() ? "fullscreen" : "normal");
    });



    var flashvars = {
        id: player.id(),
        width: player.width(),
        height: player.height(),
        nlwidth: settings.nonLinearWidth || player.width(),
        nlheight: settings.nonLinearHeight || (player.height() / 3)
    };
    var params = {
        allowScriptAccess: "always",
        allowNetworking: "all",
        wmode: "transparent"
    };

    if (options && options.adTagUrl && typeof options.adTagUrl === "string") {
        flashvars.adTagUrl = options.adTagUrl;
    }


    player.on('volumechange', function() {
        swfElement.setAdVolume(player.volume(), player.muted());
    });


    // log all events
    player.on('durationchange', function() { console.log('event: player: durationchange', arguments); });
    player.on('ended', function() { console.log('event: player: ended', arguments); });
    player.on('error', function() { console.log('event: player: error', arguments); });
    player.on('firstplay', function() { console.log('event: player: firstplay', arguments); });
    player.on('fullscreenchange', function() { console.log('event: player: fullscreenchange', arguments); });
    player.on('loadedalldata', function() { console.log('event: player: loadedalldata', arguments); });
    player.on('loadeddata', function() { console.log('event: player: loadeddata', arguments); });
    player.on('loadedmetadata', function() { console.log('event: player: loadedmetadata', arguments); });
    player.on('loadstart', function() { console.log('event: player: loadstart', arguments); });
    player.on('pause', function() { console.log('event: player: pause', arguments); });
    player.on('play', function() { console.log('event: player: play', arguments); });
    player.on('progress', function() { console.log('event: player: progress', arguments); });
    player.on('seeked', function() { console.log('event: player: seeked', arguments); });
    player.on('seeking', function() { console.log('event: player: seeking', arguments); });
    player.on('timeupdate', function() { console.log('event: player: timeupdate', arguments); });
    player.on('volumechange', function() { console.log('event: player: volumechange', arguments); });
    player.on('waiting', function() { console.log('event: player: waiting', arguments); });
    player.on('resize', function() { console.log('event: player: resize', arguments); });
    player.on('contentupdate', function() { console.log('event: ad: contentupdate', arguments); });
    player.on('readyforpreroll', function() { console.log('event: ad: readyforpreroll', arguments); });
    player.on('contentplayback', function() { console.log('event: ad: contentplayback', arguments); });
    player.on('adsready', function() { console.log('event: ad: adsready', arguments); });
    player.on('adscanceled', function() { console.log('event: ad: adscanceled', arguments); });
    player.on('adserror', function() { console.log('event: ad: adserror', arguments); });


    // request ads whenever there's new video content
    player.on('contentupdate', function() {
        console.log('contentupdate');
        // swfobject.embedSWF("http://tout.queuecontinuum.com/videojs.ima_flash.swf", options.id, "640", "360", "10.1", null, flashvars, params);

        // fetch ad inventory asynchronously, then ...
        // player.trigger('adsready');
    });


    player.on('readyforpreroll', function() {
        console.log('readyforpreroll');

        // pauseContent event is too slow, so pausing ahead of time here
        player.pause();

        // player.ima_flash.pauseContent();
        swfElement.startAd();
    });

    player.on('ended', function() {
        swfElement.videojsEnded();
    });



    player.ima_flash.requestAds = function() {
        swfElement.requestAds();
    }

    player.ima_flash.resizeAd = function(width, height, viewMode) {
        swfElement.width = width;
        swfElement.height = height;
        adContainerDiv.style.width = width + 'px';
        adContainerDiv.style.height = height + 'px';
        swfElement.resizeAd(width, height, viewMode);
    }

    player.ima_flash.stopAd = function() {
        swfElement.stopAd();
    }

    player.ima_flash.pauseAd = function() {
        swfElement.pauseAd();
    }

    player.ima_flash.resumeAd = function() {
        swfElement.resumeAd();
    }

    player.ima_flash.adPaused = function() {
        return swfElement.adPaused();
    }


    player.ima_flash.expandAd = function() {
        swfElement.expandAd();
    }

    player.ima_flash.collapseAd = function() {
        swfElement.collapseAd();
    }

    player.ima_flash.adExpanded = function() {
        return swfElement.adExpanded();
    }


    /*
      var options = {
        id: 'video_id',
        adTagUrl: 'http://cdn.daxee.com/vpaid/vast.xml'
      };

      player.ima_flash(options);


      // Initialize the ad container when the video player is clicked, but only the
      // first time it's clicked.
      var clickedOnce = false;
      var startEvent = 'click';
      if (navigator.userAgent.match(/iPhone/i) || navigator.userAgent.match(/iPad/i) || navigator.userAgent.match(/Android/i)) {
        startEvent = 'tap';
      }
      player.on(startEvent, function() {
        if (!clickedOnce) {
          player.ima_flash.initializeAdDisplayContainer();
          player.ima_flash.requestAds();
          player.play();
          clickedOnce = true;
        }
      });
    */
    swfobject.embedSWF(settings.swfUrl, swfDiv.id, player.width(), player.height(), "10.1", null, flashvars, params, {}, function(e) {
        if (e.success) {
            console.log('SWF loaded');
            swfElement = e.ref;
        } else {
            console.error('SWF load failed');
        }
    });

});
