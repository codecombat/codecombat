<script>
  import BaseModal from 'app/components/common/BaseModal'

  export default {
    components: {
      BaseModal
    },

    props: {
      show: {
        type: Boolean,
        default: false
      },
    },

    methods: {
      handleBackToCoco () {
        this.$emit('close')
        application.router.navigate('/', { trigger: true })
      }
    }
  }
</script>

<template>
  <base-modal :class="[ !show ? 'hide' : undefined, 'timetap-confirmed']">
    <template slot="header">
      <div />
      <button 
        class="close-button"
        @click="$emit('close')"
        aria-label="Close"
      >
        <img alt="close icon" src="/images/common/modal/Exit_Dusk.svg" />
      </button>
    </template>

    <template slot="body">
      <img class="coco-logo" alt="CodeCombat logo" src="/images/pages/base/logo.png">
      <h3>{{ $t('modal_timetap_confirmation.congratulations') }}</h3>
      <div class="blue-line" />
      
      <div>
        <p>{{ $t('modal_timetap_confirmation.paragraph_1') }}</p>
        <p>{{ $t('modal_timetap_confirmation.paragraph_2') }}</p>
        <p>{{ $t('modal_timetap_confirmation.paragraph_3') }}</p>
        <p>{{ $t('modal_timetap_confirmation.paragraph_4') }}</p>
        <p>{{ $t('modal_timetap_confirmation.paragraph_5') }}</p>
      </div>

      <button
        @click="handleBackToCoco"
        class='back-to-coco'
      >
        {{ $t('modal_timetap_confirmation.back_to_coco') }}
      </button>
    </template>
  </base-modal>
</template>

<style scoped>

/* Experiment to keep modal on screen with small width */
@media (max-height: 550px) {
  .timetap-confirmed ::v-deep .modal-container {
    position: fixed !important;
    /* Prevent modal from going off top of screen on smaller devices */
    top: 0;
    bottom: 0;
    overflow-y: scroll;
    overflow-x: hidden;
  }

  .timetap-confirmed ::v-deep .modal-content {
    height: unset;
  }
}

.timetap-confirmed ::v-deep .modal-content {
  background: white;
  background: url(/images/pages/parents/cheering-warriors-group-autumn-pose.png) left 30px bottom 5px no-repeat,
    url(/images/pages/parents/anya.png) right 30px bottom 12px no-repeat;
}

.timetap-confirmed ::v-deep .modal-container {
  border-radius: 10px;
  width: min(1140px, 90vw);
}

.timetap-confirmed ::v-deep .modal-header {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
}

.timetap-confirmed ::v-deep .modal-body {
  display: flex;
  flex-direction: column;
  justify-content: space-around;

  padding: 0 50px;
}

.timetap-confirmed ::v-deep .modal-body > * {
  max-width: 757px;
}


.close-button {
  border: 0;
  text-transform: none;
  -webkit-appearance: button;
  background: none;

  padding: 0;
  width: 25px;
  height: 25px;
}

.close-button:hover {
  background: white;
}

.close-button img {
  width: 25px;
  height: 25px;
}

.blue-line {
  max-width: 456px;
  width: min(456px, 70vw);
  margin: 20px 0 32px;
  border: 2px solid #1fbab4;
}

h3 {
  margin-top: 20px;

  font-family: Open Sans;
  font-style: normal;
  font-weight: bold;
  font-size: 24px;
  line-height: 33px;

  color: #0E4C60;
}

p {
  text-align: left;

  font-family: Open Sans;
  font-style: normal;
  font-weight: 300;
  font-size: 18px;
  line-height: 25px;
  display: flex;
  align-items: center;

  color: #0E4C60;
}

.coco-logo {
  height: 50px;
}

button.back-to-coco {
  margin-top: 60px;

  background: white;
  border: 2px solid #1FBAB4;
  color: #1FBAB4;
  border-radius: 4px;
  min-width: 270px;
  min-height: 50px;
}

button.back-to-coco:hover {
  background: white;
  border: 2px solid #0FAAA4;
  color: #0FAAA4;
}

</style>