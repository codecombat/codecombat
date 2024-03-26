<template>
  <div
    class="item"
  >
    <div class="item__date">
      {{ dateString(user.updatedAt) }}
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
      <button class="btn btn-success">
        Mark done
      </button>
    </div>
    <div class="item__actions">
      TBD
    </div>
  </div>
</template>

<script>
export default {
  name: 'DataItemComponent',
  props: {
    user: {
      type: Object,
      default: () => {}
    }
  },
  methods: {
    dateString (date) {
      return new Date(date).toLocaleString()
    },
    licensesString (licenseInfo) {
      return `${licenseInfo?.redeemers} / ${licenseInfo?.maxRedeemers}`
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