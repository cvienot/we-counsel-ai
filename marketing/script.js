// ===== i18n — language detection & translation =====
const SUPPORTED_LANGS = ['en', 'fr', 'es'];
const LANG_META = {
  en: { flag: '🇬🇧', code: 'EN', locale: 'en_US', path: '/' },
  fr: { flag: '🇫🇷', code: 'FR', locale: 'fr_FR', path: '/fr/' },
  es: { flag: '🇪🇸', code: 'ES', locale: 'es_ES', path: '/es/' }
};

function languageFromPath() {
  const firstSegment = window.location.pathname.split('/').filter(Boolean)[0];
  return SUPPORTED_LANGS.includes(firstSegment) ? firstSegment : null;
}

function canonicalUrl(lang) {
  return `https://we-connect-app.com${LANG_META[lang].path}`;
}

function localizedUrl(lang) {
  const params = new URLSearchParams(window.location.search);
  params.delete('lang');
  const query = params.toString();
  return `${window.location.origin}${LANG_META[lang].path}${query ? `?${query}` : ''}${window.location.hash}`;
}

function detectLanguage() {
  // 1. Check localized path (/fr/, /es/)
  const pathLang = languageFromPath();
  if (pathLang) return pathLang;

  // 2. Check URL param (?lang=fr)
  const params = new URLSearchParams(window.location.search);
  const paramLang = params.get('lang');
  if (paramLang && SUPPORTED_LANGS.includes(paramLang)) return paramLang;

  // 3. Check localStorage
  const stored = localStorage.getItem('we-connect-lang');
  if (stored && SUPPORTED_LANGS.includes(stored)) return stored;

  // 4. Check browser language
  const browserLang = (navigator.language || navigator.userLanguage || 'en').slice(0, 2).toLowerCase();
  if (SUPPORTED_LANGS.includes(browserLang)) return browserLang;

  return 'en';
}

function applyTranslations(lang) {
  const t = translations[lang];
  if (!t) return;

  // Update text content for data-i18n elements
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (t[key]) el.textContent = t[key];
  });

  // Update innerHTML for data-i18n-html elements (contains markup like <span>, <strong>)
  document.querySelectorAll('[data-i18n-html]').forEach(el => {
    const key = el.getAttribute('data-i18n-html');
    if (t[key]) el.innerHTML = t[key];
  });

  if (!document.documentElement.hasAttribute('data-static-meta')) {
    // Update meta tags on translated landing pages. SEO articles keep fixed per-page metadata.
    document.title = t['meta.title'] || document.title;
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) metaDesc.setAttribute('content', t['meta.description'] || '');

    const pageLang = languageFromPath() || 'en';
    const pageUrl = canonicalUrl(pageLang);
    const canonical = document.querySelector('link[rel="canonical"]');
    if (canonical) canonical.setAttribute('href', pageUrl);

    document.querySelectorAll('link[rel="alternate"][hreflang]').forEach(link => {
      const alternateLang = link.getAttribute('hreflang');
      if (alternateLang === 'x-default') {
        link.setAttribute('href', canonicalUrl('en'));
      } else if (LANG_META[alternateLang]) {
        link.setAttribute('href', canonicalUrl(alternateLang));
      }
    });

    // Update OG/Twitter tags
    const ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle) ogTitle.setAttribute('content', t['meta.title'] || '');
    const ogDesc = document.querySelector('meta[property="og:description"]');
    if (ogDesc) ogDesc.setAttribute('content', t['meta.description'] || '');
    const ogUrl = document.querySelector('meta[property="og:url"]');
    if (ogUrl) ogUrl.setAttribute('content', pageUrl);
    const ogLocale = document.querySelector('meta[property="og:locale"]');
    if (ogLocale) ogLocale.setAttribute('content', LANG_META[lang].locale);
    const twitterTitle = document.querySelector('meta[name="twitter:title"]');
    if (twitterTitle) twitterTitle.setAttribute('content', t['meta.title'] || '');
    const twitterDesc = document.querySelector('meta[name="twitter:description"]');
    if (twitterDesc) twitterDesc.setAttribute('content', t['meta.description'] || '');
  }

  // Update html lang attribute
  document.documentElement.lang = lang;

  // Update language switcher display
  const langFlag = document.getElementById('langFlag');
  const langCode = document.getElementById('langCode');
  if (langFlag) langFlag.textContent = LANG_META[lang].flag;
  if (langCode) langCode.textContent = LANG_META[lang].code;

  // Mark active language in dropdown
  document.querySelectorAll('.lang-option').forEach(opt => {
    opt.classList.toggle('active', opt.dataset.lang === lang);
  });

  // Persist choice
  localStorage.setItem('we-connect-lang', lang);

  if (window.WeConnectConsent) {
    window.WeConnectConsent.setLanguage(lang);
  }
}

