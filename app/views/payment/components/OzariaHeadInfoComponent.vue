<template>
  <span>
    <div class="col-md-3">
      <div class="text-center">
        <img
          class="info-img"
          src="/images/pages/home/ozaria_acodus.png"
        >
      </div>
    </div>
    <div class="col-md-3 info-data">
      <h2 class="info-title">{{ isTecmilenioPartner ? 'Acceso ' : '' }}Ozaria</h2>
      <ul
        v-if="isTecmilenioPartner"
        class="info-list"
      >
        <li>Introducción integral a informática</li>
      </ul>
      <ul
        v-else
        class="info-list"
      >
        <li>Comprehensive Introduction to Computer Science</li>
        <li>Chapters 1-4</li>
      </ul>
    </div>
  </span>
</template>

<script>
export default {
  name: 'OzariaHeadInfoComponent',
  props: {
    isTecmilenioPartner: {
      type: Boolean,
      default: false
    }
  }
}
</script>

<style scoped lang="scss">
@import "head-info";
</style>
