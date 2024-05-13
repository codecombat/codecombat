<template>
  <div class="page-template">
    <div class="template__image template__image--1">
      <img
        src="/images/pages/parents/personal_learning_3.png"
        alt="Personal learning image"
        class="template__img img-responsive"
      >
    </div>
    <slot />
    <div class="template__image template__image--2">
      <img
        src="/images/pages/home-v2/loc-image.png"
        alt="Girl playing CodeCombat"
        class="template__img img-responsive"
      >
    </div>
  </div>
</template>

<script>
export default {
  name: 'PageTemplate',
}
</script>

<style scoped lang="scss">
.page-template{
  background: linear-gradient(66.45deg, #FFFEF0 15.94%, #FFFDEA 29.45%, #FFF8CF 46.45%, #FDF7D7 76.99%, #FFFCE9 83.48%);
  border-radius: 20px;
  //transform: matrix(-1, 0, 0, 1, 0, 0);

  height: 100vh;
  position: relative;

  display: flex;
  align-items: center;
  justify-content: center;

  margin-bottom: -50px;
}

.template {
  &__image {
    position: absolute;

    &--1 {
      top: 5%;
      left: 2%;
    }

    &--2 {
      bottom: 5%;
      right: 2%;
    }
  }
  &__img {
    height: 30vh;
  }
}
</style>
