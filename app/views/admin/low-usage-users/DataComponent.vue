<template>
  <div class="data">
    <div class="data__headers">
      <div class="header">
        Found on
      </div>
      <div class="header">
        User
      </div>
      <div class="header header__criteria">
        Criterias
      </div>
      <div class="header">
        Licenses used / available
      </div>
      <div class="header">
        Mark done
      </div>
      <div class="header">
        Add action
      </div>
    </div>
    <div
      v-for="user in users"
      :key="user._id"
      class="data-element"
    >
      <data-item-component
        :user="user"
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
  }

  .data-element {
    border: 1px solid darkgray;
    background: #f8f8f8;
    padding: 5px;
  }
}
</style>