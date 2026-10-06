'use client';
// Junior Boy Boxing — motion layer (visual only: no data, auth or payment logic lives here)
import { Fragment, useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { Icon } from './ui';
import './fx.css';

declare global { interface Window { __jbbIntroDone?: boolean } }
const EVT = 'jbb:intro-done';
let introDecision: boolean | null = null;
let introActive = false;
const prefersReduced = () => typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

export function markIntroDone() {
  if (typeof window === 'undefined') return;
  window.__jbbIntroDone = true;
  introActive = false;
  window.dispatchEvent(new Event(EVT));
}

function resolveIntroDecision(): boolean {
  if (typeof window === 'undefined') return false;
  if (window.__jbbIntroDone) return false;
  if (prefersReduced()) return false;
  if (introDecision !== null) return introDecision;
  let seen = false;
  try {
    seen = sessionStorage.getItem('jbb-intro') === '1';
    sessionStorage.setItem('jbb-intro', '1');
  } catch { /* storage blocked */ }
  introDecision = !seen && !prefersReduced();
  return introDecision;
}

export function useIntroDone() {
  const [done, setDone] = useState(false);
  useEffect(() => {
    if (window.__jbbIntroDone || !introActive) {
      setDone(true);
      return;
    }
    const h = () => setDone(true);
    window.addEventListener(EVT, h);
    const fallback = setTimeout(() => setDone(true), 2500);
    return () => {
      clearTimeout(fallback);
      window.removeEventListener(EVT, h);
    };
  }, []);
  return done;
}

/* ───────── Intro: "ROUND 1" bell splash (once per browser session) ───────── */
export function IntroSplash() {
  if (typeof window === 'undefined') {
    introActive = true;
  } else if (!window.__jbbIntroDone && introDecision !== false) {
    try {
      if (sessionStorage.getItem('jbb-intro') !== '1' && !prefersReduced()) {
        introActive = true;
      }
    } catch { /* storage blocked */ }
  }

  const [show, setShow] = useState(() => typeof window === 'undefined' || !window.__jbbIntroDone);
  const [playing, setPlaying] = useState(false);

  useEffect(() => {
    if (!show) return;
    const play = resolveIntroDecision();
    if (!play || window.__jbbIntroDone) {
      introActive = false;
      setShow(false);
      markIntroDone();
      return;
    }
    introActive = true;
    setPlaying(true);
    const t = setTimeout(() => {
      introActive = false;
      setShow(false);
      markIntroDone();
    }, 1950);
    return () => clearTimeout(t);
  }, [show]);

  const skip = () => {
    introActive = false;
    setShow(false);
    markIntroDone();
  };

  const ease = [0.76, 0, 0.24, 1] as const;

  return <AnimatePresence>{show && (
    <motion.div
      className="fx-intro"
      key="intro"
      onClick={skip}
      aria-hidden="true"
      exit={{ opacity: 0, transition: { delay: playing ? 0.75 : 0, duration: 0.01 } }}
    >
      <motion.div
        className="fx-intro-panel top"
        exit={{ y: '-101%' }}
        transition={playing ? { duration: 0.75, ease } : { duration: 0 }}
      />
      <motion.div
        className="fx-intro-panel bottom"
        exit={{ y: '101%' }}
        transition={playing ? { duration: 0.75, ease } : { duration: 0 }}
      />
      <div className="fx-intro-lines" />
      <motion.div
        className="fx-intro-content"
        animate={{ x: [0, 0, -16, 13, -8, 5, 0] }}
        transition={{ duration: 0.85, times: [0, 0.55, 0.62, 0.7, 0.8, 0.9, 1] }}
        exit={playing ? { opacity: 0, scale: 1.35, filter: 'blur(10px)', transition: { duration: 0.35 } } : { opacity: 0, transition: { duration: 0 } }}
      >
        <motion.span className="fx-intro-round" initial={{ opacity: 0, letterSpacing: '1.4em' }} animate={{ opacity: 1, letterSpacing: '.55em' }} transition={{ duration: 0.5, ease: 'easeOut' }}>ROUND</motion.span>
        <span className="fx-intro-numwrap">
          <motion.span className="fx-intro-ring" initial={{ scale: 0, opacity: 0 }} animate={{ scale: [0, 4], opacity: [1, 0] }} transition={{ delay: 0.5, duration: 0.8, ease: 'easeOut' }} />
          <motion.span className="fx-intro-num" initial={{ scale: 4.5, opacity: 0, filter: 'blur(16px)' }} animate={{ scale: 1, opacity: 1, filter: 'blur(0px)' }} transition={{ delay: 0.32, type: 'spring', stiffness: 520, damping: 19, filter: { delay: 0.32, duration: 0.2 }, opacity: { delay: 0.32, duration: 0.15 } }}>1</motion.span>
        </span>
        <motion.span className="fx-intro-bar" initial={{ scaleX: 0 }} animate={{ scaleX: 1 }} transition={{ delay: 0.85, duration: 0.5, ease }} />
        <motion.span className="fx-intro-mark wordmark" initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 1.0, duration: 0.45 }}>JUNIOR BOY <em>BOXING</em></motion.span>
      </motion.div>
      <motion.div className="fx-intro-flash" initial={{ opacity: 0 }} animate={{ opacity: [0, 0.6, 0] }} transition={{ delay: 0.45, duration: 0.4, times: [0, 0.12, 1] }} />
    </motion.div>)}
  </AnimatePresence>;
}

