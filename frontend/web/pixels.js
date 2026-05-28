(function () {
  'use strict';

  // Keep IDs blank until the provider is named in the Privacy Policy.
  // Add future ad tags here so consent gating remains centralized.
  var tagConfig = {
    googleTagManagerId: '',
    metaPixelId: ''
  };

  if (!window.WeConnectConsent) return;

  window.WeConnectTags = window.WeConnectTags || {};
  window.WeConnectTags.event = trackEvent;

  window.WeConnectConsent.register('analytics', syncGoogleTagManager);
  window.WeConnectConsent.register('marketing', function () {
    var cleanups = [];

    syncGoogleTagManager(window.WeConnectConsent.get());

    if (tagConfig.metaPixelId) {
      cleanups.push(loadMetaPixel(tagConfig.metaPixelId));
    }

    return function () {
      cleanups.forEach(function (cleanup) {
        if (typeof cleanup === 'function') cleanup();
      });
    };
  });

  function syncGoogleTagManager(consent) {
    if (!tagConfig.googleTagManagerId) return null;

    var categories = consent && consent.categories ? consent.categories : {};
    if (!categories.analytics && !categories.marketing) return null;

    loadGoogleTagManager(tagConfig.googleTagManagerId);
    return function () {};
  }

  function trackEvent(name, parameters) {
    if (!name || typeof name !== 'string') return;

    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push(Object.assign({ event: name }, safeParameters(parameters)));
  }

  function safeParameters(parameters) {
    var result = {};
    var blockedKeys = /email|name|message|text|content|note|partner/i;

    Object.keys(parameters || {}).forEach(function (key) {
      var value = parameters[key];
      if (blockedKeys.test(key)) return;
      if (['string', 'number', 'boolean'].indexOf(typeof value) === -1) return;
      result[key] = value;
    });

    return result;
  }

  function loadScript(id, src) {
    if (document.getElementById(id)) return;

    var script = document.createElement('script');
    script.id = id;
    script.async = true;
    script.src = src;
    document.head.appendChild(script);
  }

  function loadGoogleTagManager(id) {
    window.dataLayer = window.dataLayer || [];
    window.gtag = window.gtag || function () {
      window.dataLayer.push(arguments);
    };

    if (!document.getElementById('wc-google-tag-manager')) {
      window.dataLayer.push({ 'gtm.start': new Date().getTime(), event: 'gtm.js' });
    }
    loadScript('wc-google-tag-manager', 'https://www.googletagmanager.com/gtm.js?id=' + encodeURIComponent(id));
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
