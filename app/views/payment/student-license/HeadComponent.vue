<template>
  <div class="container-fluid text-center p-t-2">
    <div class="container">
      <div class="top-section">
        <div class="heading-row">
          <img
            v-if="isTecmilenioPartner"
            src="/images/pages/payment/tecmilenio-logo.png" alt="Tecmilenio logo"
            class="tecmilenio-heading-img"
          >
          <h1 v-if="!isTecmilenioPartner">{{ title || $t(`payments.${this.i18nHeadingName}`)}}</h1>
          <h1 class="tecmilenio-heading-txt" v-else>Licencias de Estudiantes</h1>
          <p class="dsh-info" v-if="isDshPartner"><b>Digital Schoolhouse</b> has partnered with CodeCombat to offer the entirety of the Ozaria story-based computer science adventure game (all 4 Chapters, and over 70 hours of comprehensive instruction) as well as our original game CodeCombat (11 courses spanning Computer Science, Game Development and Web Development) for the <b>discounted rate of $25 USD per annual license (normally $30 USD)</b>. Happy coding!</p>
          <div class="tecmilenio-info" v-else-if="isTecmilenioPartner">
            <p class="tecmilenio-info-txt">
              Tecmilenio se asoció con CodeCombat para ofrecer educación en programación en Python, basada en juegos, por el precio con descuento de $12.52 USD. Todos los estudiantes de Tecmilenio que reciban este enlace deberán comprar el software CodeCombat.
            </p>
            <p class="tecmilenio-info-txt">
              En la siguiente página, se le pedirá que ingrese el correo del estudiante de Tecmilenio. Ejemplo: al02962166@tecmilenio.mx. Asegúrese de que esta información sea correcta, ya que nos permite saber que el estudiante ha pagado por su licencia el estudiante.
            </p>
          </div>
          <h5 v-if="!isTecmilenioPartner">{{ subTitle || $t('payments.great_courses')}}</h5>
          <h5 v-else>La licencia del estudiante incluye:</h5>
        </div>
        <div class="row info-row">
          <template v-if="isDshPartner">
            <ozaria-head-info-component />
            <coco-head-info-component />
          </template>
          <template v-else-if="isTecmilenioPartner">
            <ozaria-head-info-component
              :is-tecmilenio-partner="isTecmilenioPartner"
            />
            <coco-head-info-component
              :is-tecmilenio-partner="isTecmilenioPartner"
            />
          </template>
          <template v-else>
            <coco-head-info-component />
            <ozaria-head-info-component />
          </template>

        </div>
      </div>
    </div>
  </div>
</template>

<script>
import CocoHeadInfoComponent from '../components/CocoHeadInfoComponent'
import OzariaHeadInfoComponent from '../components/OzariaHeadInfoComponent'
export default {
  name: "PaymentStudentLicenseHeadComponent",
  components: {
    CocoHeadInfoComponent,
    OzariaHeadInfoComponent
  },
  props: {
    i18nHeadingName: String,
    title: String,
    subTitle: String,
    isDshPartner: {
      type: Boolean,
      default: false
    },
    isTecmilenioPartner: {
      type: Boolean,
      default: false
    }
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";

.container-fluid {
  background: linear-gradient(118.13deg, #0E4C60 0%, #20572B 100%);
  color: white;

  position: relative;
}

.top-section {
  padding: 20px 20px 50px;

  h1, h3, h5 {
    font-weight: bold;
    color: white;
  }

  .info-row {
    padding: 20px 5px 5px;
  }
}
.dsh-info {
  color: white;
  font-size: small;
}

.tecmilenio-info {
  &-txt {
    color: white;
    font-size: small;
  }
}

.tecmilenio-heading-img {
  height: 60px;
  position: absolute;
  right: 25px;
  top: 25px;

  border: 1px solid #fff;
  padding: 10px;

  box-shadow: 0 1px 2px lightgrey;

  @media (max-width: $screen-md-min) {
    position: unset;
  }
}
</style>
