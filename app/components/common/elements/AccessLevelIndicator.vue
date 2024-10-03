<template>
  <span
    v-if="isDisplayable"
    v-tooltip.bottom="{
      content: $t(`paywall.badge_tooltip_${level}`),
    }"
    :class="badgeClass"
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
        free: ['free', 'sales-call'], // non-paying users will see the 'free' and 'sales-call' badges
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
  },
}
</script>

<style scoped lang="scss">
.badge {
  padding: 5px;
  border-radius: 3px;
  color: white;
  font-size: 12px;
}

.badge-free {
  background-color: green;
}

.badge-sales-call {
  background-color: orange;
}

.badge-paid {
  background-color: red;
}
</style>
