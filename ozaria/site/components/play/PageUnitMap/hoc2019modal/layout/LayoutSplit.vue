<script>
export default {
  props: {
    showBackButton: {
      default: true,
      type: Boolean
    }
  }
}
</script>

<template>
  <div class="flex-container">
    <div class="left-side">
      <div class="back-row">
        <a v-if="showBackButton" @click="() => $emit('back')">
          <img class="back-arrow" src="/images/pages/modal/hoc2019/BackArrow_Dusk.png"/>
          <span class="back-text">Back</span>
        </a>
      </div>
      <div class="ozaria-header">
        <img src="/images/pages/modal/hoc2019/whiteOzariaWordmark.png" />
        <h3>{{ $t('hoc_2019.heading') }}</h3>
        <div class="yellow-bar"></div>
      </div>
      <img class="spirit-lands" src="/images/pages/modal/hoc2019/SpiritLandReveal.png" />
      <slot name="aside"></slot>
      <div class="flex-spacer"></div>
    </div>
    <div class="right-side">
      <slot></slot>
    </div>
  </div>
</template>


<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.yellow-bar {
  position: relative;
  height: 6.4px;
}

.yellow-bar:after {
  content: "";
  position: absolute;
	height: 245px;
	width: 6.4px;
	transform: rotate(90deg) translate(-122.5px, -122.5px);
	background: linear-gradient(59.61deg, #D1B147 0%, #D1B147 20%, #F7D047 90.4%, #F7D047 100%);
}

.flex-container {
  display: flex;
  flex-direction: row;
  height: 100%;

  border-radius: 25px;
  box-shadow: -20px -10px 50px 0 rgba(64,243,228,0.3), 20px 10px 50px 0 rgba(64,243,228,0.3);
}

.left-side {
  background-color: $pitch;
  width: 368px;

  border-radius: 25px 0 0 25px;

  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  flex: 1;

  .back-row {
    display: flex;
    align-items: center;

    width: 100%;
    padding-left: 21px;
    margin-top: 20px;

    a {
      text-decoration: none;
      &:hover {
        text-decoration: none;
      }
    }

    img.back-arrow {
      width: 9px;
      height: 16px;
    }

    span.back-text {
      font-family: Work Sans;
      font-size: 16px;
      line-height: 20px;
      letter-spacing: 0.27px;
      color: $teal;
      margin-left: 7px;
    }
  }

  .ozaria-header {
    height: 125px;
    img {
      width: 245px;
    }

  }

  h3 {
    font-family: Work Sans;
    color: white;
    font-size: 26.4px;
    font-weight: bold;
    line-height: 44px;
    letter-spacing: 0.48px;
    font-variant: normal;
    margin: 0;
    text-align: center;
  }

  img.spirit-lands {
    width: 137px;
    height: 137px;
  }

  .flex-spacer {
    height: 30px;
  }
}

.right-side {
  background-color: white; // fallback
  background-color: rgba(255,255,255,0.95);
  border-radius: 0 25px 25px 0;
  flex: 1;
}

</style>
