<template>
  <div id="roblox-page">
    <div class="container-fluid headline-container">
      <div class="container">
        <div class="row headline-row">
          <div class="col col-md-8">
            <img class="coco-worlds-logo" src="/images/pages/roblox/coco-worlds.png">
            <h1 class="text-headline">
              {{ $t('roblox_landing.headline') }}
            </h1>
            <h2 class="text-subhead">
              {{ $t('roblox_landing.subhead') }}
            </h2>

            <a href="https://www.roblox.com/games/11704713454/CodeCombat-Worlds" target="_blank">
              <img src="/images/pages/roblox/play_now.png" class="header-button" />
            </a>
          </div>
        </div>
      </div>
    </div>
    <div class="container-fluid container-fluid-boxes">
      <div v-if="role" class="container container-boxes">
        <robloxButton class="roblox-connect" />
        <h3>{{ $t('roblox_landing.boxes_title') }}</h3>
        <div v-for="boxType in boxesByRole[role]" class="row" :class="`row-type-${boxType}`">
          <div class="col col-md-6 box-content ">
            <img class="box-icon" :src="`/images/pages/roblox/${boxType}-icon.svg`">
            <h4 class="box-title">
              {{ $t(`roblox_landing.box_${boxType}_subhead`) }}
            </h4>
            <p>
              {{ $t(`roblox_landing.box_${boxType}_blurb_${role}`) }}
            </p>
          </div>
          <div class="col col-md-6">
            <img :src="`/images/pages/roblox/${boxType}.png`">
          </div>
        </div>
        <div class="row">
          <div class="col col-md-12">
            <p v-if="role === 'parent'" v-html="$t('roblox_landing.bottom_blurb_parent', i18nData)"></p>
            <p v-if="role === 'partner'" v-html="$t('roblox_landing.bottom_blurb_partner', i18nData)"></p>
          </div>
        </div>
      </div>

      <div class="container">
        <div class="row row-video">
          <div class="col-md-12">
            <div class="video-container">
              <base-video :youtube-props="{ videoId: youtubeId, fitParent: true }"
                :cloudflare-props="{ videoCloudflareId: videoId, thumbnailUrl }" />
            </div>
          </div>
        </div>

        <div class="row row-faq">
          <div class="col-md-12">
            <button-main href="https://codecombat.zendesk.com/hc/en-us/categories/18084251471383-CodeCombat-Worlds-Roblox-" target="_blank" :buttonText="$t('contact.faq')" class="button-main" />

            <div class="item">
              <p class="question">{{ $t('roblox_landing.question_1') }}</p>
              <ul>
                <li>{{ $t('roblox_landing.answer_1') }}</li>
              </ul>
            </div>

            <div class="item">
              <p class="question">{{ $t('roblox_landing.question_2') }}</p>
              <ul>
                <li>{{ $t('roblox_landing.answer_2') }}</li>
              </ul>
            </div>

            <div class="item">
              <p class="question">{{ $t('roblox_landing.question_3') }}</p>
              <ul>
                <li>{{ $t('roblox_landing.answer_3') }}</li>
              </ul>
            </div>

            <p class="faq-bottom" v-html="$t('roblox_landing.faq_bottom')"></p>
          </div>
        </div>
      </div>
    </div>
    <modal v-if="modalShown" :title="`Join the Beta ${isMobile ? 'Waitlist' : 'Now'}`" ref="modal" @close="closeModal">
      <form @submit.prevent="onFormSubmit" class="schedule-free-class-form">
        <div class="form-group">
          <label for="role">{{ $t('roblox_landing.select_role') }}</label>
          <select class="form-control" v-model="role">
            <option v-for="value in roles" :key="value" :value="value">
              {{ $t(`roblox_landing.role_${value}`) }}
            </option>
          </select>
        </div>
        <div class="form-group" :class="{ 'has-error': !isValidEmail }">
          <label for="email">{{ $t('modal_free_class.email') }}</label>
          <input type="email" id="email" placeholder="Enter email" v-model="email" class="form-control" />
        </div>
        <div class="form-group pull-right">
          <span v-if="isSuccess" class="success-msg">
            <span v-if="isMobile">
              Success
            </span>
            <span v-else>
              You're in! First, <a href="https://www.roblox.com/groups/14987146/CodeCombat#!/about" target="_blank">join
                the CodeCombat Roblox group</a>, then <a href="https://www.roblox.com/games/11704713454/CodeCombat-Worlds"
                target="_blank">play CodeCombat Worlds</a>!
            </span>
          </span>
          <button v-if="!isSuccess" class="btn btn-success btn-lg" type="submit" :disabled="inProgress">
            <span v-if="isMobile">
              Submit
            </span>
            <span v-else>
              Join
            </span>
          </button>
        </div>
      </form>
    </modal>
  </div>
