import trackable from './trackable.js'

export default {
  mixins: [trackable],
  mounted () {
    this.$el.addEventListener('click', (event) => {
      let element = event.target

      while (element && element.nodeName !== 'A' && element.nodeName !== 'BUTTON') {
        // find the closest link or button
        element = element.parentNode
      }

      let href = element.href
      if (href === '#') {
        href = null
      }

      if (element) {
        const eventName = `CTA ${href || element.innerText} clicked on ${window.location.pathname}`
        const data = {
          link: href || '',
          text: element.innerText,
          path: window.location.pathname,
        }
        this.trackEvent(eventName, data)
      }
    })
  },
}