<script>
import BaseModal from 'app/components/common/BaseModal'
export default Vue.extend({
  data: () => ({
    show: true
  }),
  props: {
    onClose: {
      type: Function,
      default: () => {}
    }
  },
  components: {
    BaseModal
  },
  methods: {
    close () {
      this.show = false
      this.onClose()
    },
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
            <div class="ozaria-row">
              <img src="/images/ozaria/modal/encouragement-modal/Icon_StandardsAlignment.svg" />
              <div>
                <h4>Standards Aligned Core Curriculum</h4>
                <p>Immersive, story based curriculum that meets all 6th-8th grade CSTA standards.</p>
              </div>
            </div>
            <div class="ozaria-row">
              <img src="/images/ozaria/modal/encouragement-modal/Icon_Turnkey.svg" />
              <div>
                <h4>Turnkey Lesson Plans</h4>
                <p>In-depth presentations and worksheets for teachers to guide students through learning objectives.</p>
              </div>
            </div>
            <div class="ozaria-row">
              <img src="/images/ozaria/modal/encouragement-modal/Icon_NewTeacherDashboard.svg" />
              <div>
                <h4>Turnkey Lesson Plans</h4>
                <p>All the actionable insights educators need at a glance, such as student progress and concept understanding.</p>
              </div>
            </div>
            <a class="primary-oz-button" href="https://www.ozaria.com/sign-up/educator">Try Ozaria</a>
          </div>
          <div class="codecombat-continue-container">
            <img class="coco-logo" alt="CodeCombat logo" src="/images/pages/base/logo.png">
            <h3>Recommended for:</h3>

            <ul>
              <li>Independent learners</li>
              <li>Homeschoolers</li>
              <li>Educators who want to continue using CodeCombat in their class</li>
            </ul>

            <button @click="close" class="continue-codecombat">Continue with CodeCombat</button>
          </div>
        </div>
      </div>
    </template>
  </base-modal>
</template>

<style scoped>

#educator-signup-encouragement-modal .content {
  min-height: min(80vh, 661px);
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
  margin-bottom: 40px;
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
  padding: 25px 0;

}

.ozaria-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  width: 90%;
  max-width: 520px;
}

.ozaria-row img {
  width: 80px;
  height: 80px;
  margin-right: 30px;
}

.ozaria-row p {
  font-family: Open Sans;
  font-style: normal;
  font-weight: 300;
  font-size: 18px;
  line-height: 25px;
  color: #232323;
}

.ozaria-row h4 {
  font-family: Open Sans;
  font-style: normal;
  font-weight: bold;
  font-size: 24px;
  line-height: 33px;
  color: black;
}

a.primary-oz-button {
  margin-top: 40px;

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
  font-family: Arvo;
  font-style: normal;
  font-weight: bold;
  font-size: 24px;
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