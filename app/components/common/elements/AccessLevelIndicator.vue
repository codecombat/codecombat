<template>
  <span
    v-if="isDisplayable"
    v-tooltip.bottom="{
      content: $t(`paywall.badge_tooltip_${level}`),
    }"
    :class="badgeClass"
    @click="handleClick"
  >
    <span v-if="displayIcon">{{ icon }}</span>
    <span v-if="displayText">{{ $t(`paywall.badge_${level}`) }}</span>
  </span>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import CourseSchema from 'app/schemas/models/course.schema'
const ACCESS_LEVELS = CourseSchema.properties.modules.additionalProperties.properties.access.enum

export default {
  name: 'AccessLevelIndicator',
  props: {
    level: {
      type: String,
      required: false,
      validator: value => ACCESS_LEVELS.includes(value),
      default: 'free',
    },
    displayText: {
      type: Boolean,
      default: true,
    },
    displayIcon: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    ...mapGetters({
      isPaidTeacher: 'me/isPaidTeacher',
    }),
    isDisplayable () {
      const userDisplayMap = {
        free: ['free', 'sales-call', 'paid'], // non-paying users will see the 'free' and 'sales-call' badges
        'sales-call': ['paid'], // users after sales call will see the 'paid' badges
        paid: [], // I'm not sure if we'll have this for users, but if we'll have no badges needed.
      }
      const userLevel = this.isPaidTeacher ? 'paid' : 'free'
      return userDisplayMap[userLevel].includes(this.level)
    },
    badgeClass () {
      return {
        badge: true,
        [`badge-${this.level}`]: true,
      }
    },
    icon () {
      const icons = {
        free: '✨',
        'sales-call': '📞',
        paid: '🔒',
      }
      return icons[this.level] || ''
    },
  },
  async created () {
    await this.ensurePrepaidsLoadedForTeacher(me.get('_id'))
  },
  methods: {
    ...mapActions({
      ensurePrepaidsLoadedForTeacher: 'prepaids/ensurePrepaidsLoadedForTeacher',
    }),
    handleClick () {
      if (this.level === 'sales-call') {
        window.tracker?.trackEvent('Clicked Sales Call Badge')
        window.open('/schools?openContactModal=true', '_blank')
      }
    },
  },
}
</script>

<style scoped lang="scss">
.badge {
  padding: 5px;
  border-radius: 3px;
  font-size: 12px;
  color: black;
}

.badge-free {
  background-color: #5db9ac;
}

.badge-sales-call {
  background-color: #f7d047;
  cursor: pointer;
}

.badge-paid {
  background-color: #355EA0;
  color: #f7d047;
}
</style>
