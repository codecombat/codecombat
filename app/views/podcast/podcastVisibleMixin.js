export default {
  methods: {
    isPodcastVisible (podcast) {
      return podcast.releasePhase === 'released' || (me.isAdmin() && ['beta', 'internalRelease'].includes(podcast.releasePhase))
    }
  }
}
