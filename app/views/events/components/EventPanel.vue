<template>
  <side-panel
    :is-visible="isVisible"
    :block-background="false"
    id="event-panel"
    @close-panel="close"
  >
    <template #header>
      <ul class="tabs nav nav-tabs">
        <li class="tab"
            :class="{active: panelType === t}"
            v-for="t in possibleTabs"
            :key="t"
            @click="changeTab(t)"
        >
          <a href="#">{{ t }}</a>
        </li>
      </ul>
    </template>

    <template #body>
      <div class="body">
        <edit-event v-if="['new', 'edit'].includes(panelType)" :editType="panelType" @save="onEventSave" />
        <!-- <members-component v-if="panelType === 'members'" /> -->
        <edit-members v-if="panelType === 'members'" @save="onEventSave" />
        <edit-instance v-if="panelType === 'instance'" @save="onEventSave" />
      </div>
    </template>
  </side-panel>
</template>

<script>
import { mapGetters, mapMutations, mapActions } from 'vuex'
import SidePanel from '../../../components/common/SidePanel'
import EditEvent from './EditEventComponent'
import EditMembers from './EditMembersComponent'
import EditInstance from './EditInstanceComponent'

export default {
  name: 'EventPanel',
  components: {
    SidePanel,
    EditEvent,
    EditMembers,
    EditInstance
  },
  data () {
    return {
    }
  },
  computed: {
    ...mapGetters({
      isVisible: 'events/eventPanelVisible',
      panelType: 'events/eventPanelType'
    }),
    tabOptions () {
      return [
        'new',
        'edit',
        'members',
        'instance'
      ]
    },
    possibleTabs () {
      if (me.isAdmin()) {
        if (this.panelType === 'new') {
          return ['new']
        } else {
          return ['instance', 'edit', 'members']
        }
      }
    },
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
      close: 'events/closeEventPanel',
      changeEventTab: 'events/changeEventPanelTab'
    }),
    ...mapActions({
      refreshEvent: 'events/fetchEvent'
    }),
    changeTab (t) {
      this.changeEventTab(t)
    },
    onEventSave (id) {
      this.refreshEvent(id).then(() => {
        this.close()
      })
    }
  }
}
</script>

<style lang="scss" scoped>
.body {
  padding: 10px;
}
.tabs {
  display: inline-block;
}
</style>
