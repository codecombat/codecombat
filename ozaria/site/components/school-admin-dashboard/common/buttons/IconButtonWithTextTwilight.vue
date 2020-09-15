<script>
  export default {
    props: {
      text: {
        type: String,
        default: ''
      },
      iconUrl: {
        type: String,
        default: ''
      },
      link: {
        type: String,
        default: ''
      },
      inactive: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      iconBackground () {
        if (this.iconUrl) {
          return { 'background-image': `url(${this.iconUrl})` }
        } else {
          return {}
        }
      }
    },

    methods: {
      clickButton () {
        if (!this.inactive) {
          this.$emit('click')
          if (this.link) {
            application.router.navigate(this.link, { trigger: true })
          }
        }
      }
    }
  }
</script>

<template>
  <button
    :disabled="inactive"
    @click="clickButton"
  >
    <div
      id="ButtonIcon"
      :style="iconBackground"
    />
    <span> {{ text }} </span>
  </button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#ButtonIcon {
  height: 23px;
  width: 19px;
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center;
  background-size: 100% 100%;
  margin-right: 7px;
}

button {
  background-color: $twilight;
  border-radius: 4px;
  border-width: 0;
  text-shadow: unset;
  font-weight: bold;
  @include font-p-3-small-button-text-black;
  color: $moon;
  font-size: 14px;
  line-height: 16px;
  font-weight: 600;
  background-image: unset;

  &:hover {
    background-color: #355ea0;
    transition: background-color .35s;
  }

  display: flex;
  height: 33px;
  justify-content: center;
  align-items: center;

  &:disabled {
    background: #adadad;
    cursor: default;
    color: $pitch;
  }
}
</style>
