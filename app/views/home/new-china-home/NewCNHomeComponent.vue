<template>
  <div class="new-cn-home-wrapper">
    <div
      ref="snapContainer"
      class="snap-container"
    >
      <!-- Section 1: Hero -->
      <section
        id="section1"
        class="snap-section"
      >
        <PageSection1 />
      </section>

      <!-- Section 2: Game Trailer -->
      <section
        id="section2"
        class="snap-section"
      >
        <PageSection2 />
      </section>

      <!-- Section 3: Story Carousel -->
      <section
        id="section3"
        class="snap-section"
      >
        <PageSection3 />
      </section>

      <!-- Section 4: AI Mentor -->
      <section
        id="section4"
        class="snap-section"
      >
        <PageSection4 />
      </section>

      <!-- Section 5: Programming Languages -->
      <section
        id="section5"
        class="snap-section"
      >
        <PageSection5 />
      </section>

      <!-- Section 6: Global Pioneer -->
      <section
        id="section6"
        class="snap-section"
      >
        <PageSection6 />
      </section>

      <!-- Section 7: User Testimonials -->
      <section
        id="section7"
        class="snap-section"
      >
        <PageSection7 />
      </section>

      <!-- Section 8: Pricing -->
      <section
        id="section8"
        class="snap-section"
      >
        <PageSection8 />
      </section>

      <!-- Section 9: Benefits -->
      <section
        id="section9"
        class="snap-section"
      >
        <PageSection9 />
      </section>

      <!-- Section 10: Showcase Images -->
      <section
        id="section10"
        class="snap-section"
      >
        <PageSection10 />
      </section>

      <section
        id="section11"
        class="snap-section"
      >
        <PageSection11 />
      </section>
    </div>
  </div>
</template>

<script>
import PageSection1 from './components/PageSection1'
import PageSection2 from './components/PageSection2'
import PageSection3 from './components/PageSection3'
import PageSection4 from './components/PageSection4'
import PageSection5 from './components/PageSection5'
import PageSection6 from './components/PageSection6'
import PageSection7 from './components/PageSection7'
import PageSection8 from './components/PageSection8'
import PageSection9 from './components/PageSection9'
import PageSection10 from './components/PageSection10'
import PageSection11 from './components/PageSection11'

export default Vue.extend({
  name: 'NewCNHomeComponent',
  components: {
    PageSection1,
    PageSection2,
    PageSection3,
    PageSection4,
    PageSection5,
    PageSection6,
    PageSection7,
    PageSection8,
    PageSection9,
    PageSection10,
    PageSection11,
  },
  mounted () {
    // Load external CSS dependencies
    this.loadFontAwesome()
    this.loadGoogleFonts()

    // Wait a bit for Tailwind to load before initializing animations
    setTimeout(() => {
      // Dynamically load GSAP if not already loaded
      this.loadGSAP().then(() => {
        this.initGSAPAnimations()
      })
    }, 100)
  },

  methods: {
    loadFontAwesome () {
      // Check if Font Awesome is already loaded
      if (document.getElementById('font-awesome-cdn')) return

      // Create link tag for Font Awesome
      const link = document.createElement('link')
      link.id = 'font-awesome-cdn'
      link.rel = 'stylesheet'
      link.href = 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css'
      document.head.appendChild(link)
    },

    loadGoogleFonts () {
      // Check if Google Fonts is already loaded
      if (document.getElementById('google-fonts-cdn')) return

      // Create link tag for Google Fonts
      const link = document.createElement('link')
      link.id = 'google-fonts-cdn'
      link.rel = 'stylesheet'
      link.href = 'https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;700&family=Noto+Sans+SC:wght@300;400;700;900&display=swap'
      document.head.appendChild(link)
    },

    async loadGSAP () {
      // Check if GSAP is already loaded
      if (window.gsap && window.ScrollTrigger) {
        return Promise.resolve()
      }

      // Load GSAP from CDN
      return new Promise((resolve, reject) => {
        const script1 = document.createElement('script')
        script1.src = 'https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js'
        script1.onload = () => {
          const script2 = document.createElement('script')
          script2.src = 'https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/ScrollTrigger.min.js'
          script2.onload = () => {
            window.gsap.registerPlugin(window.ScrollTrigger)
            resolve()
          }
          script2.onerror = reject
          document.head.appendChild(script2)
        }
        script1.onerror = reject
        document.head.appendChild(script1)
      })
    },

    initGSAPAnimations () {
      const gsap = window.gsap
      const snapContainer = this.$refs.snapContainer

      const animateSection = (sectionId) => {
        const section = document.getElementById(sectionId)
        if (!section) return

        const leftEls = section.querySelectorAll('.anim-left')
        const rightEls = section.querySelectorAll('.anim-right')
        const upEls = section.querySelectorAll('.anim-up')
        const zoomEls = section.querySelectorAll('.anim-zoom')

        if (leftEls.length) {
          gsap.fromTo(leftEls,
                      { x: -30, autoAlpha: 0 },
                      { x: 0, autoAlpha: 1, duration: 0.8, ease: 'power2.out', stagger: 0.1, overwrite: 'auto' },
          )
        }
        if (rightEls.length) {
          gsap.fromTo(rightEls,
                      { x: 30, autoAlpha: 0 },
                      { x: 0, autoAlpha: 1, duration: 0.8, ease: 'power2.out', stagger: 0.1, delay: 0.1, overwrite: 'auto' },
          )
        }
        if (upEls.length) {
          gsap.fromTo(upEls,
                      { y: 30, autoAlpha: 0 },
                      { y: 0, autoAlpha: 1, duration: 0.8, ease: 'back.out(1.2)', stagger: 0.15, overwrite: 'auto' },
          )
        }
        if (zoomEls.length) {
          gsap.fromTo(zoomEls,
                      { scale: 0.8, autoAlpha: 0 },
                      { scale: 1, autoAlpha: 1, duration: 0.8, ease: 'back.out(1.5)', overwrite: 'auto' },
          )
        }
      }

      // Observe sections for animations
      this.sectionsObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            animateSection(entry.target.id)
          }
        })
      }, { root: snapContainer, threshold: 0.1 })

      document.querySelectorAll('.snap-section').forEach(el => {
        this.sectionsObserver.observe(el)
      })

      // Animate first section immediately
      animateSection('section1')
    },

    // Pricing Methods
  },
})
</script>

