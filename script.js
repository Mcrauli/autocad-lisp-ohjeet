/* =========================================================
   Shared behaviour — AutoCAD LISP site
   Progress bar, scroll reveal, toast notifications.
   Everything is feature-detected so it no-ops if the
   matching DOM isn't present.
   ========================================================= */

(function () {
  'use strict';

  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ----- Scroll progress bar ----- */
  const progressFill = document.querySelector('.scroll-progress__fill');
  if (progressFill) {
    let ticking = false;
    const update = () => {
      const max = document.documentElement.scrollHeight - window.innerHeight;
      const pct = max > 0 ? Math.min(1, Math.max(0, window.scrollY / max)) : 0;
      progressFill.style.transform = 'scaleX(' + pct + ')';
      ticking = false;
    };
    window.addEventListener('scroll', () => {
      if (!ticking) {
        requestAnimationFrame(update);
        ticking = true;
      }
    }, { passive: true });
    update();
  }

  /* ----- Scroll reveal ----- */
  const revealTargets = document.querySelectorAll('.reveal');
  if (revealTargets.length && 'IntersectionObserver' in window) {
    if (prefersReducedMotion) {
      revealTargets.forEach(el => el.classList.add('revealed'));
    } else {
      const io = new IntersectionObserver(entries => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            entry.target.classList.add('revealed');
            io.unobserve(entry.target);
          }
        });
      }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
      revealTargets.forEach(el => io.observe(el));
    }
  }

  /* ----- Toast notifications ----- */
  const toastHost = document.querySelector('.toast-host');
  function toast(message) {
    if (!toastHost) return;
    const el = document.createElement('div');
    el.className = 'toast';
    el.textContent = message;
    toastHost.appendChild(el);
    requestAnimationFrame(() => el.classList.add('toast--in'));
    setTimeout(() => {
      el.classList.remove('toast--in');
      el.addEventListener('transitionend', () => el.remove(), { once: true });
      setTimeout(() => el.remove(), 500);
    }, 2200);
  }

  /* Wire toast to download links */
  document.querySelectorAll('.file-action[download]').forEach(link => {
    link.addEventListener('click', () => {
      const filename = (link.getAttribute('href') || '').split('/').pop() || 'tiedosto';
      toast('Ladattu · ' + filename);
    });
  });
})();
