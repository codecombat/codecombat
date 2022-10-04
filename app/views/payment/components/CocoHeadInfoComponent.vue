<template>
  <span>
    <div class="col-md-3">
      <div class="text-center">
        <img class="info-img" src="/images/pages/home/type_real_code.png" />
      </div>
    </div>
    <div class="col-md-3 info-data">
      <h2 class="info-title">{{ isTecmilenioPartner ? 'Acceso ' : '' }}CodeCombat</h2>
      <ul class="info-list" v-if="isTecmilenioPartner">
        <li>La informática</li>
        <li>Desarrollo web</li>
        <li>Desarrollo de juegos</li>
      </ul>
      <ul class="info-list" v-else>
        <li>Computer Science 1-6</li>
        <li>Web Development 1-2</li>
        <li>Game Development 1-2</li>
      </ul>
    </div>
  </span>
</template>

<script>
export default {
  name: "CocoHeadInfoComponent",
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