<style scoped lang="scss">
::v-deep {
  html {
    font-size: 16px !important;
  }
}
/* Scroll Container */
.snap-container {
  height: calc(100vh - 71px);
  overflow-y: auto;
  scroll-snap-type: y mandatory;
  scroll-behavior: smooth;
}

/* Section Styling */
.snap-section {
  scroll-snap-align: start;
  min-height: calc(100vh - 71px);
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  position: relative;
  background: linear-gradient(90deg, #F0F9FA 0%, #D9F0F3 100%);
  padding-top: 20px;
  padding-bottom: 60px;
}

@media (max-height: 800px) {
  .snap-section {
    padding-top: 40px;
    padding-bottom: 40px;
    justify-content: flex-start;
  }
}

/* Button Styles */
.btn-action {
  background-color: #F2BE22;
  color: #422B06;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  font-weight: 900;
  border: none;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  -webkit-tap-highlight-color: transparent;
}

.btn-action:hover {
  transform: translateY(-3px) scale(1.02);
  box-shadow: 0 15px 30px rgba(242, 190, 34, 0.5);
  background-color: #ffd24d;
}
::v-deep {
  .std-section-title {
    font-weight: 900;
    color: #1e293b;
    line-height: 1.1;
  }

  .highlight-primary {
    color: #4338ca;
  }

  .highlight-warm {
    color: #b45309;
  }
}

/* Hero Section Effects */
@keyframes float {
  0%, 100% { transform: translate(0, 0); }
  50% { transform: translate(20px, -10px); }
}

.cloud-left-top {
  position: absolute;
  top: 80px;
  left: 20px;
  width: 250px;
  animation: float 8s ease-in-out infinite;
  z-index: 0;
  opacity: 0.6;
  pointer-events: none;
}

.cloud-button-right {
  position: absolute;
  top: 500px;
  left: 40%;
  width: 150px;
  transform: rotate(-15deg);
  z-index: 0;
  opacity: 0.6;
  pointer-events: none;
}

.cloud-text-right-top {
  position: absolute;
  top: 150px;
  left: 45%;
  width: 120px;
  z-index: 0;
  opacity: 0.6;
  pointer-events: none;
}

@media (max-width: 768px) {
  .cloud-left-top,
  .cloud-button-right,
  .cloud-text-right-top {
    opacity: 0.2;
    width: 150px;
  }
  .hero-image-glow::before {
    display: none;
  }
}

@keyframes breathe {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-20px); }
}

