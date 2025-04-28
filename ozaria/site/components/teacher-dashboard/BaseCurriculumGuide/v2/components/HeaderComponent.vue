<template>
  <div class="header">
    <div class="header__products">
      <div
        :class="{ header__product: true, header__product__selected: selectedTab === 'guide' }"
        @click.prevent="() => onTabClicked('guide')"
      >
        {{ product }}
      </div>
      <div
        :class="{ header__product: true, header__product__selected: selectedTab === 'explore' }"
        @click.prevent="() => onTabClicked('explore')"
      >
        {{ $t('parents_v2.step_box_2_subtitle') }}
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HeaderComponent',
  props: {
    product: {
      type: String,
      required: true,
    },
    defaultTab: {
      type: String,
      default: 'guide',
      required: true,
    },
  },
  data () {
    return {
      selectedTab: this.defaultTab,
    }
  },
  methods: {
    onTabClicked (tab) {
      this.selectedTab = tab
      this.$emit('onSelectedTabChange', tab)
    },
  },
}
</script>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/views/parents/css-mixins/variables";

.header {
  &__products {
    display: flex;
    padding-top: .5rem;

    @media (max-width: $screen-lg) {
      flex-direction: column;
    }
  }

  &__product {
    background: $color-green-1;
    border: 1px solid $color-green-1;
    box-shadow: 4px 0 7px rgba(0, 0, 0, 0.2), 0px -2px 5px rgba(0, 0, 0, 0.1);

    margin-left: 1rem;
    margin-right: 1rem;

    border-top-left-radius: 5px;
    border-top-right-radius: 5px;

    padding: 2px 1rem;
    cursor: pointer;

    text-transform: uppercase;

    &:not(:last-child) {
      @media (max-width: $screen-lg) {
        margin-bottom: 1rem;
      }
    }

    &__selected {
      background: $color-grey-2;
      border: 1px solid #E6E6E6;
    }
  }

  &__logos {
    height: 2rem;
  }
}
</style>
