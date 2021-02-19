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
    <label for="clans">My Teams:</label>
    <select id="clans" name="clans" @change="e => $emit('change', e)">
      <option value="global" :selected="selected===''">--</option>
      <option  v-for="clan in clansSanitized" :key="clan._id" :value="clan._id" :selected="selected===clan._id">
        {{ clan.displayName || clan.name }}
      </option>
    </select>
  </div>
</template>
