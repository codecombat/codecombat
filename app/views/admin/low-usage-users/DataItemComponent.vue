<template>
  <div
    class="item"
  >
    <div class="item__date">
      {{ index + 1 }}.  {{ foundOnString(user) }}
    </div>
    <div class="item__user">
      {{ user.email || user.userId }}
    </div>
    <div class="item__criterias">
      {{ user.criterias.join(', ') }}
    </div>
    <div class="item__licenses">
      {{ licensesString(user.licenseInfo) }}
    </div>
    <div class="item__done">
      <button
        v-if="!isUserMarkedDone(user)"
        class="btn btn-success"
        @click="$emit('mark-done', user.userId)"
      >
        Mark done
      </button>
      <button
        v-else
        class="btn btn-warning"
        @click="$emit('undo-done', user.userId)"
      >
        Undo done
      </button>
    </div>
    <div class="item__actions">
      TBD
    </div>
  </div>
</template>

<script>
import { isMarkedDone } from './low-usage-users-helper'
export default {
  name: 'DataItemComponent',
  props: {
    user: {
      type: Object,
      default: () => {}
    },
    index: {
      type: Number,
      default: 0
    }
  },
  methods: {
    dateString (date) {
      return new Date(date).toLocaleString()
    },
    licensesString (licenseInfo) {
      return `${licenseInfo?.redeemers} / ${licenseInfo?.maxRedeemers}`
    },
    isUserMarkedDone (user) {
      return isMarkedDone(user)
    },
    foundOnString (user) {
      return this.dateString(user.logs[0].date)
    }
  }
}
</script>

<style scoped lang="scss">
.item {
  display: flex;
  justify-content: space-around;
  align-items: center;

  font-size: 1.3rem;

  & > * {
    width: 14%;
  }

  &__criterias {
    width: 25%;
  }
}
</style>
