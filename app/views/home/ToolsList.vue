<template>
  <div class="tools-logos">
    <img
      v-for="(item, index) in items"
      :key="index"
      :src="item.image"
      class="tools-logos__img"
    >
  </div>
</template>

<script>
export default {
  name: 'ToolsList',
  data () {
    return {
      items: [
        {
          image: '/images/pages/home-v3/tools-list/logo_1.webp'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_2.webp'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_3.webp'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_4.webp'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_5.webp'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_6.webp'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_7.webp'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_8.webp'
        }
      ]
    }
  }

}
</script>

<style scoped lang="scss">
.tools-logos {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    gap: 30px 30px;
    justify-content: center;
    position: relative;
    margin: 80px auto;

    &__img {
        object-fit: contain;
        max-width: 140px;
        max-height: 70px;
        margin:auto
    }
}
</style>
