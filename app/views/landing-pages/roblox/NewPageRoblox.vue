<template>
  <div class="page">
    <header-component />
    <AccountLinkingRewards />
    <CommunityLoves />
    <PCConRoblox />
    <AccessGuidebook />
    <FaqComponent />
  </div>
</template>

<script>
import Header from './components/Header.vue'
import AccountLinkingRewards from './components/AccountLinkingRewards.vue'
import CommunityLoves from './components/CommunityLoves.vue'
import PCConRoblox from './components/PCConRoblox.vue'
import AccessGuidebook from './components/AccessGuidebook.vue'
import FaqComponent from './components/FaqComponent.vue'

export default {
  components: {
    'header-component': Header,
    AccountLinkingRewards,
    CommunityLoves,
    PCConRoblox,
    AccessGuidebook,
    FaqComponent
  }
}
</script>

<style scoped lang="scss">
$primary-color: #4DECF0;
$primary-background: #31636F;
::v-deep * {
  font-family: Plus Jakarta Sans;
}
::v-deep div{
  color: white;

  &.heading {
    color: $primary-color;
  }
}
::v-deep p {
  color: white;
  &.description {
    color:  #B4B4B4;
  }
}
::v-deep .CTA {
  $black: #0A2239;

  &__button {
    color: $black !important;
    background-color: $primary-color;
    text-shadow: unset !important;
    font-weight: bold;

    &:hover {
      background-color: lighten($primary-color, 10%);

      [style*="--type: no-background"] & {
        background-color: rgba($primary-color, 0.3)
      }
    }

  }
}
</style>