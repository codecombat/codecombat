<template>
  <div
    v-if="isDisplayable"
    v-tooltip.bottom="{
      content: $t(`paywall.badge_tooltip_${level}`),
    }"
    :class="badgeClass"
    @click="handleClick"
  >
    <img
      v-if="displayIcon && icon"
      :src="`/images/common/${icon}.svg`"
      class="icon"
    >
    <span
      v-if="displayText"
      class="badge-text"
    >
      {{ $t(`paywall.badge_${level}`) }}
    </span>
  </div>
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
    courseSlug: {
      type: String,
      default: '',
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
        'only-icon': !this.displayText,
      }
    },
    icon () {
      const icons = {
        free: 'IconFreeLevelv2',
        'sales-call': 'IconUnlockWithCall',
        paid: 'IconPaidLevel',
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
        window.open(`/schools?openContactModal=true&source=sales-call-badge-${this.courseSlug}`, '_blank')
      }
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.badge {
  padding: 5px 15px;
  border-radius: 5px;
  font-size: 14px;
  line-height: 16px;
  height: 35px;

  background-color: var(--color-primary-1);
  color: #fff;

  margin-left: 10px;
  margin-right: 15px;

  display: flex;
  align-items: center;
  justify-content: center;

  &.only-icon {
    padding: 1px;
    height: unset;
    display: inline-block;
  }
}

.badge-sales-call {
  cursor: pointer;
}

.icon {
  height: 23px;
  width: 18px;
}

.badge-text {
  margin-left: 5px;
}
</style>
