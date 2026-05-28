<template>
  <div class="container">
    <div class="title">
      {{ $t('payments.manage_payment_and_subscription') }}
    </div>
    <CustomerBillingPortal />
    <DiscoverMore />
  </div>
</template>

<script>
import DiscoverMore from './DiscoverMore'
import CustomerBillingPortal from './CustomerBillingPortal'
export default {
  name: 'NewManageBillingView',
  components: {
    DiscoverMore,
    CustomerBillingPortal,
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";
.title {
  font-size: 36px;
  line-height: 42px;
  color: $dark-grey;
  font-weight: 800;
}
.container {
  display: grid;
  gap: 50px;
}
</style>