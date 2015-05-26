// Copyright 2012 Google Inc. All Rights Reserved.
// You may study, modify, and use this example for any purpose.
// Note that this example is provided "as is", WITHOUT WARRANTY
// of any kind either expressed or implied.


// https://developers.google.com/interactive-media-ads/docs/sdks/flash/v3/apis

package {
  import com.google.ads.ima.api.AdErrorEvent;
  import com.google.ads.ima.api.AdEvent;
  import com.google.ads.ima.api.AdsLoader;
  import com.google.ads.ima.api.AdsManager;
  import com.google.ads.ima.api.AdsManagerLoadedEvent;
  import com.google.ads.ima.api.AdsRenderingSettings;
  import com.google.ads.ima.api.AdsRequest;
  import com.google.ads.ima.api.ViewModes;

  import flash.display.LoaderInfo;
  import flash.display.Sprite;
  import flash.display.StageAlign;
  import flash.display.StageScaleMode;
  import flash.external.ExternalInterface;

  public class VideoJsImaFlashPlugin extends Sprite {

    // SDK Objects
    private var adsLoader:AdsLoader = null;
    private var adsManager:AdsManager;

    private var _videojs_id:String = null;
    private var _videojs_width:Number = 0;
    private var _videojs_height:Number = 0;
    private var _videojs_nlwidth:Number = 0;
    private var _videojs_nlheight:Number = 0;
    private var _ad_tag:String = null;

    private const STATE_NONE:String = "NONE";
    private const STATE_ADS_REQUESTED:String = "ADS_REQUESTED";
    private const STATE_ADS_LOADED:String = "ADS_LOADED";
    private const STATE_ADS_PLAYING:String = "ADS_PLAYING";
    private const STATE_ADS_COMPLETE:String = "ADS_COMPLETE";
    private const STATE_ERROR:String = "ERROR";

    private var _state:String = STATE_NONE;


    public function VideoJsImaFlashPlugin():void {
      var flashvars:Object = LoaderInfo(this.root.loaderInfo).parameters;

      trace('info', 'flashvars:');
      for(var key:String in flashvars) {
        var value:Object = flashvars[key];
        trace('info', '  ' + key + '=' + value);
      }

      _videojs_id = flashvars.id;
      _videojs_width = flashvars.width;
      _videojs_height = flashvars.height;
      _videojs_nlwidth = flashvars.nlwidth;
      _videojs_nlheight = flashvars.nlheight;
      _ad_tag = flashvars.tag;

      this.stage.scaleMode = StageScaleMode.NO_SCALE;
      this.stage.align = StageAlign.TOP_LEFT;

      // require ExternalInterface for proper operation
      if (!ExternalInterface.available) {
        // TODO handle failure from javascript
        throw new Error('ExternalInterface is required but not available.');
      }

      ExternalInterface.addCallback("setTag", jsi_setTag);
      ExternalInterface.addCallback("requestAds", jsi_requestAds);
      ExternalInterface.addCallback("startAd", jsi_startAd);
      ExternalInterface.addCallback("videojsEnded", jsi_videojsEnded);
      ExternalInterface.addCallback("setAdVolume", jsi_setAdVolume);

      // methods similar to VPAID 1.0
      ExternalInterface.addCallback("resizeAd", jsi_resizeAd);
      ExternalInterface.addCallback("stopAd", jsi_stopAd);
      ExternalInterface.addCallback("pauseAd", jsi_pauseAd);
      ExternalInterface.addCallback("resumeAd", jsi_resumeAd);
      ExternalInterface.addCallback("adPaused", jsi_adPaused);
      ExternalInterface.addCallback("expandAd", jsi_expandAd);
      ExternalInterface.addCallback("collapseAd", jsi_collapseAd);
      ExternalInterface.addCallback("adExpanded", jsi_adExpanded);

      adsLoader = new AdsLoader();
      adsLoader.settings.playerType = 'videojs-ima-flash';
      adsLoader.settings.playerVersion = '0.1.0';
      adsLoader.loadSdk();
      adsLoader.addEventListener(AdsManagerLoadedEvent.ADS_MANAGER_LOADED, adsLoaderAdsManagerLoaded);
      adsLoader.addEventListener(AdErrorEvent.AD_ERROR, adsLoaderAdError);

      jso_swfReady();
    }


    private function jsi_setTag(tag:String):void {
      trace('info', 'jsi_setTag', tag);

      if (_state !== STATE_NONE) {
        trace('warning', 'jsi_setTag called while in state '+_state);
        return;
      }

      _ad_tag = tag;
    }

    private function jsi_requestAds():void {
      trace('info', 'jsi_requestAds');

      if (_state !== STATE_NONE) {
        trace('warning', 'jsi_requestAds called while in state '+_state);
        return;
      }

      requestAds();
    }

    private function jsi_startAd():void {
      trace('info', 'jsi_startAd');

      if (_state !== STATE_ADS_LOADED) {
        trace('warning', 'jsi_startAd called while in state '+_state);
        return;
      }

      this.addChild(adsManager.adsContainer);
      adsManager.start();
      _adsManager_paused = false;
      _adsManager_expanded = false;
      _state = STATE_ADS_PLAYING;
      jso_trigger('adstart');
    }

    private function jsi_videojsEnded():void {
      trace('info', 'jsi_videojsEnded');

      adsLoader.contentComplete();
      _state = STATE_ADS_COMPLETE;
    }

    private function jsi_setAdVolume(volume:Number, muted:Boolean):void {
      trace('info', 'jsi_setAdVolume', volume, muted);
      if (adsManager) {
        adsManager.volume = muted ? 0 : volume;
      }
    }


    // methods similar to VPAID 1.0

    // TODO initAd

    private function jsi_resizeAd(width:Number, height:Number, viewMode:String):void {
      trace('info', 'jsi_resizeAd');

      _videojs_width = width;
      _videojs_height = height;

      if ((viewMode !== ViewModes.NORMAL) && (viewMode !== ViewModes.FULLSCREEN) && (viewMode !== ViewModes.THUMBNAIL)) {
        // TODO
        trace('error', 'invalid viewMode', viewMode);
        return;
      }

      if ((_state === STATE_ADS_LOADED) || (_state === STATE_ADS_PLAYING)) {
        adsManager.resize(_videojs_width, _videojs_height, viewMode);
      }
    }

    // TODO startAd

    private function jsi_stopAd():void {
      trace('info', 'jsi_stopAd');

      if (adsManager) {
        adsManager.stop();
        // TODO handle state
      }
    }

    private var _adsManager_paused:Boolean = false;

    private function jsi_pauseAd():void {
      trace('info', 'jsi_pauseAd');

      if (adsManager) {
        adsManager.pause();
        _adsManager_paused = true;
      }
    }

    private function jsi_resumeAd():void {
      trace('info', 'jsi_resumeAd');

      if (adsManager) {
        adsManager.resume();
        _adsManager_paused = false;
      }
    }

    private function jsi_adPaused():Boolean {
      trace('info', 'jsi_adPaused');

      return _adsManager_paused;
    }


    private var _adsManager_expanded:Boolean = false;

    private function jsi_expandAd():void {
      trace('info', 'jsi_expandAd');

      if (adsManager) {
        adsManager.expand();
        _adsManager_expanded = true;
      }
    }

    private function jsi_collapseAd():void {
      trace('info', 'jsi_collapseAd');

      if (adsManager) {
        adsManager.collapse();
        _adsManager_expanded = false;
      }
    }

    private function jsi_adExpanded():Boolean {
      trace('info', 'jsi_adExpanded');

      return _adsManager_expanded;
    }


    private function jso_error(errorMessage:String):void {
      trace('info', 'jso_error', errorMessage);

      ExternalInterface.call('videojs_error', _videojs_id, errorMessage);
    }

    private function jso_trigger(eventName:String):void {
      trace('info', 'jso_trigger');

      ExternalInterface.call('videojs_trigger', _videojs_id, eventName);
    }

    private function jso_swfReady():void {
      trace('info', 'jso_swfReady');

      ExternalInterface.call('videojs_ima_flash_swfReady', _videojs_id);
    }

    private function jso_currentTime():Number {
      trace('info', 'jso_currentTime');

      return ExternalInterface.call('videojs_currentTime', _videojs_id);
    }


    private function jso_pauseContent():void {
      trace('info', 'jso_pauseContent');

      ExternalInterface.call('videojs_ima_flash_pauseContent', _videojs_id);
    }

    private function jso_resumeContent():void {
      trace('info', 'jso_resumeContent');

      ExternalInterface.call('videojs_ima_flash_resumeContent', _videojs_id);
    }


    private function requestAds():void {
      trace('info', 'requestAds', _ad_tag);

      if (_state !== STATE_NONE) {
        trace('warning', 'requestAds called while already in progress.');
        return;
      }

      var adsRequest:AdsRequest = new AdsRequest();

      adsRequest.adTagUrl = _ad_tag;
      adsRequest.linearAdSlotWidth = _videojs_width;
      adsRequest.linearAdSlotHeight = _videojs_height;
      adsRequest.nonLinearAdSlotWidth = _videojs_nlwidth;
      adsRequest.nonLinearAdSlotHeight = _videojs_nlheight;

      adsLoader.requestAds(adsRequest);
      _state = STATE_ADS_REQUESTED;
    }


    /**
     * Invoked when the AdsLoader successfully fetched ads.
     */
    private function adsLoaderAdsManagerLoaded(adsManagerLoadedEvent:AdsManagerLoadedEvent):void {
      if (_state !== STATE_ADS_REQUESTED) {
        trace('warning', 'adsLoaderAdsManagerLoaded called while in state '+_state);
        return;
      }

      var contentPlayback:Object = {
        time: function():Number {
          return jso_currentTime() * 1000; // convert to milliseconds
        }
      };

      var adsRenderingSettings:AdsRenderingSettings = new AdsRenderingSettings();

      adsManager = adsManagerLoadedEvent.getAdsManager(contentPlayback, adsRenderingSettings);

      if (!adsManager) {
        trace('warning', 'no adsManager');
        _state = STATE_ERROR;
        return;
      }

      // Add required ads manager listeners.
      adsManager.addEventListener(AdEvent.CONTENT_PAUSE_REQUESTED, adsManagerContentPauseRequested);
      adsManager.addEventListener(AdEvent.CONTENT_RESUME_REQUESTED, adsManagerContentResumeRequested);
      adsManager.addEventListener(AdEvent.ALL_ADS_COMPLETED, adsManagerAllAdsCompleted);
      adsManager.addEventListener(AdErrorEvent.AD_ERROR, adsManagerAdError);

      // If your video player supports a specific version of VPAID ads, pass
      // in the version. If your video player does not support VPAID ads yet,
      // just pass in 1.0.
      adsManager.handshakeVersion("1.0");
      // Init should be called before playing the content in order for ad rules
      // ads to function correctly.
      adsManager.init(_videojs_width,
                      _videojs_height,
                      ViewModes.NORMAL);

      _state = STATE_ADS_LOADED;
      jso_trigger('adsready');
    }


    private function adsLoaderAdError(event:AdErrorEvent):void {
      trace("warning", "requestAds error", event.error.errorMessage);

      if (_state !== STATE_ADS_REQUESTED) {
        trace('warning', 'adsLoaderAdError called while in state '+_state);
        return;
      }

      // TODO handle failure on requestAds()
      // videoPlayer.play();
      jso_error('adsLoaderAdError: ' + event.error.errorMessage);
      _state = STATE_ERROR;
    }


    /**
     * Errors that occur during ads manager play should be treated as
     * informational signals. The SDK will send all ads completed event if there
     * are no more ads to display.
     */
    private function adsManagerAdError(event:AdErrorEvent):void {
      trace("warning", "Ad playback error: " + event.error.errorMessage);

      jso_error('adsManagerAdError: ' + event.error.errorMessage);
      _state = STATE_ERROR;
    }

    /**
     * Clean up AdsManager references when no longer needed. Explicit cleanup
     * is necessary to prevent memory leaks.
     */
    private function destroyAdsManager():void {
      if (adsManager) {
        if (adsManager.adsContainer.parent &&
            adsManager.adsContainer.parent.contains(adsManager.adsContainer)) {
          adsManager.adsContainer.parent.removeChild(adsManager.adsContainer);
        }
        adsManager.destroy();
        adsManager = null;
      }
    }

    /**
     * The AdsManager raises this event when it requests the publisher to pause
     * the content.
     */
    private function adsManagerContentPauseRequested(event:AdEvent):void {
      trace('info', 'adsManagerContentPauseRequested');

      jso_pauseContent();
    }

    /**
     * The AdsManager raises this event when it requests the publisher to resume
     * the content.
     */
    private function adsManagerContentResumeRequested(event:AdEvent):void {
      trace('info', 'adsManagerContentResumeRequested');

      jso_resumeContent();
    }

    /**
     * The AdsManager raises this event when all ads for the request have been
     * played.
     */
    private function adsManagerAllAdsCompleted(event:AdEvent):void {
      trace('info', 'adsManagerAllAdsCompleted');

      // Ads manager can be destroyed after all of its ads have played.
      destroyAdsManager();
      _state = STATE_NONE;
    }
  }
}
