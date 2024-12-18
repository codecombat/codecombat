<script>
import ContentIcon from '../../common/icons/ContentIcon'
import { getGameContentDisplayType } from 'ozaria/site/common/ozariaUtils.js'
import { aiToolToImage } from 'app/core/utils.js'
import marked from 'marked'

const aiProjectTypes = ['ai-use', 'ai-learn']

export default {
  components: {
    ContentIcon
  },

  props: {
    iconType: {
      type: String,
      required: true,
      validator: value => {
        return ['cutscene', 'cinematic', 'capstone', 'interactive', 'practicelvl', 'challengelvl', 'intro', 'hero', 'course-ladder', 'game-dev', 'web-dev', 'ladder', 'challenge', 'ai-use', 'ai-learn'].indexOf(value) !== -1
      }
    },

    nameType: {
      type: String,
      required: false,
      default: null
    },

    displayName: {
      type: String,
      required: true,
      default: ''
    },

    levelNumber: {
      type: [String, Number],
      required: false,
      default: ''
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
      // uses in parent dashboard. do not remove
      type: Boolean,
      default: false
    },
    progressStatus: {
      type: String,
      default: ''
    },
    identifier: {
      type: String
    },
    locked: {
      type: Boolean,
      default: false,
    },
    tool: {
      type: String,
      default: undefined,
    },
  },

  data () {
    return {
      showCode: false,
      aiProjectTypes,
    }
  },

  computed: {
    clearDescription () {
      const description = marked(this.description).replace(/<[^>]*>/g, '')
      const doc = new DOMParser().parseFromString(description, 'text/html')
      return doc.documentElement.textContent
    },

    moduleRowClass () {
      return {
        locked: this.locked,
        'part-of-intro': this.isPartOfIntro,
        'show-progress-dot': this.showProgressDot
      }
    },

    getContentTypeHeader () {
      if (this.nameType || this.iconType) {
        const type = this.nameType ? this.nameType : this.iconType
        if (this.aiProjectTypes.includes(type)) {
          return ''
        }
        const name = getGameContentDisplayType(type, true, true)
        return `${name}:`
      } else {
        return ''
      }
    }
  },
  methods: {
    aiImage (tool) {
      if (tool.includes('claude')) {
        return aiToolToImage['claude-3']
      } else if (tool.includes('dall-e')) {
        return aiToolToImage['dall-e-3']
      } else if (tool.includes('stable-diffusion')) {
        return aiToolToImage['stable-diffusion-xl']
      } else if (tool.includes('gpt-')) {
        return aiToolToImage['gpt-4-turbo-preview']
      }
    },
    onShowCodeClicked () {
      this.showCode = !this.showCode
      this.$emit('showCodeClicked', { identifier: this.identifier, hideCode: !this.showCode, levelNumber: this.levelNumber })
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
      />
      <content-icon
        class="content-icon"
        :icon="iconType"
      />
      <img
        v-if="aiProjectTypes.includes(iconType)"
        class="tool-image"
        :src="aiImage(tool)"
        :title="tool"
      >
      <p class="content-heading">
        <b>{{ `${levelNumber ? levelNumber : '' }${levelNumber ? (nameType ? '.' : ':') : ''} ${getContentTypeHeader} ${ displayName.replace('Course: ', '')}` }}</b>
      </p>
      <p class="content-desc">
        {{ clearDescription }}
      </p>
      <div
        v-if="showCodeBtn"
        class="code-view"
        @click="onShowCodeClicked"
      >
        <img
          src="/images/pages/parents/dashboard/show-code-logo.svg"
          alt="Show Code Logo"
          class="code-view__icon"
        >
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
    min-width: 18px;
    min-height: 18px;
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

  .lprogress__level {
    .show-progress-dot {
      margin-left: 1rem;
    }
  }
.tool-image {
  width: 20px;
  margin-right: 10px;
}
</style>
