<template>
  <div class="flex">
    <div class="attendance-row title">
      <div class="attendance">
        {{ $t('events.attendance') }}
      </div>
      <div class="name">
        {{ $t('events.name') }}
      </div>
      <div class="description">
        {{ $t('events.course_description') }}
      </div>
    </div>
    <div
      v-for="m in members"
      :key="m.userId"
      class="attendance-row"
    >
      <input
        class="attendance"
        :checked="m.attendance"
        @input="select(m.userId)"
        type="checkbox"
      >
      <div class="name">
        {{ m.name }}
      </div>
      <input
        class="description"
        :disabled="!m.attendance"
        :value="m.description"
        @input="debouncedUpdateDescription(m.userId, $event.target.value)"
        name="m"
        type="text"
      >
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
export default {
  name: 'MembersAttendees',
  components: {
  },
  props: {
    instance: {
      type: Object,
      default () { return {} }
    },
    members: {
      type: Object,
      default () { return {} }
    }
  },
  computed: {
    debouncedUpdateDescription () {
      return _.debounce(this.addDescription, 500)
    }
  },
  methods: {
    select (id) {
      this.$emit('toggle-select', id)
    },
    addDescription (id, value) {
      console.log('add description', id, value)
      this.$emit('update-description', { id, value })
    }
  }
}
</script>

<style scoped lang="scss">
.attendance-row {
  display: flex;
  align-items: center;

  .attendance {
    flex-basis: 20%;
  }
  .name {
    flex-basis: 30%;
  }
  .description {
    flex-basis: 45%;
  }
}
</style>
