<script>
  import { resourceIcons } from 'app/schemas/schemas'
  const store = require('core/store')
  export default {
    props: {
      icon: {
        type: String,
        required: true,
        validator: value => resourceIcons.indexOf(value) !== -1
      },
      label: {
        type: String,
        required: false,
        default: ''
      },
      link: {
        type: String,
        default: null
      },
      from: {
        type: String,
        default: 'Resource Hub'
      },
      trackCategory: {
        type: String,
        default: ''
      },
      description: {
        type: String,
        default: ''
      },
      locked: {
        type: Boolean,
        default: false
      },
      section: {
        type: String,
        default: 'getting-started'
      }
    },
    computed: {
      cssVariables () {
        return {
          '--backgroundImage': this.locked ? 'url(/images/pages/game-menu/lock.png)' : `url(/images/ozaria/teachers/dashboard/svg_icons/Icon${this.icon}.svg)`
        }
      },
      formattedDescription () {
        return marked(this.description)
          .replace(/<a /g, '<a target=\'_blank\' ')
          .replace(/href=.*?>/g, (match) => this.locked ? 'href="/teachers/licenses/">' : match)
      },
      displayClass () {
        if (this.from === 'Zendesk') return 'resource-extra-wide'
        if (this.from !== 'Resource Hub') return 'resource-icon-only'
        if (this.section === 'lesson-slides') return 'resource-lesson-slides'
        return 'resource-full'
      },
      showLabel () {
        // If we aren't in the Resource Hub, only show in English, since we are hard-coding the other resource names without loading i18n
        return this.label !== '' && (this.from === 'Resource Hub' || /^en/.test(store.getters['me/preferredLocale']))
      }
    },
    methods: {
      clickIcon () {
        const eventName = `Resource Icon Clicked: ${this.label}`
        window.tracker?.trackEvent(eventName, { category: this.trackCategory || 'Teachers', label: this.from })
        this.$emit('click')
      }
    }
  }
</script>

<template>
  <a
    :href="locked ? '/teachers/licenses/' : link"
    :target="link === '#' ? '' : '_blank'"
    @click="clickIcon"
    :class="displayClass"
  >
    <div class='resource-icon' :style="cssVariables">
      <div class='icon'/>
      <h5 v-if="showLabel">{{ label }}</h5>
      <p v-if="description" v-html="formattedDescription"></p>
    </div>
  </a>
</template>

<style lang="scss" scoped>
  a {
    flex-basis: 330px;
    flex-grow: 1;
    max-width: 660px;
  }

  a:hover {
    text-decoration: none;
  }

  .resource-icon {
    display: flex;
    flex-direction: column;
    justify-content: start;
    align-items: flex-start;
    margin: 10px;
    padding: 10px;
    min-height: 120px;
    position: relative;
    border-radius: 4px;
    border: 1px solid rgb(81, 111, 172);
    background: rgba(81, 111, 172, 0.0);
    transition: background 0.1s linear;

    &:hover .icon {
      filter: saturate(1.5);
    }

    &:hover {
      background:rgba(81, 111, 172, 0.15);
    }
  }
  .icon {
    width: 30px;
    height: 30px;
    cursor: pointer;
    position: absolute;
    right: -10px;
    top: -10px;
    background-size: cover;
    background-image: var(--backgroundImage);
  }
  h5 {
    text-align: left;
    font-family: "Open Sans", sans-serif;
    font-size: 18px;
    font-weight: 600;
    line-height: 29px;
    margin: 0 0 5px 0;
  }
  p {
    margin: 0;
    font-family: 'Work Sans';
    font-size: 14px;
    line-height: 18px;
    text-align: left;
    letter-spacing: 0.27px;

    ::v-deep ul {
      padding-left: 17px;
      text-align: left;
    }
  }

  a.resource-extra-wide {
    .resource-icon {
      min-width: 400px;
    }
  }

  a.resource-lesson-slides {
    .resource-icon {
      max-width: 475px;
    }
  }

  a.resource-icon-only {
    flex: none;

    .resource-icon {
      border: 0;
      margin: 10px auto;
      width: 150px;
      min-height: unset;
      align-items: center;

      .icon {
        width: 80px;
        height: 80px;
        position: unset;
        margin: 0px auto;
      }

      h5 {
        font-family: "Work Sans", "Open Sans", sans-serif;
        font-size: 16px;
        font-weight: 400;
        line-height: 20px;
        margin: 5px 0 0 0;
        color: #0b63bc;
        text-align: center;
      }
    }
  }
</style>
