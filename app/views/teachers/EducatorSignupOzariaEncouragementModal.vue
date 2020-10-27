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
            <h2>Ozaria</h2>
            <button>Try Ozari</button>
          </div>
          <div class="codecombat-continue-container">
            <img class="coco-logo" alt="CodeCombat logo" src="/images/pages/base/logo.png">
            <h3>Recommended for:</h3>

            <ul>
              <li>Independent learners</li>
              <li>Homeschoolers</li>
              <li>Educators who want to continue using CodeCombat in their class</li>
            </ul>

            <button class="continue-codecombat">Continue with CodeCombat</button>
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

  background-color: yellow;
  border-radius: 6px 0 0 6px;

  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
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