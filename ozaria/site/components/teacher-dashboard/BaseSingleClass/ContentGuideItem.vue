<template>
  <div
    v-if="item.isTitle"
    :class="item.classes"
  >
    <h3>{{ item.title }}</h3>
  </div>
  <div
    v-else
    v-tooltip.bottom="tooltip"
    class="img-subtext"
    :class="item.classes"
  >
    <content-icon
      :icon="item.icon"
      :style="item.iconStyle"
    />
    <span>{{ item.text }}</span>
  </div>
</template>

<script>
import ContentIcon from '../common/icons/ContentIcon'

export default {
  name: 'ContentGuideItem',
  components: {
    ContentIcon,
  },
  props: {
    item: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    tooltip () {
      return {
        content: this.item.tooltip,
        classes: 'teacher-dashboard-tooltip lighter-p',
      }
    },
  },
}
</script>