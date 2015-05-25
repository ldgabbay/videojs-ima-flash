// Copyright 2012 Google Inc. All Rights Reserved.
// You may study, modify, and use this example for any purpose.
// Note that this example is provided "as is", WITHOUT WARRANTY
// of any kind either expressed or implied.


// https://developers.google.com/interactive-media-ads/docs/sdks/flash/v3/apis

package {
  // import spark.components.Group;
  // import spark.components.VideoPlayer;
  // import spark.core.SpriteVisualElement;

  import com.google.ads.ima.api.AdErrorEvent;
  import com.google.ads.ima.api.AdEvent;
  import com.google.ads.ima.api.AdsLoader;
  import com.google.ads.ima.api.AdsManager;
  import com.google.ads.ima.api.AdsManagerLoadedEvent;
  import com.google.ads.ima.api.AdsRenderingSettings;
  import com.google.ads.ima.api.AdsRequest;
  import com.google.ads.ima.api.ViewModes;

  import org.osmf.events.TimeEvent;

  import mx.events.FlexEvent;

  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.display.DisplayObject;
  import flash.display.DisplayObjectContainer;
  import flash.display.StageScaleMode;
  import flash.display.StageAlign;
  import flash.events.Event;
  import flash.events.FullScreenEvent;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.display.LoaderInfo;

  /**
   * Simple Google IMA SDK video player integration.
   */
  public class VideoJsImaFlashPlugin extends Sprite {

    // The video player object.
    // private var videoPlayer:VideoPlayer;
    private var fullScreenExited:Boolean;
    private var contentPlayheadTime:Number;

    // SDK Objects
    private var adsLoader:AdsLoader = null;
    private var adsManager:AdsManager;

    private var _videojs_id:String = null;
    private var _videojs_width:Number = 0;
    private var _videojs_height:Number = 0;
    private var _videojs_nlwidth:Number = 0;
    private var _videojs_nlheight:Number = 0;
    private var _ad_tag:String = null;

    private var _in_ad_request:Boolean = false;

    private const STATE_NONE:String = "NONE";
    private const STATE_ADS_REQUESTED:String = "ADS_REQUESTED";
    private const STATE_ADS_LOADED:String = "ADS_LOADED";
    private const STATE_ADS_PLAYING:String = "ADS_PLAYING";

    private var _state:String = STATE_NONE;


    /**
     * Sets up the click-to-play player for ads and content playback.
     *
     * @param videoPlayerValue The content video player.
     */
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
      ExternalInterface.addCallback("videojsVolumeChange", jsi_videojsVolumeChange);

      ExternalInterface.addCallback("pauseAd", jsi_pauseAd);
      ExternalInterface.addCallback("resumeAd", jsi_resumeAd);
      ExternalInterface.addCallback("adPaused", jsi_adPaused);

      // arg videoPlayerValue:VideoPlayer

      /*
      var videoPlayerValue:VideoPlayer = new VideoPlayer();

      videoPlayer = videoPlayerValue;
      videoPlayer.source = CONTENT_URL;
      // Add some custom event handlers.
      videoPlayer.stage.addEventListener(FullScreenEvent.FULL_SCREEN,
                                         fullscreenChangeHandler);
      videoPlayer.addEventListener(TimeEvent.COMPLETE, contentCompleteHandler);
      videoPlayer.addEventListener(TimeEvent.CURRENT_TIME_CHANGE,
                                   contentPlayheadTimeChangeHandler);
      // Workaround flex problem with fullscreen: when fullscreen is exited,
      // flex video player component still has the old dimension values. We wait
      // for update complete event, after which correct values are available.
      videoPlayer.addEventListener(FlexEvent.UPDATE_COMPLETE,
                                   videoPlayerUpdateCompleteHandler);
      */

      adsLoader = new AdsLoader();
      adsLoader.loadSdk();
      adsLoader.addEventListener(AdsManagerLoadedEvent.ADS_MANAGER_LOADED, adsLoaderAdsManagerLoaded);
      adsLoader.addEventListener(AdErrorEvent.AD_ERROR, adsLoaderAdError);

      jso_ready();
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

      destroyAdsManager();
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
      _state = STATE_ADS_PLAYING;
      jso_trigger('adstart');
    }

    private function jsi_videojsEnded():void {
      trace('info', 'jsi_videojsEnded');

      adsLoader.contentComplete();
    }

    private function jsi_videojsVolumeChange(volume:Number, muted:Boolean):void {
      trace('info', 'jsi_videojsVolumeChange', volume, muted);
      if (adsManager) {
        adsManager.volume = muted ? 0 : volume;
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


    private function jso_trigger(eventName:String):void {
      trace('info', 'jso_trigger');

      ExternalInterface.call('videojs_trigger', _videojs_id, eventName);
    }

    private function jso_ready():void {
      trace('info', 'jso_ready');

      ExternalInterface.call('videojs_ima_flash_ready', _videojs_id);
    }

    private function jso_currentTime():Number {
      trace('info', 'jso_currentTime');

      return ExternalInterface.call('videojs_currentTime', _videojs_id);
    }


    private function jso_content_pause():void {
      trace('info', 'jso_content_pause');

      ExternalInterface.call('videojs_ima_flash_content_pause', _videojs_id);
    }

    private function jso_content_resume():void {
      trace('info', 'jso_content_resume');

      ExternalInterface.call('videojs_ima_flash_content_resume', _videojs_id);
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
        _state = STATE_NONE;
        return;
      }

      // Add required ads manager listeners.
      // ALL_ADS_COMPLETED event will fire once all the ads have played. There
      // might be more than one ad played in the case of ad pods and ad rules.
      adsManager.addEventListener(AdEvent.ALL_ADS_COMPLETED, allAdsCompletedHandler);
      // If ad is linear, it will fire content pause request event.
      adsManager.addEventListener(AdEvent.CONTENT_PAUSE_REQUESTED, adsManagerContentPauseRequested);
      // When ad finishes or if ad is non-linear, content resume event will be
      // fired. For example, if ad rules response only has post-roll, content
      // resume will be fired for pre-roll ad (which is not present) to signal
      // that content should be started or resumed.
      adsManager.addEventListener(AdEvent.CONTENT_RESUME_REQUESTED, adsManagerContentResumeRequested);
      // We want to know when an ad starts.
      adsManager.addEventListener(AdEvent.STARTED, startedHandler);
      adsManager.addEventListener(AdErrorEvent.AD_ERROR, adsManagerPlayErrorHandler);

      // If your video player supports a specific version of VPAID ads, pass
      // in the version. If your video player does not support VPAID ads yet,
      // just pass in 1.0.
      adsManager.handshakeVersion("1.0");
      // Init should be called before playing the content in order for ad rules
      // ads to function correctly.
      adsManager.init(_videojs_width,
                      _videojs_height,
                      ViewModes.NORMAL);

      // Add the adsContainer to the display list. Below is an example of how
      // to do it in Flex.
      // var flexAdContainer:SpriteVisualElement = new SpriteVisualElement();
      // flexAdContainer.addChild(adsManager.adsContainer);
      // (videoPlayer.videoDisplay.parent as Group).addElement(flexAdContainer);

      _state = STATE_ADS_LOADED;
      jso_trigger('adsready');
    }


    private function adsLoaderAdError(event:AdErrorEvent):void {
      trace("warning", "requestAds error", event.error.errorMessage);

      if (_state !== STATE_ADS_REQUESTED) {
        trace('warning', 'adsLoaderAdsManagerLoaded called while in state '+_state);
        return;
      }

      // TODO handle failure on requestAds()
      // videoPlayer.play();
      _state = STATE_NONE;
    }


    /**
     * Errors that occur during ads manager play should be treated as
     * informational signals. The SDK will send all ads completed event if there
     * are no more ads to display.
     */
    private function adsManagerPlayErrorHandler(event:AdErrorEvent):void {
      trace("warning", "Ad playback error: " + event.error.errorMessage);
    }

    /**
     * Clean up AdsManager references when no longer needed. Explicit cleanup
     * is necessary to prevent memory leaks.
     */
    private function destroyAdsManager():void {
      enableContentControls();
      if (adsManager) {
        if (adsManager.adsContainer.parent &&
            adsManager.adsContainer.parent.contains(adsManager.adsContainer)) {
          adsManager.adsContainer.parent.removeChild(adsManager.adsContainer);
        }
        adsManager.destroy();
      }
    }

    /**
     * The AdsManager raises this event when it requests the publisher to pause
     * the content.
     */
    private function adsManagerContentPauseRequested(event:AdEvent):void {
      trace('info', 'adsManagerContentPauseRequested');

      jso_content_pause();

      // The ad will cover a large portion of the content, therefore content
      // must be paused.
      // if (videoPlayer.playing) {
      //   videoPlayer.pause();
      // }
      // // Manually flip play button state.
      // videoPlayer.playPauseButton.selected =
      //       !videoPlayer.playPauseButton.selected;
      // Rewire controls to affect ads manager instead of the content video.
      enableLinearAdControls();
      // Ads usually do not allow scrubbing.
      canScrub = false;
    }

    /**
     * The AdsManager raises this event when it requests the publisher to resume
     * the content.
     */
    private function adsManagerContentResumeRequested(event:AdEvent):void {
      trace('info', 'adsManagerContentResumeRequested');

      jso_content_resume();

      // Rewire controls to affect content instead of the ads manager.
      enableContentControls();
      // videoPlayer.play();
    }

    /**
     * The AdsManager raises this event when the ad has started.
     */
    private function startedHandler(event:AdEvent):void {
      // If the ad exists and is a non-linear, start the content with the ad.
      // if (event.ad != null && !event.ad.linear) {
      //   videoPlayer.play();
      // }
    }

    /**
     * The AdsManager raises this event when all ads for the request have been
     * played.
     */
    private function allAdsCompletedHandler(event:AdEvent):void {
      // Ads manager can be destroyed after all of its ads have played.
      destroyAdsManager();
      _state = STATE_NONE;
    }

    /**
     * Switches the video player controls to control the video ad.
     */
    private function enableLinearAdControls():void {
    }

    /**
     * Switches the video player controls to control the content.
     */
    private function enableContentControls():void {
      canScrub = true;
    }

    private function set canScrub(value:Boolean):void {
      // videoPlayer.scrubBar.enabled = value;
      // videoPlayer.scrubBar.mouseEnabled = value;
    }

//    /**
//     * Update the playhead time for the AdsManager.
//     */
//    private function contentPlayheadTimeChangeHandler(event:TimeEvent):void {
//      contentPlayheadTime = event.time;
//    }

    private function fullscreenChangeHandler(event:FullScreenEvent):void {
      if (event.fullScreen) {
        adsManager.resize(_videojs_width,
                          _videojs_height,
                          ViewModes.FULLSCREEN);
      } else {
        fullScreenExited = true;
        // Ads manager resize will occur after update complete.
      }
    }

    /**
     * Workaround for a bug in the video player's full screen functionality.
     */
    private function videoPlayerUpdateCompleteHandler(event:FlexEvent):void {
      if (fullScreenExited) {
        fullScreenExited = false;
        adsManager.resize(_videojs_width,
                          _videojs_height,
                          ViewModes.NORMAL);
      }
    }

//    /**
//     * The video player raises this event when the content has finished playing.
//     */
//    private function contentCompleteHandler(event:TimeEvent):void {
//      videoPlayer.stage.removeEventListener(FullScreenEvent.FULL_SCREEN,
//                                            fullscreenChangeHandler);
//      videoPlayer.removeEventListener(FlexEvent.UPDATE_COMPLETE,
//                                      videoPlayerUpdateCompleteHandler);
//      videoPlayer.removeEventListener(TimeEvent.COMPLETE,
//                                      contentCompleteHandler);
//      // Tell the SDK when any content completes, even content without ads. The
//      // SDK uses this method for better ad selection (especially ad rules).
//      adsLoader.contentComplete();
//    }


//    private function traceDisplayList(container:DisplayObjectContainer, indentString:String = "=>"):void {
//      var child:DisplayObject;
//
//      for (var i:uint=0; i < container.numChildren; i++) {
//        child = container.getChildAt(i);
//        trace(indentString, child.parent.name + " " + indentString + " " + child.name);
//        dumpPos(child, indentString + "...")
//        if (container.getChildAt(i) is DisplayObjectContainer) {
//          traceDisplayList(DisplayObjectContainer(child), indentString + "");
//        }
//      }
//    }
//
//
//    private function dumpPos(dob:DisplayObject, indentString:String = "=>"):void {
//      trace('x = '+dob.x);
//      trace('y = '+dob.y);
//      trace('scaleX = '+dob.scaleX);
//      trace('scaleY = '+dob.scaleY);
//      trace('width = '+dob.width);
//      trace('height = '+dob.height);
//    }
  }
}