/* ───────── Hero headline: each word lands like a punch ───────── */
export function PunchTitle() {
  const done = useIntroDone();
  const reduced = useReducedMotion();
  const go = done || !!reduced;
  const words: [string, boolean][] = [['Discipline', false], ['builds', false], ['champions.', true]];
  return <motion.h1 className="fx-punch" animate={go && !reduced ? { x: [0, -14, 11, -6, 3, 0] } : undefined} transition={{ delay: 0.72, duration: 0.45 }}>
    {words.map(([w, champ], i) => <Fragment key={w}>{i > 0 && <br />}
      <motion.span className={`fx-word${champ ? ' fx-champ' : ''}`}
        initial={reduced ? false : { opacity: 0, scale: 2.3, y: -24, filter: 'blur(14px)' }}
        animate={go ? { opacity: 1, scale: 1, y: 0, filter: 'blur(0px)' } : undefined}
        transition={{ delay: 0.12 + i * 0.24, type: 'spring', stiffness: 430, damping: 21, mass: 0.9, opacity: { delay: 0.12 + i * 0.24, duration: 0.18 }, filter: { delay: 0.12 + i * 0.24, duration: 0.28 } }}>
        {w}
        {champ && !reduced && <motion.i className="fx-shock" initial={{ scale: 0, opacity: 0 }} animate={go ? { scale: [0, 3.4], opacity: [0.9, 0] } : undefined} transition={{ delay: 0.7, duration: 0.85, ease: 'easeOut' }} />}
      </motion.span>
    </Fragment>)}
  </motion.h1>;
}