.hero-image {
  animation: breathe 4s ease-in-out infinite;
}

.hero-image-glow::before {
  content: '';
  position: absolute;
  top: -10%;
  left: -10%;
  width: 120%;
  height: 120%;
  background: radial-gradient(ellipse at center, rgba(99, 102, 241, 0.3) 0%, rgba(6, 182, 212, 0.2) 50%, transparent 70%);
  border-radius: 50%;
  animation: glow-pulse 3s ease-in-out infinite;
  z-index: -1;
}

@keyframes glow-pulse {
  0%, 100% { opacity: 0.6; transform: scale(1); }
  50% { opacity: 0.9; transform: scale(1.05); }
}

/* Video Frame */
.video-frame {
  position: relative;
  border-radius: 24px;
  overflow: hidden;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.15);
  transform: translateZ(0);
  background: #fff;
  border: 4px solid #fff;
}

/* Animation Classes */
.anim-left,
.anim-right,
.anim-up,
.anim-card,
.anim-zoom {
  opacity: 0;
  visibility: hidden;
}

$primary-color: #F2BE22;
$primary-background: #31636F;
::v-deep * {
  font-family: Plus Jakarta Sans;
}

::v-deep div {
  &.heading {
    font-size: clamp(3.0rem, 5vw + 1.6rem, 6.0rem) !important;
    line-height: 1;
    font-weight: 900;

    .description {
      font-size: 1.8rem;
      font-weight: normal;
    }
  }
}

::v-deep .CTA {
  $black: #0A2239;

  &__button {
    color: $black !important;
    background-color: $primary-color;
    text-shadow: unset !important;
    font-weight: bold;

    &:hover {
      background-color: lighten($primary-color, 10%);

      [style*="--type: no-background"] & {
        background-color: rgba($primary-color, 0.3);
      }
    }
  }
}

::v-deep {
  .cta-button {
    width: fit-content;
    margin-top: 6rem;

    .description {
      color: #94a3b8;
    }
  }
  img, video {
    width: 100%;
  }
  .page-section {
    width: 100%;
    padding: 40px 20px !important;
    .frame {
      display: flex;
      gap: 10px;
    }
  }
}

::v-deep .two-column-block {
  .column-one, .column-two {
    flex-basis: calc(50% - 15px);
  }
}
/* Hide scrollbar for Chrome, Safari and Opera */
.no-scrollbar::-webkit-scrollbar {
  display: none;
}

/* Hide scrollbar for IE, Edge and Firefox */
.no-scrollbar {
  -ms-overflow-style: none;  /* IE and Edge */
  scrollbar-width: none;  /* Firefox */
}
</style>

<style lang="scss">
/* Layout & Container */
.w-full { width: 100%; }
.w-2 { width: 0.8rem; }
.w-12 { width: 4.8rem; }
.w-48 { width: 19.2rem; }

.h-full { height: 100%; }
.h-2 { height: 0.8rem; }
.h-12 { height: 4.8rem; }
.h-auto { height: auto; }

.max-w-5xl { max-width: 102.4rem; }
.max-w-6xl { max-width: 115.2rem; }

.container {
  width: 100%;
  margin-left: auto;
  margin-right: auto;
  padding-left: 1.6rem;
  padding-right: 1.6rem;
}

.mx-auto {
  margin-left: auto;
  margin-right: auto;
}

/* Spacing - Padding */
.p-2 { padding: 0.8rem; }
.p-3 { padding: 1.2rem; }
.p-4 { padding: 1.6rem; }

.px-1 { padding-left: 0.4rem; padding-right: 0.4rem; }
.px-2 { padding-left: 0.8rem; padding-right: 0.8rem; }
.px-4 { padding-left: 1.6rem; padding-right: 1.6rem; }

.py-6 { padding-top: 2.4rem; padding-bottom: 2.4rem; }
.py-12 { padding-top: 4.8rem; padding-bottom: 4.8rem; }

.pl-6 { padding-left: 2.4rem; }

/* Spacing - Margin */
.mt-1 { margin-top: 0.4rem; }
.mt-2 { margin-top: 0.8rem; }
.mt-4 { margin-top: 1.6rem; }

