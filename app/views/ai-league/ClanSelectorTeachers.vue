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
  <div class="clan-selector">
    <label
      v-if="label"
      for="clans"
    >
      {{ $t('league.view_leaderboards_for_team') }}
    </label>
    <select
      id="clans"
      name="clans"
      :disabled="disabled"
      @change="e => $emit('change', e)"
    >
      <option
        value="global"
        :selected="selected === ''"
      >
        {{ $t('league.global_stats') }}
      </option>
      <option
        v-for="clan in clansSanitized"
        :key="clan._id"
        :value="clan._id"
        :selected="selected === clan._id"
      >
        {{ clan.displayName || clan.name }}
      </option>
    </select>
  </div>
</template>

<style lang="scss" scoped>
.clan-selector {
  display: flex;
  flex-direction: row;
  gap: 10px;
}
</style>