<template>
  <div class="explore">
    <page-junior v-if="product === 'junior'" />
    <page-hack-stack v-if="product === 'hackstack'" />
    <page-schools v-else />
  </div>
</template>

<script>
import PageJunior from 'app/views/junior/PageJunior.vue'
import PageSchools from 'app/views/schools/PageSchools.vue'
import PageHackStack from 'app/views/landing-pages/hackstack/PageHackStack.vue'
export default {
  name: 'ExploreComponent',
  components: {
    PageJunior,
    PageSchools,
    PageHackStack,
  },
  props: {
    product: {
      type: String,
      required: true,
    },
  },
}
</script>

<style lang="scss" scoped>
.explore {
  background: #fff;
}
</style>