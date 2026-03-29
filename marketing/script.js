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

billingToggle.addEventListener('click', () => {
  isAnnual = !isAnnual;
  billingToggle.classList.toggle('active', isAnnual);

  document.querySelectorAll('.price[data-monthly]').forEach(el => {
    const price = isAnnual ? el.dataset.annual : el.dataset.monthly;
    el.textContent = `€${price}`;
  });

  document.getElementById('monthlyLabel').style.fontWeight = isAnnual ? '400' : '600';
  document.getElementById('monthlyLabel').style.color = isAnnual ? '' : 'var(--text)';
  document.getElementById('annualLabel').style.fontWeight = isAnnual ? '600' : '400';
  document.getElementById('annualLabel').style.color = isAnnual ? 'var(--text)' : '';
});

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
