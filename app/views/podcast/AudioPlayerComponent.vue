<template>
  <modal
    @close="$emit('close')"
  >
    <iframe
      :src="transistorUrl"
      width="80%"
      height="180"
      frameborder="0"
      scrolling="no"
      seamless="true"
      style="width:80%; height:180px;"
    />
  </modal>
</template>

<script>
import Modal from '../../components/common/Modal'
export default {
  name: 'AudioPlayerComponent',
  components: {
    Modal
  },
  props: {
    transistorEpisodeId: {
      type: String
    }
  },
  computed: {
    transistorUrl () {
      return `https://share.transistor.fm/e/${this.transistorEpisodeId}/dark`
    }
  }
}
</script>

<style scoped lang="scss">
::v-deep .modal-container {
  width: 80%;
}
</style>
