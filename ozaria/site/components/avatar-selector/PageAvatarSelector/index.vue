
<script>
import LayoutCenterContent from '../../common/LayoutCenterContent.vue'
import LayoutAspectRatioContainer from '../../common/LayoutAspectRatioContainer.vue'
import LayoutChrome from '../../common/LayoutChrome.vue'
import Surface from '../../char-customization/common/Surface.vue';
import BaseButton from '../../common/BaseButton.vue';
import { mapActions } from 'vuex';

// TODO migrate api calls to the Vuex store.
import { getThangTypeOriginal } from '../../../../../app/core/api/thang-types'
const ThangType = require('models/ThangType')

const avatars = _.shuffle([
  {
    selectionImg: '/images/ozaria/avatar-selector/avatar_bug.png',
    cinematicThangTypeId: '5d48b61ae92cc00030a9b2db',
    cinematicPetThangId: '5d48bd7677c98f0029118e11',
    avatarCodeString: 'bug'
  },
  {
    selectionImg: '/images/ozaria/avatar-selector/avatar_crown.png',
    cinematicThangTypeId: '5d48b85f703ac600249a5d69',
    cinematicPetThangId: '5d48c12b8ccd96003576806a',
    avatarCodeString: 'crown'
  },
  {
    selectionImg: '/images/ozaria/avatar-selector/avatar_ghost.png',
    cinematicThangTypeId: '5d48b98e703ac600249a5df6',
    cinematicPetThangId: '5d48c17a77c98f0029118fff',
    avatarCodeString: 'ghost'
  },
  {
    selectionImg: '/images/ozaria/avatar-selector/avatar_leaf.png',
    cinematicThangTypeId: '5d48ba358ccd960035767d81',
    cinematicPetThangId: '5d48c1c48ccd9600357680be',
    avatarCodeString: 'leaf'
  },
  {
    selectionImg: '/images/ozaria/avatar-selector/avatar_rose.png',
    cinematicThangTypeId: '5d48babc77c98f0029118cd7',
    cinematicPetThangId: '5d48c202e92cc00030a9b8bf',
    avatarCodeString: 'rose'
  },
  {
    selectionImg: '/images/ozaria/avatar-selector/avatar_snake.png',
    cinematicThangTypeId: '5d48bb5277c98f0029118d0d',
    cinematicPetThangId: '5d48c24a8ccd9600357680fd',
    avatarCodeString: 'snake'
  },
])

export default Vue.extend({
  components: {
    LayoutChrome,
    LayoutCenterContent,
    LayoutAspectRatioContainer,
    BaseButton,
    Surface
  },

  data: () => ({
    selected: -1,
    loadedThangTypes: {},
    loaded: false,
    avatars
  }),

  async created () {
    const loader = []

    for (const avatar of avatars) {
      const thangLoading = getThangTypeOriginal(avatar.cinematicThangTypeId)
        .then(attr => new ThangType(attr))
        .then(thangType => this.loadedThangTypes[avatar.cinematicThangTypeId] = thangType)
      loader.push(thangLoading)
    }

    try {
      await Promise.all(loader)
    } catch (e) {
      // TODO handle_error_ozaria - what if an avatar fails to load?
      console.error(e)
    }

    this.loaded = true
    window.tracker.trackEvent('Loaded Avatar Selector', {}, ['Google Analytics'])
  },

  beforeDestroy () {
    window.tracker.trackEvent('Unloaded Avatar Selector',
      {petThangTypeOriginalId: (this.avatars[this.selected] || {}).cinematicPetThangId,
        avatarThangTypeOriginalId: (this.avatars[this.selected] || {}).cinematicThangTypeId},
      ['Google Analytics'])
  },

  computed: {
    topRowAvatars () {
      return this.avatars.slice(0, 3)
    },

    bottomRowAvatars () {
      return this.avatars.slice(3)
    },

    selectedAvatar () {
      return this.avatars[this.selected]
    },

    title () {
      return $.i18n.t('avatar_selection.select_avatar_title')
    }
  },

  methods: {
    ...mapActions('me', ['setCh1Avatar', 'save']),

    handleClick (e) {
      const selectedAvatar = parseInt(e.target.dataset.avatar, 10)
      this.selected = selectedAvatar
    },

    async handleNext () {
      this.setCh1Avatar(this.selectedAvatar)

      try {
        // TODO handle_error_ozaria - What happens on failure?
        await this.save()
        // TODO button should become disabled while saving.
      } catch (e) {
        console.error('Failed to save avatar')
        console.error(JSON.stringify(e))
      }

      this.$emit('completed')
    }
  }
})
</script>

<template>

  <layout-chrome
    :title="title"
  >
    <layout-center-content>
      <layout-aspect-ratio-container
        :aspectRatio="1266 / 668"
      >
      <div class="avatar-selector container-fluid">
        <div id="row">
          <div class="col-xs-12 header">
            <h1>{{ this.$t('avatar_selection.pick_an_avatar') }}:</h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-8 avatar-grid">

            <section class="row">
              <div class="col-xs-4 avatar-item" v-for="({ selectionImg, avatarCodeString }, index) in topRowAvatars" :key="avatarCodeString">
                <div
                  :class="{selected: selected === index}"
                  :data-avatar="index"
                  @click="handleClick"
                  :style="{ backgroundImage: `url(${selectionImg})` }"
                />
              </div>
            </section>

            <section class="row">
              <div class="col-xs-4 avatar-item" v-for="({ selectionImg, avatarCodeString }, index) in bottomRowAvatars" :key="avatarCodeString">
                <div
                  :class="{selected: selected === index + 3}"
                  :data-avatar="index+3"
                  @click="handleClick"
                  :style="{ backgroundImage: `url(${selectionImg})` }"
                />
              </div>
            </section>

          </div>
          <div class="col-xs-4 surface" v-if="loaded && selected !== -1">
            <div>
              <Surface
                :key="selected"
                :width="200"
                :height="200"
                :loadedThangTypes="loadedThangTypes"
                :selectedThang="selectedAvatar.cinematicThangTypeId"
                :thang="{
                  scaleFactorX: 0.5,
                  scaleFactorY: 0.5,
                  pos: { y: -21.5, x: 3.5 }
                }"
              />
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col-xs-12 footer">
            <base-button
              :enabled="selected !== -1"
              @click="handleNext"
            >
              {{ this.$t('common.next') }}
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
  font-size: 5vh;
}

.avatar-selector {
  background-color: white;
  height: 100%;
  @media screen and (max-width: 1008px) {
    height: unset;
  }
  @media screen and (max-width: 652px) {
    white-space: nowrap;
  }
  padding: 30px 60px;

  display: flex;

  flex-direction: column;
  justify-content: space-between;

  overflow: scroll;
}

.avatar-item {
  height: 100%;
  padding: 0 0.8vh;

  div {
    height: 100%;
    border-radius: 10px;
    border: 1px solid #ccc;
    box-shadow: inset 0px 0px 5px #ddd;

    &.selected {
      border: 1px solid #4A90E2;
      box-shadow: inset 0px 0px 6px rgb(71, 136, 211);
    }
  }

  & > div {
    background-position: center;
    background-size: auto 80%;
    background-repeat: no-repeat;
  }
}

.avatar-grid {
  display: flex;
  flex-direction: column;
  justify-content: space-evenly;
  height: 40vh;
}

.avatar-grid .row {
  margin: 0.8vh 0;
  /* Locking height resolves responsive issues seen on chromebook */
  height: 170px;
}

.surface {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-content: center;
  height: 100%;

  & > div {
    text-align: center;
  }
}

.footer {
  text-align: right;
}

</style>
