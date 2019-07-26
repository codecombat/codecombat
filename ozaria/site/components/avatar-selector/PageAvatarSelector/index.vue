
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

// TODO replace placeholders with the various options.
const avatars = [
  {
    selectionImg: '/images/ozaria/avatar-selector/circle.png',
    levelThangTypeId: '5c373c9f9034ac0034b43b22',
    cinematicThangTypeId: '5c373c9f9034ac0034b43b22'
  },
  {
    selectionImg: '/images/ozaria/avatar-selector/hex.png',
    levelThangTypeId: '5c373c9f9034ac0034b43b22',
    cinematicThangTypeId: '5c373c9f9034ac0034b43b22'
  },
  {
    selectionImg: '/images/ozaria/avatar-selector/square.png',
    levelThangTypeId: '5c373c9f9034ac0034b43b22',
    cinematicThangTypeId: '5c373c9f9034ac0034b43b22'
  },
  {
    selectionImg: '/images/ozaria/avatar-selector/circle.png',
    levelThangTypeId: '5c373c9f9034ac0034b43b22',
    cinematicThangTypeId: '5c373c9f9034ac0034b43b22'
  },
  {
    selectionImg: '/images/ozaria/avatar-selector/square.png',
    levelThangTypeId: '5c373c9f9034ac0034b43b22',
    cinematicThangTypeId: '5c373c9f9034ac0034b43b22'
  },
  {
    selectionImg: '/images/ozaria/avatar-selector/hex.png',
    levelThangTypeId: '5c373c9f9034ac0034b43b22',
    cinematicThangTypeId: '5c373c9f9034ac0034b43b22'
  },
]

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
    if (!me.hasAvatarSelectorAccess())  {
      return application.router.navigate('/', { trigger: true })
    }
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
    }
  },

  methods: {
    ...mapActions('me', ['set1fhAvatar']),

    handleClick (e) {
      const selectedAvatar = parseInt(e.target.dataset.avatar, 10)
      this.selected = selectedAvatar
    },

    async handleNext () {
      // TODO: uncomment this once slugs are finalized.
      //       We do not want to save these placeholder ids.
      // this.set1fhAvatar(this.selectedAvatar)

      // TODO: Handle saving avatar selection state.
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
            <h1>{{ this.$t('avatar_selection.pick_an_avatar') }}:</h1>
          </div>
        </div>
        <div class="row body">
          <div class="col-xs-8 avatar-grid">

            <section class="row">
              <div class="col-xs-4 avatar-item" v-for="({ selectionImg, levelThangTypeId }, index) in topRowAvatars" :key="levelThangTypeId">
                <div
                  :class="{selected: selected === index}"
                  :data-avatar="index"
                  @click="handleClick"
                  :style="{ backgroundImage: `url(${selectionImg})` }"
                />
              </div>
            </section>

            <section class="row">
              <div class="col-xs-4 avatar-item" v-for="({ selectionImg, levelThangTypeId }, index) in bottomRowAvatars" :key="levelThangTypeId">
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
                :height="360"
                :loadedThangTypes="loadedThangTypes"
                :selectedThang="selectedAvatar.cinematicThangTypeId"
                :thang="{
                  scaleFactorX: 3,
                  scaleFactorY: 3,
                  pos: { y: 1, x: 1 }
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
  height: 100%;

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

.body {
  height: 100%;
}

.avatar-grid {
  display: flex;
  flex-direction: column;
  justify-content: space-evenly;
  height: 100%;
}

.avatar-grid .row {
  margin: 15px 0;
  height: 100%;
  max-height: 200px;
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
