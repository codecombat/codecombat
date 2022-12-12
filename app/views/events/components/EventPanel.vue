<template>
  <side-panel
    :is-visible="isVisible"
    :block-background="false"
    id="event-panel"
    @close-panel="close"
  >
    <template #header>
      Event Panel
    </template>

    <template #body>
      Body
    </template>
  </side-panel>
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'
import SidePanel from '../../../components/common/SidePanel'

export default {
  name: 'EventPanel',
  components: {
    SidePanel
  },
  computed: {
    ...mapGetters({
      isVisible: 'events/eventPanelVisible'
    })
  },
  methods: {
    ...mapMutations({
      close: 'events/closeEventPanel'
    })
  }
}
</script>

<style lang="scss" scoped>
</style>