/* ───────── Hero atmosphere: glow, light sweep, ring ropes, embers, impact sparks, parallax ───────── */
type P = { x: number; y: number; vx: number; vy: number; r: number; life: number; max: number; hue: number; spark: boolean };
export function HeroFX() {
  const canvas = useRef<HTMLCanvasElement>(null);
  const done = useIntroDone();
  useEffect(() => { const hero = canvas.current?.closest('.hero'); if (hero && done) hero.classList.add('fx-go'); }, [done]);
  useEffect(() => {
    const c = canvas.current, hero = c?.closest('.hero') as HTMLElement | null;
    if (!c || !hero || prefersReduced()) return;
    const ctx = c.getContext('2d'); if (!ctx) return;
    let w = 0, h = 0, raf = 0, visible = true, dpr = Math.min(window.devicePixelRatio || 1, 2);
    const ps: P[] = [];
    const small = () => w < 700;
    const spawn = (x?: number, y?: number, spark = false): P => {
      const a = Math.random() * Math.PI * 2, s = spark ? 2 + Math.random() * 6 : 0;
      return { x: x ?? Math.random() * w, y: y ?? h + 10, vx: spark ? Math.cos(a) * s : (Math.random() - 0.5) * 0.35, vy: spark ? Math.sin(a) * s : -(0.35 + Math.random() * 1.1), r: spark ? 0.8 + Math.random() * 1.8 : 0.6 + Math.random() * 2.2, life: 0, max: spark ? 40 + Math.random() * 30 : 260 + Math.random() * 320, hue: 350 + Math.random() * 25, spark };
    };
    const resize = () => { const r = hero.getBoundingClientRect(); w = r.width; h = r.height; c.width = w * dpr; c.height = h * dpr; ctx.setTransform(dpr, 0, 0, dpr, 0, 0); };
    resize();
    for (let i = 0; i < (small() ? 28 : 64); i++) { const p = spawn(); p.y = Math.random() * h; ps.push(p); }
    const tick = () => {
      raf = requestAnimationFrame(tick);
      if (!visible) return;
      ctx.clearRect(0, 0, w, h);
      ctx.globalCompositeOperation = 'lighter';
      for (let i = ps.length - 1; i >= 0; i--) {
        const p = ps[i];
        p.life++; p.x += p.vx + (p.spark ? 0 : Math.sin((p.life + i * 30) / 40) * 0.25); p.y += p.vy;
        if (p.spark) { p.vx *= 0.94; p.vy = p.vy * 0.94 + 0.12; }
        const t = p.life / p.max, alpha = p.spark ? 1 - t : Math.sin(Math.PI * Math.min(t, 1)) * 0.85;
        if (t >= 1 || p.y < -20) { if (p.spark) ps.splice(i, 1); else ps[i] = spawn(); continue; }
        const g = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.r * 5);
        g.addColorStop(0, `hsla(${p.hue},100%,${p.spark ? 75 : 62}%,${alpha})`);
        g.addColorStop(0.35, `hsla(${p.hue},100%,50%,${alpha * 0.45})`);
        g.addColorStop(1, 'hsla(0,100%,40%,0)');
        ctx.fillStyle = g; ctx.beginPath(); ctx.arc(p.x, p.y, p.r * 5, 0, Math.PI * 2); ctx.fill();
      }
    };
    raf = requestAnimationFrame(tick);
    const ro = new ResizeObserver(resize); ro.observe(hero);
    const io = new IntersectionObserver(([e]) => { visible = e.isIntersecting; }); io.observe(hero);
    const onMove = (e: PointerEvent) => { const r = hero.getBoundingClientRect(); hero.style.setProperty('--mx', `${e.clientX - r.left}px`); hero.style.setProperty('--my', `${e.clientY - r.top}px`); };
    const onDown = (e: PointerEvent) => { const r = hero.getBoundingClientRect(); for (let i = 0; i < 34; i++) ps.push(spawn(e.clientX - r.left, e.clientY - r.top, true)); };
    let sraf = 0;
    const onScroll = () => { cancelAnimationFrame(sraf); sraf = requestAnimationFrame(() => hero.style.setProperty('--sy', `${Math.min(window.scrollY, 1000)}px`)); };
    hero.addEventListener('pointermove', onMove, { passive: true });
    hero.addEventListener('pointerdown', onDown, { passive: true });
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => { cancelAnimationFrame(raf); cancelAnimationFrame(sraf); ro.disconnect(); io.disconnect(); hero.removeEventListener('pointermove', onMove); hero.removeEventListener('pointerdown', onDown); window.removeEventListener('scroll', onScroll); };
  }, []);
  return <>
    <div className="fx-hero" aria-hidden="true">
      <div className="fx-hero-glow" />
      <div className="fx-hero-sweep" />
      <div className="fx-hero-word">BOXING</div>
      <div className="fx-ropes"><i /><i /><i /></div>
    </div>
    <canvas ref={canvas} className="fx-embers" aria-hidden="true" />
  </>;
}

/* ───────── Double marquee strip ───────── */
export function Marquee() {
  const items: [string, string][] = [['fitness_center', 'TRAIN'], ['menu_book', 'LEARN'], ['trending_up', 'GROW']];
  const row = [...items, ...items, ...items, ...items];
  const words = ['DISCIPLINE', 'CONFIDENCE', 'FOCUS', 'STRENGTH', 'DISCIPLINE', 'CONFIDENCE', 'FOCUS', 'STRENGTH'];
  return <div className="fx-marquee" role="img" aria-label="Train. Learn. Grow.">
    <div className="fx-mq-track" aria-hidden="true">{[0, 1].map(k => <div className="fx-mq-group" key={k}>{row.map(([ic, t], i) => <span className="fx-mq-item" key={i}><Icon name={ic} />{t}<b className="fx-mq-sep" /></span>)}</div>)}</div>
    <div className="fx-mq-track fx-mq-rev" aria-hidden="true">{[0, 1].map(k => <div className="fx-mq-group" key={k}>{words.map((t, i) => <span className="fx-mq-outline" key={i}>{t}<b className="fx-mq-dot" /></span>)}</div>)}</div>
  </div>;
}

