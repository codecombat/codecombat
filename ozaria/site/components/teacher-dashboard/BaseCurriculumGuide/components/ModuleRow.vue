<script>
  import ContentIcon from '../../common/icons/ContentIcon'
  import { mapGetters } from 'vuex'
  import { getGameContentDisplayType } from 'ozaria/site/common/ozariaUtils.js'

  export default {
    components: {
      ContentIcon
    },

    props: {
      iconType: {
        type: String,
        required: true,
        validator: value => ['cutscene', 'cinematic', 'capstone', 'interactive', 'practicelvl', 'challengelvl'].indexOf(value) !== -1
      },

      displayName: {
        type: String,
        required: true
      },

      description: {
        type: String,
        required: false,
        default: ''
      },

      isPartOfIntro: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      ...mapGetters({
        isOnLockedCampaign: 'baseCurriculumGuide/isOnLockedCampaign'
      }),

      moduleRowClass () {
        return {
          locked: this.isOnLockedCampaign,
          'part-of-intro': this.isPartOfIntro
        }
      },

      getContentTypeHeader () {
        if (this.iconType) {
          return getGameContentDisplayType(this.iconType, true, true)
        } else {
          return ''
        }
      }
    }
  }
</script>
<template>
  <div
    class="module-row"
    :class="moduleRowClass"
    @click="$emit('click')"
  >
    <div>
      <content-icon class="content-icon" :icon="iconType" />
      <p class="content-heading"><b>{{ getContentTypeHeader }}: {{ displayName }}</b></p>
      <p>{{ description }}</p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .module-row {
    min-width: 30px;
    width: 100%;
    height: 100%;

    box-sizing: border-box;

    & > div {
      display: flex;
      flex-direction: row;
      align-items: center;

      padding-top: 5px;
      padding-bottom: 5px;

      width:100%;
      height: 100%;
    }

    cursor: pointer;

    &.locked {
      cursor: default;
    }
  }

  .module-row:hover:not(.locked) {
    border: 1px solid #74C6DF;
  }

  .part-of-intro {
    position: relative;
    padding-left: 34px;
  }

  .part-of-intro::before {
    position: absolute;
    width: 8px;
    height: 100%;
    content: "";
    margin-left: -34px;
    background-color: rgba(153, 145, 185, 0.3);

  }

  .content-heading {
    /* Prevents wrapping of the title leading to strange spacing. */
    flex-shrink: 0;
  }

  .content-icon {
    margin: 0 15px;
  }

  p {
    @include font-p-3-paragraph-small-white;
    color: $pitch;
    font-size: 12px;
    line-height: 13px;
    text-align: left;

    margin-bottom: -3px;
    margin-right: 15px;
  }

  .content-icon {
    width: 18px;
    height: 18px;
  }
</style>
