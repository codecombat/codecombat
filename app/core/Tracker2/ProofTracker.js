import CocoLegacyTracker from '../Tracker'
import BaseTracker from './BaseTracker'

export function loadProof () {
  /* eslint-disable */

  const styleTag = document.createElement('style')
  styleTag.type = 'text/css'
  styleTag.innerHTML = '.proofx-hidden{visibility:hidden}'
  document.head.appendChild(styleTag)

  !function(c,s,e){if("function"==typeof document.querySelector){if(e){document.querySelector("html").classList.add("proofx-hidden")};var proofx=c.proofx=c.proofx||[];if(!proofx.initialized)if(proofx.invoked)c.console&&console.error&&console.error("ProofX snippet included twice.");else{proofx.invoked=!0;proofx.methods=["identify","watchIdentity","reset","track","page","watchInput","setInputValue","unwatchInput","watchInputs","unwatchInputs","init"];proofx.factory=function(t){return function(){var e=Array.prototype.slice.call(arguments);e.unshift(t);proofx.push(e);return proofx}};for(var t=0;t<proofx.methods.length;t++){var o=proofx.methods[t];proofx[o]=proofx.factory(o)}proofx.load=function(e,t){var o=t&&t.timeout?t.timeout:2e3;c.setTimeout(function(){var e=s.getElementsByClassName("proofx-hidden");for(var i = 0;i<e.length;i++)e[i].className=e[i].className.replace(/proofx-hidden/g,"")},o);var n=Date.now(),r=document.createElement("link");r.href="https://cdn.proof-x.com/proofx.js?ver="+n;r.rel="preload";r.as="script";document.head.appendChild(r);var a=s.getElementsByTagName("script")[0];a.parentNode.insertBefore(r,a);var i=s.createElement("script");i.type="text/javascript";i.async=!0;i.src="https://cdn.proof-x.com/proofx.js?ver="+n;a.parentNode.insertBefore(i,a);proofx.init(e,t)};
    proofx.load("-M-RGUfR3QToJiCIwXw7", { timeout: 2000 });
    proofx.page();
  }}}(window,document,false);
}

export default class ProofTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store
    this.enabled = window.location.hostname.startsWith('next.')
  }

  async _initializeTracker () {
    if (!this.enabled) {
      return this.onInitializeSuccess()
    }

    loadProof()
    this.onInitializeSuccess()
  }

  async identify (traits = {}) {
    if (!this.enabled) {
      return
    }

    const { me } = this.store.state

    // TODO determine what traits we want to send for all user types
    proofx.identify(me._id)
  }

  async trackPageView (includeIntegrations = []) {
    proofx.page()
  }

  async trackEvent (action, properties = {}) {
    proofx.track(action, properties)
  }

  async resetIdentity () {
    proofx.reset()
  }
}
