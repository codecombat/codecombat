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
        validator: value => ['cutscene', 'cinematic', 'capstone', 'interactive', 'practicelvl', 'challengelvl', 'intro'].indexOf(value) !== -1
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
      },

      showCodeBtn: {
        type: Boolean,
        default: false
      },
      showProgressDot: {
        type: Boolean,
        default: false
      },
      progressStatus: {
        type: String,
        default: ''
      },
      identifier: {
        type: String
      }
    },

    data () {
      return {
        showCode: false
      }
    },

    computed: {
      ...mapGetters({
        isOnLockedCampaign: 'baseCurriculumGuide/isOnLockedCampaign'
      }),

      moduleRowClass () {
        return {
          locked: this.isOnLockedCampaign,
          'part-of-intro': this.isPartOfIntro,
          'show-progress-dot': this.showProgressDot
        }
      },

      getContentTypeHeader () {
        if (this.iconType) {
          return getGameContentDisplayType(this.iconType, true, true)
        } else {
          return ''
        }
      }
    },
    methods: {
      onShowCodeClicked () {
        this.showCode = !this.showCode
        this.$emit('showCodeClicked', { identifier: this.identifier, hideCode: !this.showCode })
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
      <div
        v-if="showProgressDot"
        :class="{ 'progress-dot': true, 'in-progress': progressStatus === 'in-progress', 'not-started': progressStatus === 'not-started', 'complete': progressStatus === 'complete' }"
      >
      </div>
      <content-icon class="content-icon" :icon="iconType" />
      <p class="content-heading"><b>{{ getContentTypeHeader }}: {{ displayName }}</b></p>
      <p class="content-desc">{{ description }}</p>
      <div
        v-if="showCodeBtn"
        class="code-view"
        @click="onShowCodeClicked"
      >
        <img src="/images/pages/parents/dashboard/show-code-logo.svg" alt="Show Code Logo" class="code-view__icon">
        <span class="code-view__text">
          {{ showCode ? 'Hide Code' : 'See Code' }}
        </span>
      </div>
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
    border: 1px solid transparent;

    & > div {
      display: flex;
      flex-direction: row;
      align-items: center;

      padding-top: 4px;
      padding-bottom: 4px;

      width:100%;
      height: 100%;
    }

    cursor: pointer;

    &.locked {
      cursor: default;
    }
  }

  .module-row:hover:not(.locked) {
    border-color: #74C6DF;
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

  .content-desc {
    margin-right: auto;
  }

  .code-view {
    display: flex;
    align-items: center;
    margin-right: 2rem;
    cursor: pointer;
    &__text {
      font-weight: 600;
      font-size: 1.4rem;
      line-height: 1.6rem;
      letter-spacing: 0.333333px;

      color: #355EA0;
      margin-left: .5rem;
    }
  }

  .progress-dot {
    width: 1rem;
    height: 1rem;
    background: #FFFFFF;
    border-radius: 1rem;
    margin-bottom: .5rem;
  }
  .not-started {
    border: 1.5px solid #C8CDCC;
  }

  .in-progress {
    background-color: #1ad0ff;
  }

  .complete {
    background-color: #2dcd38;
  }

  .show-progress-dot {
    margin-left: 1rem;
  }
</style>
