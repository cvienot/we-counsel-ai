(function () {
  'use strict';

  // Keep IDs blank until the Privacy Policy names the provider.
  // Add future ad tags here so consent gating remains centralized.
  var pixelConfig = {
    googleAdsId: '',
    metaPixelId: ''
  };

  if (!window.WeConnectConsent) return;

  window.WeConnectConsent.register('marketing', function () {
    var cleanups = [];

    if (pixelConfig.googleAdsId) {
      cleanups.push(loadGoogleTag(pixelConfig.googleAdsId));
    }

    if (pixelConfig.metaPixelId) {
      cleanups.push(loadMetaPixel(pixelConfig.metaPixelId));
    }

    return function () {
      cleanups.forEach(function (cleanup) {
        if (typeof cleanup === 'function') cleanup();
      });
    };
  });

  function loadScript(id, src) {
    if (document.getElementById(id)) return;

    var script = document.createElement('script');
    script.id = id;
    script.async = true;
    script.src = src;
    document.head.appendChild(script);
  }

  function loadGoogleTag(id) {
    window.dataLayer = window.dataLayer || [];
    window.gtag = window.gtag || function () {
      window.dataLayer.push(arguments);
    };

    loadScript('wc-google-tag', 'https://www.googletagmanager.com/gtag/js?id=' + encodeURIComponent(id));
    window.gtag('js', new Date());
    window.gtag('config', id);

    return function () {
      window['ga-disable-' + id] = true;
    };
  }

  function loadMetaPixel(id) {
    if (!window.fbq) {
      var fbq = function () {
        fbq.callMethod ? fbq.callMethod.apply(fbq, arguments) : fbq.queue.push(arguments);
      };
      window.fbq = fbq;
      window._fbq = fbq;
      fbq.push = fbq;
      fbq.loaded = true;
      fbq.version = '2.0';
      fbq.queue = [];
    }

    loadScript('wc-meta-pixel', 'https://connect.facebook.net/en_US/fbevents.js');
    window.fbq('consent', 'grant');
    window.fbq('init', id);
    window.fbq('track', 'PageView');

    return function () {
      if (window.fbq) window.fbq('consent', 'revoke');
    };
  }
})();