</template>

<script>

import BaseVideo from 'app/components/common/BaseVideo'

import Modal from 'app/components/common/Modal'
import forms from 'core/forms'
import { waitlistSignup } from 'core/api/roblox'
import ButtonMain from '../common/ButtonMain'

import RobloxButton from 'app/views/account/robloxButton.vue'

export default {
  components: {
    RobloxButton,
    BaseVideo,
    ButtonMain,
    Modal
  },

  data: () => {
    const i18nData = {
      'sign-up': `<a href="https://codecombat.com/parents">${$.i18n.t('roblox_landing.bottom_blurb_sign_up')}</a>`,
      'reach-out': `<a href="https://codecombat.com/partners">${$.i18n.t('roblox_landing.bottom_blurb_reach_out')}</a>`,
      interpolation: { escapeValue: false }
    }

    const videoId = 'a4a795197e1e6b4c75149c7ff297d2fa'
    const youtubeId = 'ZhfFr0TWqjo'

    return {
      role: 'player',
      roles: ['teacher', 'player', 'parent', 'partner'],
      boxesByRole: {
        teacher: ['play', 'code', 'create'],
        player: ['play', 'code', 'create'],
        parent: ['play', 'code', 'create'],
        partner: ['play', 'code', 'create']
      },
      name: me.get('firstName') || me.get('name') || '',
      email: me.get('email') || '',
      isSuccess: false,
      inProgress: false,
      isValidEmail: true,
      modalShown: false,
      i18nData,
      videoId,
      youtubeId,
      thumbnailUrl: `https://videodelivery.net/${videoId}/thumbnails/thumbnail.jpg?time=3.000s`
    }
  },
  computed: {
    isMobile () {
      const userAgent = window.navigator.userAgent;
      const mobileDevices = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i;

      return mobileDevices.test(userAgent);
    },
  },

  methods: {
    openModal () {
      this.modalShown = true
    },
    closeModal () {
      this.modalShown = false
    },
    validate () {
      this.isValidEmail = this.email && forms.validateEmail(this.email)
    },
    async onFormSubmit () {
      this.validate()
      if (!this.isValidEmail) {
        return
      }

      this.inProgress = true
      this.isSuccess = false

      try {
        await waitlistSignup({ email: this.email, role: this.role, mobile: this.isMobile })
        this.isSuccess = true
      } catch (err) {

        let text = 'Failed to contact server, please reach out to support@codecombat.com'
        if (err.code === 409) { // already signed up, so we'll just show success
          this.isSuccess = true
          this.inProgress = false
          return
        }

        console.error('roblox waitlist signup error', err)
        noty({
          text,
          type: 'error',
          timeout: 5000,
          layout: 'topCenter'
        })
      }
      this.inProgress = false
    }
  }
}
</script>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";

$body-font: "Work Sans", "Open Sans", "sans serif";
$box-content-margin: min(6vw, 90px);

.asset {
  content: "";
  position: absolute;
  display: block;
  width: 30%;
  aspect-ratio: 1/1;
  background-image: url(/images/pages/roblox/play-assets.png);
  background-size: contain;
  background-repeat: no-repeat;
  z-index: 1;
  top: 27%;
  left: -18.5%;
}

