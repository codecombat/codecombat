
<script>
import LayoutCenterContent from '../../common/LayoutCenterContent.vue'
import LayoutAspectRatioContainer from '../../common/LayoutAspectRatioContainer.vue'
import LayoutChrome from '../../common/LayoutChrome.vue'
import Surface from '../../char-customization/common/Surface.vue';
import BaseButton from '../../common/BaseButton.vue';

export default Vue.extend({
  components: {
    LayoutChrome,
    LayoutCenterContent,
    LayoutAspectRatioContainer,
    BaseButton,
    Surface
  },
  
  data: () => ({
    selected: -1
  }),

  methods: {
    handleClick (e) {
      const selectedAvatar = parseInt(e.target.dataset.avatar, 10)
      this.selected = selectedAvatar
    },

    async handleNext () {
      await Promise.resolve() // TODO: Handle saving avatar selection state.

      // Notify intro to move along.
      this.$emit('completed')
    }
  }
})
</script>

<template>

  <layout-chrome>
    <layout-center-content>
      <layout-aspect-ratio-container
        :aspectRatio="1266 / 668"
      >
      <div class="avatar-selector container-fluid">
        <div id="row">
          <div class="col-xs-12 header">
            <h1>Pick an avatar that will represent you as a player:</h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-8 avatar-grid">

            <section class="row">

              <div class="col-xs-4 avatar-item">
                <div class="avatar2" :class="{selected: selected === 1}" data-avatar="1" @click="handleClick" />
              </div>

              <div class="col-xs-4 avatar-item">
                <div class="avatar1" :class="{selected: selected === 2}" data-avatar="2" @click="handleClick" />
              </div>

              <div class="col-xs-4 avatar-item">
                <div class="avatar3" :class="{selected: selected === 3}" data-avatar="3" @click="handleClick" />
              </div>

            </section>

            <section class="row">

              <div class="col-xs-4 avatar-item">
                <div class="avatar3" :class="{selected: selected === 4}" data-avatar="4" @click="handleClick" />
              </div>

              <div class="col-xs-4 avatar-item">
                <div class="avatar2" :class="{selected: selected === 5}" data-avatar="5" @click="handleClick" />
              </div>

              <div class="col-xs-4 avatar-item">
                <div class="avatar1" :class="{selected: selected === 6}" data-avatar="6" @click="handleClick" />
              </div>

            </section>

          </div>
          <div class="col-xs-4 surface">
            <Surface :width="200" :height="360" />
          </div>
        </div>

        <div class="row">
          <div class="col-xs-12 footer">
            <base-button
              :enabled="selected !== -1"
              @click="handleNext"
            >
              Next
            </base-button>
          </div>
        </div>
      </div>

      </layout-aspect-ratio-container>
    </layout-center-content>
  </layout-chrome>

</template>

<style lang="scss" scoped>

.header h1 {
  margin-top: 0;
}

.avatar-selector {
  background-color: white;
  height: 100%;
  padding: 30px 60px;

  display: flex;

  flex-direction: column;
  justify-content: space-between;

}

.avatar-item {
  div {
    min-height: 120px;

    margin: 0 7px;
    border-radius: 10px;
    border: 1px solid #ccc;
    box-shadow: inset 0px 0px 5px #ddd;

    &.selected {
      border: 1px solid #4A90E2;
      box-shadow: inset 0px 0px 6px rgb(71, 136, 211);
    }
  }

  .avatar1 {
    background-image: url(/images/ozaria/avatar-selector/circle.png)
  }
  .avatar2 {
    background-image: url(/images/ozaria/avatar-selector/hex.png)
  }
  .avatar3 {
    background-image: url(/images/ozaria/avatar-selector/square.png)
  }

  & > div {
    background-position: center;
    background-size: auto 80%;
    background-repeat: no-repeat;
  }
}

.avatar-grid .row {
  margin: 40px 0;
}

.surface {
  text-align: center;
}

.footer {
  text-align: right;
}

</style>
