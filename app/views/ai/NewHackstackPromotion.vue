/* eslint-disable-line vue/vue-no-html */
<template>
  <Modal
    :backbone-dismiss-modal="true"
  >
    <HackstackPromotionComponent />
  </Modal>
</template>

<script>
import Modal from 'app/components/common/Modal.vue'
import HackstackPromotionComponent from './HackstackPromotionComponent'
export default Vue.extend({
  name: 'HackstackPromotionModal',
  components: {
    Modal,
    HackstackPromotionComponent,
  },
})
</script>

<style scoped lang="scss">
.hackstack-modal {
  width: 800px;
  .body {
    font-size: 16px;

    .points {
      li {
        font-weight: bold;
      }
    }
  }
  .body .container {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    padding: 5px;
  }

  .body .text {
    flex: 1 1 0px;
  }

  .text, .image {
    padding: 5px;
    margin: 10px;
  }

  .text {
    text-align: center;
    font-weight: 300;
  }

  .image {
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-bottom: 60px;
    position: relative;
  }

  .promo-img {
    max-width: 100%;
    height: auto;
  }

  .banner-img {
    width: 300px;
    position: absolute;
    bottom: -30px;
  }

  .center {
    display: flex;
    justify-content: center;
  }

  .header {
    font-weight: bold;
  }

  .free-btn {
    text-transform: uppercase;
  }

}
</style>