#roblox-page {
  background: radial-gradient(ellipse at center, rgba(0, 161, 144, 1) 0%, rgba(0, 177, 156, 1) 54%, rgba(0, 107, 99, 1) 96%, rgba(0, 107, 99, 1) 100%);
  margin-bottom: -50px;

  h1,
  h2,
  h3,
  h4,
  p,
  li {
    color: white;
    font-family: $body-font;
  }

  h1.text-headline {
    color: black;
    font-size: 40px;
    line-height: 1em;
    font-weight: 600;
    text-shadow: 0em 0.0375em 0.28125em rgb(255 255 255 / 90%);

    @media (max-width: $screen-md-min) {
      font-size: 20px;
    }
  }

  h2.text-subhead {
    color: black;
    font-size: 29px;
    text-shadow: 0em 0.0375em 0.28125em rgb(255 255 255 / 90%);
    line-height: 1.13em;
    font-weight: 600;

    @media (max-width: $screen-md-min) {
      font-size: 15px;
    }

    margin: 5px 0;
  }

  >.container>.row,
  >.container-fluid-boxes>.container>.row {
    margin-bottom: min(6.66vw, 100px);

    &:last-child {
      margin-bottom: 0;
    }

    @media (max-width: $screen-md-min) {
      &:not(:last-child) {
        margin-bottom: 60px;
      }
    }
  }

  img {
    max-width: 100%;

    &.box-icon {
      max-width: 80px;
      max-height: 80px;
    }
  }

  .box-content {
    text-align: center;

    p {
      margin: 0 $box-content-margin 14px;
    }

    + div > img {
      width: 100%;
    }
  }

  .row-type-play,
  .row-type-create {
    position: relative;

    &:before {
      @extend .asset;
    }
  }

  .row-type-create {
    &:before {
      top: -18%;
      left: auto;
      right: -16.7%;
      background-image: url(/images/pages/roblox/create-assets.png);
    }
  }

  .box-title {
    font-size: 29px;
    font-weight: bold;
    margin: 10px auto;
  }

  .coco-worlds-logo {
    height: min(20vw, 160px);
  }

  .container-fluid-boxes {
    background: radial-gradient(1196.37px at 925.287px 1196.37px, rgba(0, 0, 0, 0) 70%, rgba(0, 0, 0, 0.58) 130%);
    margin-top: -50px;
    padding-top: 50px;
    overflow: hidden;
  }

  .container-boxes {
    h3 {
      text-align: center;
      margin-bottom: 70px;
      font-size: 33px;
      line-height: 1.2em;

      @media (max-width: $screen-md-min) {
        font-size: 19px;
      }

    }

    @media (min-width: $screen-md-min) {

      // reverse the order of image/text in every second box on desktop screens
      >.row {
        display: flex;

        &:nth-child(odd) {
          >.col:first-child {
            order: 1
          }

          >.col:last-child {
            order: 0
          }
        }
      }
    }
  }

  >.container,
  >.container-fluid-boxes>.container {
    >.row-video {
      margin-bottom: min(3vw, 40px);

      .video-container {
        width: 100%;
      }
    }

    .row-faq {
      font-size: 27px;
      text-align: center;
      line-height: 1.23em;

      @media (max-width: $screen-md-min) {
        font-size: 13px;
      }

      .faq-bottom {
        margin-top: 60px;
        margin-bottom: 30px;
        ::v-deep {
          a {
            color: #FF9406;
          }
        }
      }

      .item {
        text-align: left;
        margin-bottom: min(2vw, 40px);

        &:not(.item ~ .item) {
          // first item of class selected
          margin-top: min(1.5vw, 30px);
        }
      }

      .question {
        font-weight: bold;
      }
    }
  }


  .headline-container {
    margin-bottom: min(3.33vw, 50px);
    background: url(/images/pages/roblox/Code_Combat_Thumbnail_wide.png);
    background-size: cover;
    background-position: right center;
    position: relative;
    overflow: hidden;
    position: relative;
  }

  .headline-row {
    position: relative;
    padding-bottom: 0px;

    &:before {
      content: "";
      position: absolute;
      height: 100%;
      aspect-ratio: 1265/864;
      background: url(/images/pages/roblox/tree.png);
      background-size: contain;
      left: -50%;
      transform: translateX(22%);
    }

    .header-button {
      width: 190px;
      margin-bottom: 30px;

      &:hover {
        filter: brightness(1.2);
      }
    }

    .col {
      padding-top: min(1.25vw, 20px);
    }

  }

  .video-background {
    position: absolute;
    min-width: 100%;
    min-height: 100%;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    aspect-ratio: 4676 / 1772;
  }

  .success-msg {
    font-size: 1.6rem;
    color: #0B6125;
    display: inline-block;
    margin-right: 1rem;
  }

  .button-main {
    background-color: #FF9406;
    display: inline-block;
    min-width: auto;
    margin: 25px 0;
    color: white;
    text-shadow: 0em 0.0375em 0.18em rgb(0 0 0 / 37%);

    &:hover {
      background-color: #fcd200;
    }
  }

  .roblox-connect {
    margin-bottom: 20px;
  }
}</style>