// Initialize language
let currentLang = detectLanguage();
applyTranslations(currentLang);

// ===== Campaign attribution passthrough =====
const AD_ATTRIBUTION_PARAMS = new Set(['gclid', 'gbraid', 'wbraid']);

function isCampaignAttributionParam(key) {
  return key.startsWith('utm_') || key.startsWith('gad_') || AD_ATTRIBUTION_PARAMS.has(key);
}

function preserveCampaignParams() {
  const currentParams = new URLSearchParams(window.location.search);
  const campaignParams = new URLSearchParams();

  currentParams.forEach((value, key) => {
    if (isCampaignAttributionParam(key) && value) {
      campaignParams.set(key, value);
    }
  });

  if ([...campaignParams].length === 0) return;

  document.querySelectorAll('a[href^="https://app.we-connect-app.com"]').forEach(link => {
    const url = new URL(link.href);
    const isAppEntryLink = url.origin === 'https://app.we-connect-app.com' && url.pathname === '/';

    if (!isAppEntryLink) return;

    campaignParams.forEach((value, key) => {
      if (!url.searchParams.has(key)) {
        url.searchParams.set(key, value);
      }
    });

    link.href = url.toString();
  });
}

preserveCampaignParams();

const privacySettingsButton = document.getElementById('privacySettingsButton');
if (privacySettingsButton) {
  privacySettingsButton.addEventListener('click', () => {
    if (window.WeConnectConsent) {
      window.WeConnectConsent.openPreferences();
    }
  });
}

// Language switcher dropdown
const langBtn = document.getElementById('langBtn');
const langDropdown = document.getElementById('langDropdown');

if (langBtn && langDropdown) {
  langBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    langDropdown.classList.toggle('open');
  });

  document.querySelectorAll('.lang-option').forEach(opt => {
    opt.addEventListener('click', () => {
      const newLang = opt.dataset.lang;
      if (newLang !== currentLang) {
        localStorage.setItem('we-connect-lang', newLang);
        window.location.href = localizedUrl(newLang);
        return;
      }
      langDropdown.classList.remove('open');
    });
  });

  // Close dropdown on outside click
  document.addEventListener('click', () => {
    langDropdown.classList.remove('open');
  });
}

// ===== Navbar scroll effect =====
const nav = document.getElementById('nav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 20);
}, { passive: true });

// ===== Mobile menu toggle =====
const navToggle = document.getElementById('navToggle');
const navLinks = document.getElementById('navLinks');

navToggle.addEventListener('click', () => {
  navLinks.classList.toggle('open');
  navToggle.classList.toggle('active');
});

// Close mobile menu on link click
navLinks.querySelectorAll('a').forEach(link => {
  link.addEventListener('click', () => {
    navLinks.classList.remove('open');
    navToggle.classList.remove('active');
  });
});

// ===== Scroll animations =====
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry, i) => {
      if (entry.isIntersecting) {
        // Stagger animations for sibling elements
        const parent = entry.target.parentElement;
        const siblings = parent ? Array.from(parent.querySelectorAll('[data-animate]')) : [];
        const index = siblings.indexOf(entry.target);
        const delay = index >= 0 ? index * 80 : 0;

        setTimeout(() => {
          entry.target.classList.add('visible');
        }, delay);

        observer.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.1, rootMargin: '0px 0px -40px 0px' }
);

document.querySelectorAll('[data-animate]').forEach(el => observer.observe(el));

// ===== Billing toggle =====
const billingToggle = document.getElementById('billingToggle');
let isAnnual = false;

if (billingToggle) {
  billingToggle.addEventListener('click', () => {
    isAnnual = !isAnnual;
    billingToggle.classList.toggle('active', isAnnual);

    document.querySelectorAll('.price[data-monthly]').forEach(el => {
      const price = isAnnual ? el.dataset.annual : el.dataset.monthly;
      el.textContent = `€${price}`;
    });

    const monthlyLabel = document.getElementById('monthlyLabel');
    const annualLabel = document.getElementById('annualLabel');
    if (monthlyLabel) {
      monthlyLabel.style.fontWeight = isAnnual ? '400' : '600';
      monthlyLabel.style.color = isAnnual ? '' : 'var(--text)';
    }
    if (annualLabel) {
      annualLabel.style.fontWeight = isAnnual ? '600' : '400';
      annualLabel.style.color = isAnnual ? 'var(--text)' : '';
    }
  });
}

// ===== Smooth scroll for anchor links =====
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', (e) => {
    const href = anchor.getAttribute('href');
    if (href === '#') return;
    e.preventDefault();
    const target = document.querySelector(href);
    if (target) {
      const offset = 80; // nav height
      const top = target.getBoundingClientRect().top + window.scrollY - offset;
      window.scrollTo({ top, behavior: 'smooth' });
    }
  });
});
