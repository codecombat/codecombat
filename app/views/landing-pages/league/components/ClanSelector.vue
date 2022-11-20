<script>
export default {
  props: {
    clans: {
      type: Array,
      required: false,
      default: () => ([])
    },

    selected: {
      type: String,
      required: false,
      default: ''
    },

    label: {
      type: Boolean,
      default: () => true
    },
    disabled: {
      type: Boolean,
      default: () => false
    }
  },

  computed: {
    clansSanitized () {
      return this.clans.filter(v => v !== undefined)
    }
  }
}
</script>

<template>
  <div>
    <label
      v-if="label"
      for="clans"
    >
      {{ $t('tournament.my_teams') }}
    </label>
    <select
      id="clans"
      name="clans"
      :disabled="disabled"
      @change="e => $emit('change', e)"
    >
      <option value="global" :selected="selected===''">--</option>
      <option  v-for="clan in clansSanitized" :key="clan._id" :value="clan._id" :selected="selected===clan._id">
        {{ clan.displayName || clan.name }}
      </option>
    </select>
  </div>
</template>
