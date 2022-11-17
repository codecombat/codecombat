const storage = require('app/core/storage')
export default {
  methods: {
    // add id on iframe element like this: :id="`podcast-${podcast._id}`"
    trackPlayClicked () {
      const elemId = document.activeElement.id
      this.allowIframeTracking()
      if(elemId?.includes('podcast')){
        const podcastId = elemId.split('-').pop()
        if (storage.load(this.storageKey(podcastId))) {
          return
        }
        window.tracker?.trackEvent('Podcast played', { podcastId })
        storage.save(this.storageKey(podcastId), true, 24 * 60 * 3)
      }
    },
    allowIframeTracking () {
      // without this blur, second click on any other iframe wont be tracked
      setTimeout(() => {
        document.activeElement?.blur()
      }, 3000)
    },
    storageKey (podcastId) {
     return `podcast-played-${podcastId}-${me.get('_id')}`
    }
  },
  mounted () {
    window.addEventListener('blur', this.trackPlayClicked)
  },
  beforeDestroy() {
    window.removeEventListener('blur', this.trackPlayClicked)
  }
}
