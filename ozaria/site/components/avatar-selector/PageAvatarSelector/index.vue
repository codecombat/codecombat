
<script>
import LayoutCenterContent from '../../common/LayoutCenterContent.vue'
import LayoutAspectRatioContainer from '../../common/LayoutAspectRatioContainer.vue'
import LayoutChrome from '../../common/LayoutChrome.vue'
import Surface from '../../char-customization/common/Surface.vue';


export default Vue.extend({
  components: {
    LayoutChrome,
    LayoutCenterContent,
    LayoutAspectRatioContainer,
  }
})
</script>

<template>

  <layout-chrome>
    <layout-center-content>
      <layout-aspect-ratio-container
        :aspectRatio="1266 / 668"
      >
      <div id="avatar-selector">
        <div id="header">
          <h1>Pick an avatar that will represent you as a player:</h1>
        </div>
        <div class="content">
          <div class="avatar-grid">
            <section class="avatar-row">
              <div class="avatar-item avatar1" />
              <div class="avatar-item avatar2" />
              <div class="avatar-item avatar3" />
            </section>
            <section class="avatar-row">
              <div class="avatar-item avatar1" />
              <div class="avatar-item avatar2" />
              <div class="avatar-item avatar3" />
            </section>
          </div>
          <div class="selected-avatar">
            <Surface />
          </div>
        </div>
      </div>

      </layout-aspect-ratio-container>
    </layout-center-content>
  </layout-chrome>

</template>

<style lang="scss" scoped>

#header h1 {
  margin-top: 0;
}

#avatar-selector {
  background-color: white;
  height: 100%;
  position: relative;

  .content {
    display: flex;
  }
  .avatar-grid {
    position: absolute;

    display: flex;
    flex-direction: column;
    justify-content: space-evenly;

    .avatar-row {
      flex: 1;

      display: flex;

      min-height: 50%;

      .avatar-item {
        flex: 1;

        min-width: 100px;
        min-height: 100px;

        &.avatar1 {
          background-image: url(/images/ozaria/avatar-selector/circle.png)
        }
        &.avatar2 {
          background-image: url(/images/ozaria/avatar-selector/hex.png)
        }
        &.avatar3 {
          background-image: url(/images/ozaria/avatar-selector/square.png)
        }
        background-position: center;
        background-size: contain;
        background-repeat: no-repeat;
      }
    }
  }
  .selected-avatar {
    flex-grow: 1;
    flex-shrink: 1;
  }
}

</style>
