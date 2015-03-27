// Copyright 2012 Google Inc. All Rights Reserved.
// You may study, modify, and use this example for any purpose.
// Note that this example is provided "as is", WITHOUT WARRANTY
// of any kind either expressed or implied.

package {
  import spark.components.Group;
  import spark.components.VideoPlayer;
  import spark.core.SpriteVisualElement;

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

  import flash.events.Event;
  import flash.events.FullScreenEvent;
  import flash.events.MouseEvent;

  /**
   * Simple Google IMA SDK video player integration.
   */
  public class SdkIntegrationExample {

    private static const CONTENT_URL:String =
        "http://rmcdn.2mdn.net/Demo/vast_inspector/android.flv";

    private static const LINEAR_AD_TAG:String = "http://cdn.daxee.com/vpaid/vast.xml";
        // "http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&" +
        // "iu=%2F6062%2Fiab_vast_samples&ciu_szs=300x250%2C728x90&impl=s&" +
        // "gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&" +
        // "url=[referrer_url]&correlator=[timestamp]&" +
        // "cust_params=iab_vast_samples%3Dlinear";

    private static const NONLINEAR_AD_TAG:String =
        "http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&" +
        "iu=%2F6062%2Fiab_vast_samples&ciu_szs=300x250%2C728x90&" +
        "impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&" +
        "url=[referrer_url]&correlator=[timestamp]&" +
        "cust_params=iab_vast_samples%3Dimageoverlay";

    // The video player object.
    private var videoPlayer:VideoPlayer;
    private var fullScreenExited:Boolean;
    private var contentPlayheadTime:Number;

    // SDK Objects
    private var adsLoader:AdsLoader;
    private var adsManager:AdsManager;

    /**
     * Sets up the click-to-play player for ads and content playback.
     *
     * @param videoPlayerValue The content video player.
     */
    public function SdkIntegrationExample(videoPlayerValue:VideoPlayer):void {
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
      initAdsLoader();
    }

    /**
     * Handler for when a user clicks on the "Linear Ad" radio button.
     */
    public function linearAdSelectionHandler(event:Event):void {
      destroyAdsManager();
      requestAds(LINEAR_AD_TAG);
    }

    /**
     * Handler for when a user clicks on the "Non-linear Ad" radio button.
     */
    public function nonlinearAdSelectionHandler(event:Event):void {
      destroyAdsManager();
      requestAds(NONLINEAR_AD_TAG);
    }


    /**
     * Initialize the AdsLoader and load the SDK
     */
    private function initAdsLoader():void {
      if (adsLoader == null) {
        // On the first request, create the AdsLoader.
        adsLoader = new AdsLoader();
        // The SDK uses a 2 stage loading process. Without this call, the second
        // loading stage will take place when ads are requested. Including this
        // call will decrease latency in starting ad playback.
        adsLoader.loadSdk();
      }
    }

    /**
     * Request ads using the specified ad tag.
     *
     * @param adTag A URL that will return a valid VAST response.
     */
    private function requestAds(adTag:String):void {
      // The AdsRequest encapsulates all the properties required to request ads.
      var adsRequest:AdsRequest = new AdsRequest();
      adsRequest.adTagUrl = adTag;
      adsRequest.linearAdSlotWidth = videoPlayer.width;
      adsRequest.linearAdSlotHeight = videoPlayer.height;
      adsRequest.nonLinearAdSlotWidth = videoPlayer.width;
      adsRequest.nonLinearAdSlotHeight = videoPlayer.height;

      // Instruct the AdsLoader to request ads using the AdsRequest object.
      adsLoader.requestAds(adsRequest);
    }

    /**
     * Invoked when the AdsLoader successfully fetched ads.
     */
    private function adsManagerLoadedHandler(event:AdsManagerLoadedEvent):void {
      // Publishers can modify the default preferences through this object.
      var adsRenderingSettings:AdsRenderingSettings =
          new AdsRenderingSettings();

      // In order to support ad rules ads, ads manager requires an object that
      // provides current playhead position for the content.
      var contentPlayhead:Object = {};
      contentPlayhead.time = function():Number {
        return contentPlayheadTime * 1000; // convert to milliseconds.
      };

      // Get a reference to the AdsManager object through the event object.
      adsManager = event.getAdsManager(contentPlayhead, adsRenderingSettings);
      if (adsManager) {
        // Add required ads manager listeners.
        // ALL_ADS_COMPLETED event will fire once all the ads have played. There
        // might be more than one ad played in the case of ad pods and ad rules.
        adsManager.addEventListener(AdEvent.ALL_ADS_COMPLETED,
                                    allAdsCompletedHandler);
        // If ad is linear, it will fire content pause request event.
        adsManager.addEventListener(AdEvent.CONTENT_PAUSE_REQUESTED,
                                    contentPauseRequestedHandler);
        // When ad finishes or if ad is non-linear, content resume event will be
        // fired. For example, if ad rules response only has post-roll, content
        // resume will be fired for pre-roll ad (which is not present) to signal
        // that content should be started or resumed.
        adsManager.addEventListener(AdEvent.CONTENT_RESUME_REQUESTED,
                                    contentResumeRequestedHandler);
        // We want to know when an ad starts.
        adsManager.addEventListener(AdEvent.STARTED, startedHandler);
        adsManager.addEventListener(AdErrorEvent.AD_ERROR,
                                    adsManagerPlayErrorHandler);

        // If your video player supports a specific version of VPAID ads, pass
        // in the version. If your video player does not support VPAID ads yet,
        // just pass in 1.0.
        adsManager.handshakeVersion("1.0");
        // Init should be called before playing the content in order for ad rules
        // ads to function correctly.
        adsManager.init(videoPlayer.videoDisplay.width,
                        videoPlayer.videoDisplay.height,
                        ViewModes.NORMAL);

        // Add the adsContainer to the display list. Below is an example of how
        // to do it in Flex.
        var flexAdContainer:SpriteVisualElement = new SpriteVisualElement();
        flexAdContainer.addChild(adsManager.adsContainer);
        (videoPlayer.videoDisplay.parent as Group).addElement(flexAdContainer);

        // Start the ad playback.
        adsManager.start();
      }
    }

    /**
     * If an error occurs during the ads load, the content can be resumed or
     * another ads request can be made. In this example, the content is resumed
     * if there's an error loading ads.
     */
    private function adsLoadErrorHandler(event:AdErrorEvent):void {
      trace("warning", "Ads load error: " + event.error.errorMessage);
      videoPlayer.play();
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
    private function contentPauseRequestedHandler(event:AdEvent):void {
      // The ad will cover a large portion of the content, therefore content
      // must be paused.
      if (videoPlayer.playing) {
        videoPlayer.pause();
      }
      // Manually flip play button state.
      videoPlayer.playPauseButton.selected =
            !videoPlayer.playPauseButton.selected;
      // Rewire controls to affect ads manager instead of the content video.
      enableLinearAdControls();
      // Ads usually do not allow scrubbing.
      canScrub = false;
    }

    /**
     * The AdsManager raises this event when it requests the publisher to resume
     * the content.
     */
    private function contentResumeRequestedHandler(event:AdEvent):void {
      // Rewire controls to affect content instead of the ads manager.
      enableContentControls();
      videoPlayer.play();
    }

    /**
     * The AdsManager raises this event when the ad has started.
     */
    private function startedHandler(event:AdEvent):void {
      // If the ad exists and is a non-linear, start the content with the ad.
      if (event.ad != null && !event.ad.linear) {
        videoPlayer.play();
      }
    }

    /**
     * The AdsManager raises this event when all ads for the request have been
     * played.
     */
    private function allAdsCompletedHandler(event:AdEvent):void {
      // Ads manager can be destroyed after all of its ads have played.
      destroyAdsManager();
    }

    /**
     * The video player raises this event when the user clicks the play/pause
     * button.
     */
    private function playPauseButtonHandler(event:MouseEvent):void {
      // Prevent video player from receiving the event, because it would affect
      // content.
      event.stopImmediatePropagation();
      var paused:Boolean = !videoPlayer.playPauseButton.selected;
      if (paused) {
        adsManager.pause();
      } else {
        adsManager.resume();
      }
    }

    /**
     * Switches the video player controls to control the video ad.
     */
    private function enableLinearAdControls():void {
      // Subscribe to the the player control click events with maximum
      // priority, so that we can handle the click before it is handled by the
      // VideoPlayer instance.
      videoPlayer.playPauseButton.addEventListener(MouseEvent.CLICK,
                                                   playPauseButtonHandler,
                                                   false, // use capture.
                                                   int.MAX_VALUE);
      videoPlayer.volumeBar.addEventListener(Event.CHANGE,
                                             volumeChangeHandler,
                                             false, // use capture.
                                             int.MAX_VALUE);
      videoPlayer.volumeBar.addEventListener(FlexEvent.MUTED_CHANGE,
                                             volumeMutedHandler,
                                             false, // use capture.
                                             int.MAX_VALUE);
    }

    /**
     * Switches the video player controls to control the content.
     */
    private function enableContentControls():void {
      videoPlayer.playPauseButton.removeEventListener(MouseEvent.CLICK,
                                                      playPauseButtonHandler);
      videoPlayer.volumeBar.removeEventListener(Event.CHANGE,
                                                volumeChangeHandler);
      videoPlayer.volumeBar.removeEventListener(FlexEvent.MUTED_CHANGE,
                                                volumeMutedHandler);
      canScrub = true;
    }

    private function volumeMutedHandler(event:FlexEvent):void {
      // Prevent video player from receiving the event, because it would affect
      // content.
      event.stopImmediatePropagation();
      adsManager.volume = 0;
    }

    private function volumeChangeHandler(event:Event):void {
      // Prevent video player from receiving the event, because it would affect
      // content.
      event.stopImmediatePropagation();
      adsManager.volume = videoPlayer.volumeBar.value;
    }

    private function set canScrub(value:Boolean):void {
      videoPlayer.scrubBar.enabled = value;
      videoPlayer.scrubBar.mouseEnabled = value;
    }

    /**
     * Update the playhead time for the AdsManager.
     */
    private function contentPlayheadTimeChangeHandler(event:TimeEvent):void {
      contentPlayheadTime = event.time;
    }

    private function fullscreenChangeHandler(event:FullScreenEvent):void {
      if (event.fullScreen) {
        adsManager.resize(videoPlayer.videoDisplay.width,
                          videoPlayer.videoDisplay.height,
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
        adsManager.resize(videoPlayer.videoDisplay.width,
                          videoPlayer.videoDisplay.height,
                          ViewModes.NORMAL);
      }
    }

    /**
     * The video player raises this event when the content has finished playing.
     */
    private function contentCompleteHandler(event:TimeEvent):void {
      videoPlayer.stage.removeEventListener(FullScreenEvent.FULL_SCREEN,
                                            fullscreenChangeHandler);
      videoPlayer.removeEventListener(FlexEvent.UPDATE_COMPLETE,
                                      videoPlayerUpdateCompleteHandler);
      videoPlayer.removeEventListener(TimeEvent.COMPLETE,
                                      contentCompleteHandler);
      // Tell the SDK when any content completes, even content without ads. The
      // SDK uses this method for better ad selection (especially ad rules).
      adsLoader.contentComplete();
    }
  }
}
