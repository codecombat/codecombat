<script>
import BaseModal from 'app/components/common/BaseModal'

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
    BaseModal
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
  <base-modal v-if="show" id="get-started-modal">
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

          <button>I'm an educator</button>
          <button>I'm a parent</button>
          <button>I'm a student</button>
          <button>I'm an individual</button>

        </div>
      </div>
    </template>
  </base-modal>
</template>

<style scoped>

#get-started-modal .content {
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

.modal-contents-container {
  display: flex;
  flex-direction: row;

  /* Without this the flex container won't fill height */
  min-height: inherit;
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


#get-started-modal ::v-deep .modal-container {
  border-radius: 6px;
}

#get-started-modal ::v-deep .modal-body {
  padding: 0;
}

#get-started-modal ::v-deep .modal-content {
  border: 0;
}

#get-started-modal ::v-deep .modal-header {
  display: none;
}

#get-started-modal ::v-deep .modal-footer {
  display: none;
}

</style>
