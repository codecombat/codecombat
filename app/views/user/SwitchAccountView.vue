<template>
  <div>
    <div
      v-if="!loading"
      class="switch"
    >
      Hello
    </div>
    <div
      v-else
      class="loading"
    >
      {{ $t('common.loading') }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'SwitchAccountView',
  data () {
    return {
      loading: true,
      relatedUsers: null
    }
  },
  created () {
    // fetch users based on related
    const related = me.get('related')
    if (!related || related.length === 0) {
      this.loading = false
      // return
    }
  }
}
</script>

<style scoped lang="scss">
.loading {
  text-align: center;
}
</style>
