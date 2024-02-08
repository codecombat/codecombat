<template>
  <div class="tools-logos">
    <img
      v-for="(item, index) in items"
      :key="index"
      :src="item.image"
      class="tools-logos__img"
      :alt="item.alt"
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
          image: '/images/pages/home-v3/tools-list/logo_1.webp',
          alt: 'Python logo'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_2.webp',
          alt: 'JavaScript logo'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_3.webp',
          alt: 'HTML logo'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_4.webp',
          alt: 'CSS logo'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_5.webp',
          alt: 'C++ logo'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_6.webp',
          alt: 'ChatGPT logo'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_7.webp',
          alt: 'Stable Diffusion logo'
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_8.webp',
          alt: 'DALL-E logo'
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