/* ───────── Site-wide: scroll progress, scroll reveals, 3D tilt cards ───────── */
const REVEAL = ['.section-heading', '.two-col > *', '.program', '.plan', '.program-grid > .card', '.faq > h2', '.faq details', '.cta-band .container > *', '.class-row', '.page-heading > *', '.values > div', '.footer-top > *', '.day-grid', '.stats-grid > *', '.legal > *'].join(',');
export function SiteFX() {
  const bar = useRef<HTMLDivElement>(null);
  useEffect(() => {
    let raf = 0;
    const update = () => { const d = document.documentElement, max = d.scrollHeight - d.clientHeight; if (bar.current) bar.current.style.transform = `scaleX(${max > 0 ? d.scrollTop / max : 0})`; };
    const onScroll = () => { cancelAnimationFrame(raf); raf = requestAnimationFrame(update); };
    update(); window.addEventListener('scroll', onScroll, { passive: true }); window.addEventListener('resize', onScroll);
    return () => { cancelAnimationFrame(raf); window.removeEventListener('scroll', onScroll); window.removeEventListener('resize', onScroll); };
  }, []);
  useEffect(() => {
    if (prefersReduced() || !('IntersectionObserver' in window)) return;
    const root = document.documentElement; root.classList.add('fx-ready');
    const io = new IntersectionObserver(entries => entries.forEach(e => {
      if (!e.isIntersecting) return;
      const el = e.target as HTMLElement; el.classList.add('fx-in'); io.unobserve(el);
      window.setTimeout(() => el.classList.add('fx-done'), 1700);
    }), { rootMargin: '0px 0px -8% 0px', threshold: 0.1 });
    let pending = 0;
    const scan = () => {
      pending = 0;
      document.querySelectorAll<HTMLElement>(REVEAL).forEach(el => {
        if (el.dataset.fx || el.closest('.hero,.modal,.admin-shell,dialog')) return;
        el.dataset.fx = '1';
        const sibs = el.parentElement ? Array.from(el.parentElement.children).filter(c => c.matches(REVEAL)) : [];
        el.style.setProperty('--fx-i', String(Math.min(Math.max(0, sibs.indexOf(el)), 6)));
        el.classList.add('fx-r'); io.observe(el);
      });
    };
    scan();
    const mo = new MutationObserver(() => { if (!pending) pending = requestAnimationFrame(scan); });
    mo.observe(document.body, { childList: true, subtree: true });
    return () => { io.disconnect(); mo.disconnect(); cancelAnimationFrame(pending); root.classList.remove('fx-ready'); document.querySelectorAll<HTMLElement>('.fx-r').forEach(el => { el.classList.add('fx-in'); }); };
  }, []);
  useEffect(() => {
    if (prefersReduced() || !window.matchMedia('(hover: hover) and (pointer: fine)').matches) return;
    let cur: HTMLElement | null = null;
    const reset = (el: HTMLElement) => { el.classList.remove('fx-tilt'); el.style.removeProperty('--rx'); el.style.removeProperty('--ry'); };
    const move = (e: PointerEvent) => {
      const el = (e.target as Element | null)?.closest?.('.program,.plan') as HTMLElement | null;
      if (cur && cur !== el) reset(cur);
      cur = el; if (!el) return;
      const r = el.getBoundingClientRect(), px = (e.clientX - r.left) / r.width, py = (e.clientY - r.top) / r.height;
      el.classList.add('fx-tilt');
      el.style.setProperty('--rx', `${((0.5 - py) * 7).toFixed(2)}deg`); el.style.setProperty('--ry', `${((px - 0.5) * 9).toFixed(2)}deg`);
      el.style.setProperty('--gx', `${(px * 100).toFixed(1)}%`); el.style.setProperty('--gy', `${(py * 100).toFixed(1)}%`);
    };
    const leave = () => { if (cur) reset(cur); cur = null; };
    document.addEventListener('pointermove', move, { passive: true }); document.addEventListener('pointerleave', leave);
    return () => { document.removeEventListener('pointermove', move); document.removeEventListener('pointerleave', leave); };
  }, []);
  return <div className="fx-progress" ref={bar} aria-hidden="true" />;
}
