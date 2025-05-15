<template>
  <div class="header">
    <div class="header__products">
      <div
        :class="{ header__product: true, header__product__selected: defaultTab === 'guide' }"
        @click.prevent="() => onTabClicked('guide')"
      >
        {{ displayProductName }}
      </div>
      <div
        :class="{ header__product: true, header__product__selected: defaultTab === 'explore' }"
        @click.prevent="() => onTabClicked('explore')"
      >
        {{ $t('general.learn_more') }}
      </div>
    </div>
    <old-header-component
      v-if="showGuideHeader()"
    />
  </div>
</template>

<script>
import OldHeaderComponent from '../../components/HeaderComponent'
export default {
  name: 'HeaderComponentV2',
  components: {
    OldHeaderComponent,
  },
  props: {
    product: {
      type: String,
      required: true,
    },
    defaultTab: {
      type: String,
      default: 'guide',
    },
  },
  computed: {
    displayProductName () {
      if (this.product === 'codecombat') {
        return 'CodeCombat'
      } else if (this.product === 'ozaria') {
        return 'Ozaria'
      } else if (this.product === 'hackstack') {
        return 'AI HackStack'
      } else if (this.product === 'junior') {
        return 'Junior'
      }
      return this.product
    },
  },
  methods: {
    onTabClicked (tab) {
      this.$emit('onSelectedTabChange', tab)
    },
    showGuideHeader () {
      return this.defaultTab === 'guide'
    },
  },
}
</script>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/views/parents/css-mixins/variables";
@import "app/styles/component_variables.scss";

.header {
  border: 1px solid #E6E6E6;
  box-shadow: inset 0px -2px 10px rgba(0, 0, 0, 0.15);

  &__products {
    display: flex;
    padding-top: 10px;

    @media (max-width: $screen-lg) {
      flex-direction: column;
    }
  }

  &__product {
    background: var(--color-primary-1);
    border: 1px solid var(--color-primary-1);
    box-shadow: 4px 0 7px rgba(0, 0, 0, 0.2), 0px -2px 5px rgba(0, 0, 0, 0.1);
    color: #fff;

    margin-right: 10px;
    margin-left: 10px;

    border-top-left-radius: 5px;
    border-top-right-radius: 5px;

    padding: 5px 15px;
    cursor: pointer;

    &:not(:last-child) {
      @media (max-width: $screen-lg) {
        margin-bottom: 10px;
      }
    }

    &__selected {
      background: $color-grey-2;
      border: 1px solid #E6E6E6;
      color: black;
      font-weight: bold;
    }
  }

  &__logos {
    height: 2rem;
  }
}
</style>
