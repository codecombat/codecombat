<template>
  <div>
    <div class="tec">
      <div class="tec__image">
        <img
          src="/images/pages/payment/tecmilenio-logo.png"
          alt="Tecmilenio logo"
          class="tec__image-img"
        >
      </div>
      <div class="tec__heading">
        ¡Felicidades!
      </div>
      <div class="tec__subheading">
        Su compra está completa.
      </div>
      <div class="tec__info">
        El alumno recibirá más información de su profesor para acceder a la licencia de CodeCombat.
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TecmilenioSuccessView'
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
.tec {
  background: linear-gradient(118.13deg, #0E4C60 0%, #20572B 100%);
  color: #FFFFFF;
  text-align: center;
  padding: 50px;
  margin-bottom: -50px;
  font-size: 62.5%;

  &__heading {
    font-size: 3rem;
    padding: 1rem;
  }

  &__subheading {
    font-size: 2.4rem;
    padding: 1rem;
  }

  &__info {
    font-size: 1.8rem;
    padding: 3rem;
  }

  &__image {
    &-img {
      height: 6rem;
      position: absolute;
      right: 2.5rem;
      top: 10rem;

      border: 1px solid #fff;
      padding: 1rem;

      box-shadow: 0 1px 2px lightgrey;

      @media (max-width: $screen-md-min) {
        position: unset;
        margin-bottom: 1rem;
      }
    }
  }
}
</style>
