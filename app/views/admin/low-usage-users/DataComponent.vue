<template>
  <div class="data">
    <div class="data__headers">
      <div class="header">
        Last Found on
      </div>
      <div class="header">
        User
      </div>
      <div class="header header__criteria">
        Criterias
      </div>
      <div class="header">
        Licenses <span class="header__sub">(used / available)</span>
      </div>
      <div class="header">
        Mark done
      </div>
      <div class="header">
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

    &__sub {
      font-size: 1.1rem;
    }
  }

  .data-element {
    border: 1px solid darkgray;
    background: #f8f8f8;
    padding: 5px;
  }
}
</style>