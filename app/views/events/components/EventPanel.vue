<template>
  <side-panel
    :is-visible="isVisible"
    :block-background="false"
    id="event-panel"
    @close-panel="close"
  >
    <template #header>
      {{ title }}
    </template>

    <template #body>
      <div class="body">
        <edit-event v-if="panelType !== 'info'" @save="onEventSave" />
      </div>
    </template>
  </side-panel>
</template>

<script>
import { mapGetters, mapMutations, mapActions } from 'vuex'
import SidePanel from '../../../components/common/SidePanel'
import EditEvent from './EditEventComponent'

export default {
  name: 'EventPanel',
  components: {
    SidePanel,
    EditEvent
  },
  computed: {
    ...mapGetters({
      isVisible: 'events/eventPanelVisible',
      panelType: 'events/eventPanelType'
    }),
    title () {
      return {
        info: 'Event Info', // maybe we don't need it
        new: 'Create Event',
        edit: 'Edit Event'
      }[this.panelType]
    }
  },
  methods: {
    ...mapMutations({
      close: 'events/closeEventPanel'
    }),
    ...mapActions({

})
    onEventSave () {
      this.close()
    }
  }
}
</script>

<style lang="scss" scoped>
.body {
  padding: 10px;
}
</style>
