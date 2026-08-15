(function () {
  'use strict';

  var STORAGE_KEY = 'we-connect-consent-v1';
  var VERSION = 1;
  var OPTIONAL_CATEGORIES = ['analytics', 'marketing'];

  var TEXT = {
    en: {
      manage: 'Privacy settings',
      title: 'Privacy choices',
      intro: 'We use necessary storage to run the site. With your consent, we can also use analytics and advertising pixels to measure campaigns and improve ads.',
      preferencesTitle: 'Manage privacy choices',
      preferencesIntro: 'Optional analytics and advertising pixels stay off unless you enable them. You can change your choice at any time.',
      necessaryTitle: 'Necessary',
      necessaryText: 'Required for language preferences, consent choices, security, authentication, and core site functions.',
      analyticsTitle: 'Analytics',
      analyticsText: 'Helps us understand visits, page performance, and campaign results without loading advertising pixels.',
      marketingTitle: 'Advertising and retargeting',
      marketingText: 'Allows advertising pixels and campaign tags that may be used to measure ads or build retargeting audiences.',
      alwaysOn: 'Always on',
      acceptAll: 'Accept all',
      rejectAll: 'Reject all',
      customize: 'Customize',
      save: 'Save choices',
      privacy: 'Privacy Policy',
      close: 'Close'
    },
    fr: {
      manage: 'Confidentialité',
      title: 'Choix de confidentialité',
      intro: 'Nous utilisons un stockage nécessaire au fonctionnement du site. Avec votre accord, nous pouvons aussi utiliser des mesures d\'audience et des pixels publicitaires pour mesurer les campagnes et améliorer les publicités.',
      preferencesTitle: 'Gérer les choix de confidentialité',
      preferencesIntro: 'Les mesures d\'audience et pixels publicitaires optionnels restent désactivés sauf si vous les activez. Vous pouvez modifier votre choix à tout moment.',
      necessaryTitle: 'Nécessaire',
      necessaryText: 'Requis pour les préférences de langue, les choix de consentement, la sécurité, l\'authentification et les fonctions essentielles du site.',
      analyticsTitle: 'Mesure d\'audience',
      analyticsText: 'Nous aide à comprendre les visites, la performance des pages et les résultats des campagnes sans charger de pixels publicitaires.',
      marketingTitle: 'Publicité et retargeting',
      marketingText: 'Autorise les pixels publicitaires et balises de campagne pouvant servir à mesurer les publicités ou créer des audiences de retargeting.',
      alwaysOn: 'Toujours actif',
      acceptAll: 'Tout accepter',
      rejectAll: 'Tout refuser',
      customize: 'Personnaliser',
      save: 'Enregistrer',
      privacy: 'Politique de confidentialité',
      close: 'Fermer'
    },
    es: {
      manage: 'Privacidad',
      title: 'Opciones de privacidad',
      intro: 'Usamos almacenamiento necesario para que el sitio funcione. Con su consentimiento, también podemos usar analítica y píxeles publicitarios para medir campañas y mejorar anuncios.',
      preferencesTitle: 'Gestionar opciones de privacidad',
      preferencesIntro: 'La analítica y los píxeles publicitarios opcionales permanecen desactivados salvo que los active. Puede cambiar su elección en cualquier momento.',
      necessaryTitle: 'Necesario',
      necessaryText: 'Requerido para preferencias de idioma, opciones de consentimiento, seguridad, autenticación y funciones esenciales del sitio.',
      analyticsTitle: 'Analítica',
      analyticsText: 'Nos ayuda a entender visitas, rendimiento de páginas y resultados de campañas sin cargar píxeles publicitarios.',
      marketingTitle: 'Publicidad y retargeting',
      marketingText: 'Permite píxeles publicitarios y etiquetas de campaña que pueden usarse para medir anuncios o crear audiencias de retargeting.',
      alwaysOn: 'Siempre activo',
      acceptAll: 'Aceptar todo',
      rejectAll: 'Rechazar todo',
      customize: 'Personalizar',
      save: 'Guardar',
      privacy: 'Política de privacidad',
      close: 'Cerrar'
    }
  };

  var language = detectLanguage();
  var state = readState();
  var listeners = [];
  var registrations = [];

  function detectLanguage() {
    var firstSegment = window.location.pathname.split('/').filter(Boolean)[0];
    var params = new URLSearchParams(window.location.search);
    var requested = params.get('lang');
    var storedLanguage = safeStorageGet('we-connect-lang');
    var browserLanguage = (navigator.language || navigator.userLanguage || 'en').slice(0, 2).toLowerCase();
    var candidate = firstSegment || requested || storedLanguage || document.documentElement.lang || browserLanguage;
    return TEXT[candidate] ? candidate : 'en';
  }

  function copyCategories(categories) {
    return {
      necessary: true,
      analytics: Boolean(categories && categories.analytics),
      marketing: Boolean(categories && categories.marketing)
    };
  }

  function defaultState() {
    return {
      version: VERSION,
      updatedAt: null,
      categories: copyCategories({})
    };
  }

  function hasSavedChoice() {
    return Boolean(state && state.version === VERSION && state.updatedAt);
  }

  function readState() {
    try {
      var raw = window.localStorage.getItem(STORAGE_KEY);
      if (!raw) return defaultState();
      var parsed = JSON.parse(raw);
      if (!parsed || parsed.version !== VERSION || !parsed.categories) return defaultState();
      return {
        version: VERSION,
        updatedAt: parsed.updatedAt || null,
        categories: copyCategories(parsed.categories)
      };
    } catch (error) {
      return defaultState();
    }
  }

  function safeStorageGet(key) {
    try {
      return window.localStorage.getItem(key);
    } catch (error) {
      return null;
    }
  }

  function saveState(categories) {
    state = {
      version: VERSION,
      updatedAt: new Date().toISOString(),
      categories: copyCategories(categories)
    };

    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (error) {
      // Consent still applies for this page view even if storage is unavailable.
    }

    pushGoogleConsent('update');
    evaluateRegistrations();
    notifyListeners();
    removeBanner();
    removeModal();
    renderManageButton();
  }

  function translation(key) {
    return (TEXT[language] && TEXT[language][key]) || TEXT.en[key] || key;
  }

  function getPrivacyUrl() {
    return window.location.hostname === 'app.entrelace.app'
      ? '/privacy'
      : 'https://app.entrelace.app/privacy';
  }

  function getConsent() {
    return {
      version: VERSION,
      updatedAt: state.updatedAt,
      categories: copyCategories(state.categories)
    };
  }

  function hasConsent(category) {
    return category === 'necessary' || Boolean(state.categories && state.categories[category]);
  }

  function notifyListeners() {
    var detail = getConsent();
    listeners.forEach(function (listener) {
      listener(detail);
    });
    window.dispatchEvent(new CustomEvent('weconnect:consentchange', { detail: detail }));
  }

  function register(category, loader) {
    if (OPTIONAL_CATEGORIES.indexOf(category) === -1 || typeof loader !== 'function') {
      throw new Error('Unknown consent category: ' + category);
    }

    registrations.push({
      category: category,
      loader: loader,
      loaded: false,
      cleanup: null
    });

    evaluateRegistrations();
  }

  function evaluateRegistrations() {
    registrations.forEach(function (entry) {
      if (hasConsent(entry.category)) {
        if (!entry.loaded) {
          entry.loaded = true;
          entry.cleanup = entry.loader(getConsent()) || null;
        }
        return;
      }

      if (entry.loaded && typeof entry.cleanup === 'function') {
        entry.cleanup(getConsent());
      }
      entry.loaded = false;
      entry.cleanup = null;
    });
  }

  function pushGoogleConsent(command) {
    window.dataLayer = window.dataLayer || [];
    window.gtag = window.gtag || function () {
      window.dataLayer.push(arguments);
    };

    var analyticsGranted = hasConsent('analytics');
    var marketingGranted = hasConsent('marketing');

    window.gtag('consent', command, {
      ad_storage: marketingGranted ? 'granted' : 'denied',
      ad_user_data: marketingGranted ? 'granted' : 'denied',
      ad_personalization: marketingGranted ? 'granted' : 'denied',
      analytics_storage: analyticsGranted ? 'granted' : 'denied',
      functionality_storage: 'granted',
      security_storage: 'granted',
      wait_for_update: 500
    });
  }

  function injectStyles() {
    if (document.getElementById('wc-consent-styles')) return;

    var style = document.createElement('style');
    style.id = 'wc-consent-styles';
    style.textContent = [
      '.wc-consent-banner{position:fixed;left:16px;right:16px;bottom:16px;z-index:2147483000;display:flex;justify-content:center;font-family:Inter,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#1a1d3b}',
      '.wc-consent-panel{width:min(960px,100%);background:#fff;border:1px solid #e4e7f5;border-radius:8px;box-shadow:0 16px 48px rgba(13,15,28,.18);padding:20px;display:grid;grid-template-columns:1fr auto;gap:18px;align-items:center}',
      '.wc-consent-copy h2,.wc-consent-modal h2{font-size:1.1rem;line-height:1.3;margin:0 0 8px;font-weight:800;color:#1a1d3b}',
      '.wc-consent-copy p,.wc-consent-modal p{font-size:.92rem;line-height:1.55;margin:0;color:#555b76}',
      '.wc-consent-actions{display:flex;gap:10px;flex-wrap:wrap;justify-content:flex-end}',
      '.wc-consent-btn{border:1px solid #d6d9e8;background:#fff;color:#1a1d3b;border-radius:8px;padding:10px 14px;font:600 .9rem Inter,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;cursor:pointer;transition:background .15s,border-color .15s,transform .15s}',
      '.wc-consent-btn:hover{border-color:#6b73ff;background:#f6f7ff}',
      '.wc-consent-btn-primary{background:#1a1d3b;color:#fff;border-color:#1a1d3b}',
      '.wc-consent-btn-primary:hover{background:#30345c;border-color:#30345c}',
      '.wc-consent-btn-link{border-color:transparent;background:transparent;color:#555bdf;padding-left:0;padding-right:0}',
      '.wc-consent-manage{position:fixed;left:16px;bottom:16px;z-index:2147482500;border:1px solid #d6d9e8;background:#fff;color:#1a1d3b;border-radius:8px;padding:8px 11px;font:700 .8rem Inter,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;box-shadow:0 8px 24px rgba(13,15,28,.14);cursor:pointer}',
      '.wc-consent-overlay{position:fixed;inset:0;background:rgba(13,15,28,.48);z-index:2147483100;display:flex;align-items:center;justify-content:center;padding:20px;font-family:Inter,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#1a1d3b}',
      '.wc-consent-modal{width:min(620px,100%);max-height:calc(100vh - 40px);overflow:auto;background:#fff;border-radius:8px;border:1px solid #e4e7f5;box-shadow:0 18px 64px rgba(13,15,28,.22);padding:24px}',
      '.wc-consent-row{display:grid;grid-template-columns:1fr auto;gap:18px;align-items:center;padding:16px 0;border-top:1px solid #eef0f8}',
      '.wc-consent-row h3{font-size:.98rem;margin:0 0 4px;color:#1a1d3b}',
      '.wc-consent-row p{font-size:.86rem}',
      '.wc-consent-status{font-size:.78rem;font-weight:800;color:#555b76;text-transform:uppercase;letter-spacing:.04em}',
      '.wc-consent-switch{position:relative;display:inline-flex;width:52px;height:30px}',
      '.wc-consent-switch input{opacity:0;width:0;height:0}',
      '.wc-consent-slider{position:absolute;cursor:pointer;inset:0;background:#c8ccde;border-radius:999px;transition:.2s}',
      '.wc-consent-slider:before{content:"";position:absolute;width:24px;height:24px;left:3px;top:3px;background:#fff;border-radius:50%;transition:.2s;box-shadow:0 1px 3px rgba(13,15,28,.2)}',
      '.wc-consent-switch input:checked+.wc-consent-slider{background:#1a1d3b}',
      '.wc-consent-switch input:checked+.wc-consent-slider:before{transform:translateX(22px)}',
      '.wc-consent-modal-actions{display:flex;gap:10px;justify-content:flex-end;flex-wrap:wrap;margin-top:18px}',
      '@media (max-width:720px){.wc-consent-panel{grid-template-columns:1fr}.wc-consent-actions{justify-content:stretch}.wc-consent-actions .wc-consent-btn,.wc-consent-modal-actions .wc-consent-btn{flex:1 1 100%}.wc-consent-manage{left:10px;bottom:10px}.wc-consent-banner{left:10px;right:10px;bottom:10px}}'
    ].join('');
    document.head.appendChild(style);
  }

  function removeBanner() {
    var banner = document.getElementById('wc-consent-banner');
    if (banner) banner.remove();
  }

  function removeModal() {
    var modal = document.getElementById('wc-consent-overlay');
    if (modal) modal.remove();
  }

  function renderBanner() {
    if (hasSavedChoice() || document.getElementById('wc-consent-banner')) return;

    var banner = document.createElement('div');
    banner.id = 'wc-consent-banner';
    banner.className = 'wc-consent-banner';
    banner.innerHTML =
      '<div class="wc-consent-panel" role="dialog" aria-labelledby="wc-consent-title">' +
        '<div class="wc-consent-copy">' +
          '<h2 id="wc-consent-title">' + translation('title') + '</h2>' +
          '<p>' + translation('intro') + ' <a href="' + getPrivacyUrl() + '">' + translation('privacy') + '</a></p>' +
        '</div>' +
        '<div class="wc-consent-actions">' +
          '<button class="wc-consent-btn" data-wc-consent="reject">' + translation('rejectAll') + '</button>' +
          '<button class="wc-consent-btn" data-wc-consent="customize">' + translation('customize') + '</button>' +
          '<button class="wc-consent-btn wc-consent-btn-primary" data-wc-consent="accept">' + translation('acceptAll') + '</button>' +
        '</div>' +
      '</div>';

    document.body.appendChild(banner);
    bindCommonActions(banner);
  }

  function renderManageButton() {
    if (!hasSavedChoice() || document.getElementById('wc-consent-manage')) return;

    var button = document.createElement('button');
    button.id = 'wc-consent-manage';
    button.className = 'wc-consent-manage';
    button.type = 'button';
    button.textContent = translation('manage');
    button.addEventListener('click', openPreferences);
    document.body.appendChild(button);
  }

  function renderModal() {
    removeModal();

    var current = copyCategories(state.categories);
    var overlay = document.createElement('div');
    overlay.id = 'wc-consent-overlay';
    overlay.className = 'wc-consent-overlay';
    overlay.innerHTML =
      '<div class="wc-consent-modal" role="dialog" aria-modal="true" aria-labelledby="wc-consent-preferences-title">' +
        '<h2 id="wc-consent-preferences-title">' + translation('preferencesTitle') + '</h2>' +
        '<p>' + translation('preferencesIntro') + ' <a href="' + getPrivacyUrl() + '">' + translation('privacy') + '</a></p>' +
        categoryRow('necessary', translation('necessaryTitle'), translation('necessaryText'), true, true) +
        categoryRow('analytics', translation('analyticsTitle'), translation('analyticsText'), current.analytics, false) +
        categoryRow('marketing', translation('marketingTitle'), translation('marketingText'), current.marketing, false) +
        '<div class="wc-consent-modal-actions">' +
          '<button class="wc-consent-btn" data-wc-consent="reject">' + translation('rejectAll') + '</button>' +
          '<button class="wc-consent-btn" data-wc-consent="close">' + translation('close') + '</button>' +
          '<button class="wc-consent-btn wc-consent-btn-primary" data-wc-consent="save">' + translation('save') + '</button>' +
        '</div>' +
      '</div>';

    document.body.appendChild(overlay);
    bindCommonActions(overlay);
    overlay.querySelector('[data-wc-category="analytics"]').focus();
  }

  function categoryRow(category, title, description, checked, disabled) {
    if (disabled) {
      return '<div class="wc-consent-row"><div><h3>' + title + '</h3><p>' + description + '</p></div><span class="wc-consent-status">' + translation('alwaysOn') + '</span></div>';
    }

    return '<div class="wc-consent-row"><div><h3>' + title + '</h3><p>' + description + '</p></div><label class="wc-consent-switch"><input type="checkbox" data-wc-category="' + category + '"' + (checked ? ' checked' : '') + '><span class="wc-consent-slider"></span></label></div>';
  }

  function bindCommonActions(root) {
    root.querySelectorAll('[data-wc-consent]').forEach(function (button) {
      button.addEventListener('click', function () {
        var action = button.getAttribute('data-wc-consent');
        if (action === 'accept') saveState({ analytics: true, marketing: true });
        if (action === 'reject') saveState({ analytics: false, marketing: false });
        if (action === 'customize') openPreferences();
        if (action === 'close') removeModal();
        if (action === 'save') {
          saveState({
            analytics: Boolean(root.querySelector('[data-wc-category="analytics"]') && root.querySelector('[data-wc-category="analytics"]').checked),
            marketing: Boolean(root.querySelector('[data-wc-category="marketing"]') && root.querySelector('[data-wc-category="marketing"]').checked)
          });
        }
      });
    });
  }

  function openPreferences() {
    renderModal();
  }

  function setLanguage(nextLanguage) {
    if (!TEXT[nextLanguage]) return;
    language = nextLanguage;

    removeBanner();
    removeModal();
    var manageButton = document.getElementById('wc-consent-manage');
    if (manageButton) manageButton.remove();

    if (hasSavedChoice()) {
      renderManageButton();
    } else {
      renderBanner();
    }
  }

  function onChange(listener) {
    if (typeof listener !== 'function') return function () {};
    listeners.push(listener);
    return function () {
      listeners = listeners.filter(function (current) {
        return current !== listener;
      });
    };
  }

  window.WeConnectConsent = {
    get: getConsent,
    has: hasConsent,
    onChange: onChange,
    openPreferences: openPreferences,
    register: register,
    setLanguage: setLanguage
  };

  function init() {
    injectStyles();
    pushGoogleConsent('default');
    window.gtag('set', 'ads_data_redaction', true);

    if (hasSavedChoice()) {
      renderManageButton();
    } else {
      renderBanner();
    }

    evaluateRegistrations();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