.mb-2 { margin-bottom: 0.8rem; }
.mb-4 { margin-bottom: 1.6rem; }
.mb-10 { margin-bottom: 4.0rem; }

.ml-1 { margin-left: 0.4rem; }

/* Gap */
.gap-3 { gap: 1.2rem; }
.gap-4 { gap: 1.6rem; }

.space-y-4 > * + * { margin-top: 1.6rem; }
.space-y-6 > * + * { margin-top: 2.4rem; }
.space-y-12 > * + * { margin-top: 4.8rem; }

/* Flexbox */
.flex { display: flex; }
.flex-col { flex-direction: column; }

.items-start { align-items: flex-start; }
.items-center { align-items: center; }

.justify-center { justify-content: center; }

.flex-shrink-0,
.shrink-0 { flex-shrink: 0; }

/* Grid */
.grid { display: grid; }
.grid-cols-1 { grid-template-columns: repeat(1, minmax(0, 1fr)); }

.order-1 { order: 1; }
.order-2 { order: 2; }
.order-3 { order: 3; }

/* Positioning */
.fixed { position: fixed; }
.absolute { position: absolute; }

.top-0 { top: 0; }
.bottom-0 { bottom: 0; }
.bottom-6 { bottom: 2.4rem; }
.bottom-16 { bottom: 6.4rem; }

.left-0 { left: 0; }
.right-0 { right: 0; }
.right-4 { right: 1.6rem; }

.z-50 { z-index: 50; }

