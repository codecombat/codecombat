<template>
  <div>
    <transition name="slide">
      <div
        v-if="isVisible"
        id="event-panel"
        class="transition-side-panel"
      >
        <div class="header">
          <div class="header-right">
            <img
              class="close-btn"
              src="/images/ozaria/teachers/dashboard/svg_icons/Icon_Exit.svg"
              @click="close"
            >
          </div>
        </div>
        <div>Panel</div>
      </div>
    </transition>
  </div>
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'
export default {
  name: 'EventPanel',
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
@use 'app/styles/common/transition' with (
  $side-panel-width: min(40vw, 800px)
);

#event-panel {
  height: 100vh;
}

.header-right{
  float: right;
  .close-btn {
    cursor: pointer;
    margin-left: 30px;
    padding: 10px;
  }
}
</style>
