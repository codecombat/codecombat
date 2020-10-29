<script>
import BaseModal from 'app/components/common/BaseModal'
import OzariaCTA from 'app/components/teacher/OzariaCTA'
export default Vue.extend({
  data: () => ({
    show: true
  }),
  props: {
    onNext: {
      type: Function,
      default: () => {}
    }
  },
  components: {
    BaseModal,
    OzariaCTA
  },
  methods: {
    next () {
      this.show = false
      this.onNext()
    },
    close () {
      this.show = false
    }
  }
})
</script>

<template>
  <base-modal v-if="show" id="educator-signup-encouragement-modal">
    <template slot="body">
      <div class="content">
        <div class="header">
          <button 
            class="close-button"
            @click="close"
            aria-label="Close"
          >
            <img alt="close icon" src="/images/common/modal/Exit_Dusk.svg" />
          </button>
        </div>
        <div class="modal-contents-container">
          <div class="ozaria-encourage-container">
            <img class="oz-logo" alt="Ozaria logo" src="/images/pages/home/logo_ozaria.png"/>
            <OzariaCTA />
            <a class="primary-oz-button" href="https://www.ozaria.com/sign-up/educator">
              {{ $t('new_home.try_ozaria') }}
            </a>
          </div>
          <div class="codecombat-continue-container">
            <img class="coco-logo" alt="CodeCombat logo" src="/images/pages/base/logo.png">
            <h3>{{ $t('educator_signup_ozaria_encouragement.recommended_for') }}</h3>

            <ul>
              <li>{{ $t('educator_signup_ozaria_encouragement.independent_learners') }}</li>
              <li>{{ $t('educator_signup_ozaria_encouragement.homeschoolers') }}</li>
              <li>{{ $t('educator_signup_ozaria_encouragement.educators_continue_coco') }}</li>
            </ul>

            <button @click="next" class="continue-codecombat">
              {{ $t('educator_signup_ozaria_encouragement.continue_coco') }}
            </button>
          </div>
        </div>
      </div>
    </template>
  </base-modal>
</template>

<style scoped>

#educator-signup-encouragement-modal .content {
  min-height: min(80vh, 600px);
  min-width: min(80vw, 1167px);
}

.close-button {
  border: 0;
  text-transform: none;
  -webkit-appearance: button;
  background: none;
}

.close-button img {
  width: 25px;
  height: 25px;
}

.header {
  width: 100%;
  display: flex;
  flex-direction: row;
  justify-content: end;
  justify-content: flex-end;

  position: absolute;
}

img.oz-logo {
  height: 78.75px;
  width: auto;
  margin-bottom: 35px;
}

img.coco-logo {
  height: 50px;
  width: auto;
}

.modal-contents-container {
  display: flex;
  flex-direction: row;

  /* Without this the flex container won't fill height */
  min-height: inherit;
}

.ozaria-encourage-container {
  flex-shrink: 2;
  flex-grow: 2;
  flex-basis: 2;
  flex: 2;

  background: white;
  background: url(/images/ozaria/modal/encouragement-modal/SpritLandReveal_Gradient.png) left bottom no-repeat, url(/images/ozaria/modal/encouragement-modal/Hero.png) left bottom no-repeat; /* Fallback */
  background: url(/images/ozaria/modal/encouragement-modal/Hero.png) 22px bottom no-repeat, url(/images/ozaria/modal/encouragement-modal/SpritLandReveal_Gradient.png) left bottom no-repeat, linear-gradient(66.45deg, #FFFEF0 15.94%, #FFFDEA 29.45%, #FFF8CF 46.45%, #FDF7D7 76.99%, #FFFCE9 83.48%);

  border-radius: 6px 0 0 6px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
  padding: 40px 0;

}


a.primary-oz-button {
  margin-top: 35px;

  font-family: Open Sans;
  font-style: normal;
  font-weight: bold;
  font-size: 18px;
  line-height: 38px;

  color: black;
  text-transform: capitalize;
  background-color: #1FBAB4;
  border: 0;
  padding: 5px 15px;
  border-radius: 4px;
  text-align: center;

  min-width: 250px;
  min-height: 50px;
}

.codecombat-continue-container {
  flex-shrink: 1;
  flex-grow: 1;
  flex-basis: 1;
  flex: 1;

  background-color: #173F41;
  border-radius: 0 6px 6px 0;

  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.codecombat-continue-container h3 {
  font-family: Open Sans;
  font-style: normal;
  font-variant: normal;
  font-weight: bold;
  font-size: 22px;
  line-height: 30px;
  color: white;
}

.codecombat-continue-container li {
  font-family: Open Sans;
  font-style: normal;
  font-weight: 300;
  font-size: 18px;
  line-height: 25px;
  color: white;

  margin: 10px 0;
}

.codecombat-continue-container ul {
  margin: 10px 0 40px;
}

.codecombat-continue-container button {
  font-family: Open Sans;
  font-style: normal;
  font-weight: bold;
  font-size: 18px;
  line-height: 25px;

  text-align: center;
  color: #1FBAB4;
  background-color: unset;
  border: 1px solid;
  padding: 5px 15px;
  height: 50px;

  text-transform: capitalize;
  border-radius: 4px;
}


#educator-signup-encouragement-modal ::v-deep .modal-container {
  border-radius: 6px;
}

#educator-signup-encouragement-modal ::v-deep .modal-body {
  padding: 0;
}

#educator-signup-encouragement-modal ::v-deep .modal-content {
  border: 0;
}

#educator-signup-encouragement-modal ::v-deep .modal-header {
  display: none;
}

#educator-signup-encouragement-modal ::v-deep .modal-footer {
  display: none;
}



</style>