<template>
  <div class="flex">
    <select
      id="tzSelect"
      v-model="_tz"
      class="form-select form-control"
    >
      <option
        v-for="tz in timezones"
        :key="tz.tzCode"
        :value="tz.tzCode"
        :selected="tz.tzCode === _tz"
      >
        {{ tz.label }}
      </option>
    </select>
  </div>
</template>

<script>
import { minimalTimezoneSet } from 'compact-timezone-list'

export default {
  name: 'TimezoneSelect',
  props: {
    tz: {
      type: String,
      default: 'America/New_York' // Eastern Time
    }
  },
  data () {
    return {
      timezones: minimalTimezoneSet
    }
  },
  computed: {
    _tz: {
      get () {
        return this.tz
      },
      set (val) {
        this.$emit('select', val)
      }
    }
  }
}
</script>
