<template>
  <div class="data">
    <div class="data__headers">
      <div class="header">
        Last Found on
      </div>
      <div class="header header__mid">
        User
      </div>
      <div class="header header__criteria">
        Criterias
      </div>
      <div class="header">
        Licenses <p class="header__sub">
          (used / available)
        </p>
      </div>
      <div class="header">
        Location
      </div>
      <div class="header header__small">
        Mark
      </div>
      <div class="header header__small">
        Actions
      </div>
    </div>
    <div
      v-for="(user, index) in users"
      :key="user._id"
      class="data-element"
    >
      <data-item-component
        :user="user"
        :index="index"
        @mark-done="$emit('mark-done', user.userId)"
        @undo-done="$emit('undo-done', user.userId)"
      />
    </div>
  </div>
</template>

<script>
import DataItemComponent from './DataItemComponent.vue'
export default {
  name: 'DataComponent',
  components: {
    DataItemComponent
  },
  props: {
    users: {
      type: Array,
      default: () => []
    }
  }
}
</script>

<style scoped lang="scss">
.data {
  margin-top: 2rem;

  &__headers {
    display: flex;
    justify-content: space-around;

    & > * {
      width: 14%;
    }
  }
  .header__criteria {
    width: 25%;
  }

  .header {
    font-weight: bold;
    font-size: 1.8rem;
    line-height: 2rem;

    &__sub {
      font-size: 1.2rem;
      line-height: 1.4rem;
    }

    &__small {
      width: 8%;
    }

    &__mid {
      width: 20%;
    }
  }

  .data-element {
    border: 1px solid darkgray;
    background: #f8f8f8;
    padding: 5px;
  }
}
</style>