/* Background Colors */
.bg-white { background-color: #ffffff; }

.bg-indigo-100 { background-color: #e0e7ff; }
.bg-indigo-200 { background-color: #c7d2fe; }
.bg-indigo-500 { background-color: #6366f1; }
.bg-indigo-600 { background-color: #4f46e5; }

.bg-yellow-50 { background-color: #fefce8; }
.bg-yellow-100 { background-color: #fef9c3; }

.bg-orange-100 { background-color: #ffedd5; }

.bg-blue-100 { background-color: #dbeafe; }

.bg-red-100 { background-color: #fee2e2; }

.bg-slate-100 { background-color: #f1f5f9; }

/* Text Colors */
.text-indigo-100 { color: #e0e7ff; }
.text-indigo-300 { color: #a5b4fc; }
.text-indigo-500 { color: #6366f1; }
.text-indigo-600 { color: #4f46e5; }
.text-indigo-700 { color: #4338ca; }
.text-indigo-800 { color: #3730a3; }
.text-indigo-900 { color: #312e81; }

.text-slate-400 { color: #94a3b8; }
.text-slate-500 { color: #64748b; }
.text-slate-600 { color: #475569; }
.text-slate-700 { color: #334155; }
.text-slate-800 { color: #1e293b; }
.text-slate-900 { color: #0f172a; }

.text-yellow-500 { color: #eab308; }
.text-yellow-600 { color: #ca8a04; }
.text-yellow-700 { color: #a16207; }
.text-yellow-800 { color: #854d0e; }

.text-orange-500 { color: #f97316; }
.text-orange-700 { color: #c2410c; }
.text-orange-800 { color: #9a3412; }

.text-blue-500 { color: #3b82f6; }
.text-blue-700 { color: #1d4ed8; }

.text-red-500 { color: #ef4444; }

.text-green-500 { color: #22c55e; }

.text-purple-600 { color: #9333ea; }

.text-cyan-600 { color: #0891b2; }
.text-cyan-700 { color: #0e7490; }
.text-cyan-800 { color: #155e75; }

/* Borders */
.border { border-width: 1px; border-style: solid; }
.border-2 { border-width: 2px; border-style: solid; }

.border-slate-100 { border-color: #f1f5f9; }

.border-indigo-200 { border-color: #c7d2fe; }
.border-indigo-400 { border-color: #818cf8; }

.border-yellow-200 { border-color: #fef08a; }

.border-l-4 { border-left-width: 4px; border-left-style: solid; }

/* Typography */
.text-xs { font-size: 1.2rem; line-height: 1.6rem; }
.text-sm { font-size: 1.4rem; line-height: 2.0rem; }
.text-base { font-size: 1.6rem; line-height: 2.4rem; }
.text-lg { font-size: 1.8rem; line-height: 2.8rem; }
.text-xl { font-size: 2.0rem; line-height: 2.8rem; }
.text-3xl { font-size: 3.0rem; line-height: 3.6rem; }
.text-4xl { font-size: 3.6rem; line-height: 4.0rem; }
.font-black { font-weight: 900; }

.font-normal { font-weight: 400; }
.font-medium { font-weight: 500; }
.font-bold { font-weight: 700; }

.leading-relaxed { line-height: 1.625; }

.text-center { text-align: center; }

.whitespace-nowrap { white-space: nowrap; }

.line-through { text-decoration: line-through; }

.align-middle { vertical-align: middle; }

.font-mono { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }

/* Border Radius */
.rounded { border-radius: 0.4rem; }
.rounded-full { border-radius: 9999px; }
.rounded-xl { border-radius: 1.2rem; }
.rounded-2xl { border-radius: 1.6rem; }

/* Shadows */
.shadow-sm { box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05); }
.shadow-lg { box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05); }
.shadow-xl { box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04); }
.shadow-2xl { box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25); }

/* Effects */
.opacity-0 { opacity: 0; }
.opacity-80 { opacity: 0.8; }

.backdrop-blur-sm { backdrop-filter: blur(4px); }
.backdrop-blur-xl { backdrop-filter: blur(24px); }

/* Transforms & Transitions */
.transform { transform: translateX(0) translateY(0) rotate(0) skewX(0) skewY(0) scaleX(1) scaleY(1); }
.scale-0 { transform: scale(0); }

.transition-all { transition-property: all; transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1); transition-duration: 150ms; }
.transition-transform { transition-property: transform; transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1); transition-duration: 150ms; }

.duration-300 { transition-duration: 300ms; }

.origin-bottom-right { transform-origin: bottom right; }

/* Interactivity */
.cursor-pointer { cursor: pointer; }

/* Misc */
.block { display: block; }
.object-cover { object-fit: cover; }

/* Responsive - Medium screens (768px and up) */
@media (min-width: 768px) {
  .md-px-2 { padding-left: 0.8rem; padding-right: 0.8rem; }
  .md-px-5 { padding-left: 2.0rem; padding-right: 2.0rem; }
  .md-px-6 { padding-left: 2.4rem; padding-right: 2.4rem; }
  .md-px-12 { padding-left: 4.8rem; padding-right: 4.8rem; }

  .md-text-base { font-size: 1.6rem; line-height: 2.4rem; }
  .md-text-lg { font-size: 1.8rem; line-height: 2.8rem; }
  .md-text-xl { font-size: 2.0rem; line-height: 2.8rem; }
  .md-text-2xl { font-size: 2.4rem; line-height: 3.2rem; }
  .md-text-5xl { font-size: 4.8rem; line-height: 1; }
  .md-text-7xl { font-size: 7.2rem; line-height: 1; }

  .md-gap-4 { gap: 1.6rem; }

  .md-space-y-6 > * + * { margin-top: 2.4rem; }
  .md-space-y-8 > * + * { margin-top: 3.2rem; }
  .md-space-y-10 > * + * { margin-top: 4.0rem; }
  .md-space-y-20 > * + * { margin-top: 8.0rem; }

  .md-col-span-1 { grid-column: span 1 / span 1; }
  .md-col-span-2 { grid-column: span 2 / span 2; }
  .md-col-span-4 { grid-column: span 4 / span 4; }

  .md-grid-cols-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
  .md-grid-cols-4 { grid-template-columns: repeat(4, minmax(0, 1fr)); }

  .md-mt-2 { margin-top: 0.8rem; }
  .md-mt-2\.5 { margin-top: 1rem; }

  .md-mb-20 { margin-bottom: 8.0rem; }

  .md-w-14 { width: 5.6rem; }
  .md-h-14 { height: 5.6rem; }

  .md-bottom-8 { bottom: 3.2rem; }
  .md-bottom-20 { bottom: 8.0rem; }

  .md-right-8 { right: 3.2rem; }

  .md-order-1 { order: 1; }
  .md-order-2 { order: 2; }
  .md-order-3 { order: 3; }
}

/* Responsive - Large screens (1024px and up) */
@media (min-width: 1024px) {
  .lg-px-24 { padding-left: 9.6rem; padding-right: 9.6rem; }

  .lg-text-left { text-align: left; }
  .lg-text-6xl { font-size: 6.0rem; line-height: 1; }
  .lg-text-8xl { font-size: 9.6rem; line-height: 1; }
}
</style>
