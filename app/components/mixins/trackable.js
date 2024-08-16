export default {
  methods: {
    trackEvent (eventName, data) {
      if (eventName) {
        window.tracker?.trackEvent(eventName, data)
      }
    },
  }
}