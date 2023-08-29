<template>
  <div
    v-if="campaign"
    class="basic"
  >
    <div class="content">
      <div class="content__img">
        <img
          :src=getCampaignImage(campaign)
          alt="Campaign image"
          class="content__level-img"
        >
      </div>
      <div class="content__info">
        <div class="content__title">
          {{ campaign.fullName || campaign.name }}
        </div>
        <div
          v-if="campaign?.course?.description || campaign?.description"
          class="content__subtitle"
        >
          {{ campaign?.course?.description || campaign?.description }}
        </div>
        <div class="content__proficiency">
          <p class="content__proficiency__text">Concept proficiency</p>
          <div class="content__list">
            <div
              v-for="concept in levelConcepts"
              :key="concept"
              class="content__list__item"
            >
              {{ concept }}
            </div>
          </div>
        </div>
        <div class="content__options">
          <p class="content__select-lang">
            Select Language:
          </p>
          <div class="content__lang-solution">
            <select
              @change="updateLanguage"
              name="content__language" id="content__language-id" class="content__language"
            >
              <option :selected="selectedCodeLang === 'python'" value="python" class="content__language__option">Python</option>
              <option :selected="selectedCodeLang === 'javascript'" value="javascript" class="content__language__option">Javascript</option>
            </select>
            <button
              v-if="!isPaidUser"
              class="content__solution__lock"
              @click="onLockSolutionGuideClick"
            >
              <img
                src="/images/ozaria/teachers/dashboard/svg_icons/IconSolution.svg"
                alt="Solution Guide Icon"
                class="content__solution__icon"
              />
              <span class="content__solution__text">
                Solution Guide
              </span>
              <img
                src="/images/pages/game-menu/lock.png"
                alt="Solution Guide Icon"
                class="content__solution__lock-icon"
              />
            </button>
            <a
              v-else
              :href="getSolutionGuideLink"
              target="_blank"
              class="content__solution-guide"
            >
              <img
                src="/images/ozaria/teachers/dashboard/svg_icons/IconSolution.svg"
                alt="Solution Guide Icon"
                class="content__solution__icon"
              />
              <span class="content__solution__text">
                Solution Guide
              </span>
            </a>
          </div>
        </div>
      </div>
    </div>
    <div class="certificate">
      <a
        v-if="isCampaignComplete"
        :href="`/certificates/${childId}?campaign-id=${campaign._id}`"
        target="_blank"
      >
        <img
          src="/images/pages/user/certificates/certificate-icon.png"
          alt="Certificate image"
          class="certificate__img certificate__img--complete"
        >
      </a>
      <img
        v-if="!isCampaignComplete"
        src="/images/pages/parents/dashboard/certificate.png"
        alt="Certificate image"
        class="certificate__img"
      >
      <div
        class="certificate__subtext"
      >
        {{ isCampaignComplete ? 'course complete' : 'course incomplete' }}
      </div>
    </div>
  </div>
</template>

<script>
const campignSlugImageMap = {
  dungeon: 'kithgard-dungeon.png',
  forest: 'backwoods-forest.png',
  desert: 'desert.png',
  mountain: 'cloudrip-mountain.png',
  glacier: 'glacier.png',
  'campaign-web-dev-1': 'web-dev.png',
  'campaign-web-dev-2': 'web-dev-2.png',
  'campaign-game-dev-1': 'game-dev.png',
  'campaign-game-dev-2': 'game-dev-2.png',
  'campaign-game-dev-3': 'game-dev-2.png'
}
export default {
  name: 'CampaignBasicSummary',
  props: {
    campaign: {
      type: Object,
      default: null
    },
    selectedCodeLanguage: {
      type: String,
      default: 'python'
    },
    childId: {
      type: String,
      default: ''
    },
    isCampaignComplete: {
      type: Boolean,
      default: false
    },
    isPaidUser: {
      type: Boolean,
      default: false
    },
    product: {
      type: String,
      default: 'CodeCombat'
    }
  },
  data () {
    return {
      selectedCodeLang: this.selectedCodeLanguage
    }
  },
  computed: {
    levelConcepts () {
      const capitalize = str => str[0].toUpperCase() + str.substring(1)
      if (this.product === 'Ozaria') {
        return this.campaign?.concepts?.map(c => c.split('_').map(capitalize).join(' '))
      } else {
        return this.campaign?.description?.split(',').map(d => d.trim().split(' ').map(capitalize).join(' '))
      }
    }
  },
  methods: {
    updateLanguage (e) {
      this.selectedCodeLang = e.target.value
      this.$emit('languageUpdated', this.selectedCodeLang)
    },
    getCampaignImage (campaign) {
      if (this.product === 'Ozaria') {
        return `/ozaria/file/${campaign.screenshot}`
      } else {
        return `/images/pages/play/campaign/${campignSlugImageMap[campaign.slug]}`
      }
    },
    getSolutionGuideLink () {
      if (this.product === 'Ozaria') {
        return `/teachers/course-solution/${this.campaign._id}/${this.selectedCodeLang}`
      } else {
        return `/teachers/campaign-solution/${this.campaign.slug}/${this.selectedCodeLang}`
      }
    },
    onLockSolutionGuideClick () {
      noty({
        type: 'information',
        text: 'Only available to paid users',
        timeout: 5000,
        layout: 'center'
      })
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "../css-mixins/variables";

.basic {
  display: grid;
  grid-template-columns: 2fr 1fr;
  background: $color-grey-2;

  @media (max-width: $screen-lg) {
    grid-template-columns: repeat(2, minmax(min-content, max-content));
  }

  .content {
    display: grid;
    grid-template-columns: 1fr 3fr;
    grid-column-gap: 2rem;
    padding: 2rem;

    &__img {
      display: flex;
      justify-content: center;
    }

    &__level {
      &-img {
        height: 30rem;
      }
    }

    &__info {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      justify-content: space-around;

      @media (max-width: $screen-lg) {
        padding: 1rem;
      }
    }

    &__list {
      display: grid;
      grid-template-columns: 1fr 1fr;
      grid-column-gap: 5rem;

      @media (max-width: $screen-lg) {
        grid-template-columns: minmax(min-content, max-content);
      }
    }

    &__language {
      background: $color-twilight;
      border: 1.5px solid $color-blue-1;
      border-radius: 4px;
      color: $color-yellow-1;
      width: 150px;
      padding: 8px 5px;
      font-weight: 600;
      font-size: 14px;
      line-height: 20px;
    }

    &__solution-guide {
      background-color: $color-green-1;
      border-radius: 4px;
      border-width: 0;
      text-shadow: unset;
      text-align: center;
      color: #131b25;
      letter-spacing: .27px;
      font-style: normal;
      font-weight: 600;
      font-size: 14px;
      line-height: 16px;
      background-image: unset;
      display: flex;
      padding: .8rem 1.5rem;
      justify-content: center;
      align-items: center;
      margin-left: 1rem;
      text-decoration: none;
    }

    &__title {
      font-weight: 600;
      font-size: 2.2rem;
      line-height: 2.4rem;
      color: #131B25;
      text-transform: uppercase;

      margin-bottom: 1rem;
    }

    &__subtitle {
      font-weight: 400;
      font-size: 1.6rem;
      line-height: 2rem;
      color: #131B25;

      margin-bottom: 1.5rem;
    }

    &__proficiency {
      margin-bottom: 1.5rem;
      &__text {
        font-size: 1.8rem;
        line-height: 3rem;
        letter-spacing: 0.444444px;
        text-transform: uppercase;
        color: #131B25;
        font-weight: 600;

        margin-bottom: 0;
      }
    }

    &__list {
      &__item {
        font-weight: 600;
        font-size: 1.4rem;
        //line-height: 1.6rem;
      }
    }

    &__select-lang {
      font-weight: 400;
      font-size: 1.2rem;
      line-height: 1.4rem;

      margin-bottom: 5px;
    }

    &__lang-solution {
      display: flex;
      align-items: center;
    }

    &__solution__text {
      margin-left: .5rem;
    }

    &__solution__lock {
      margin-left: 2rem;
      &-icon {
        width: 2rem;
      }
    }
  }

  .certificate {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;

    &__text {
      font-weight: 600;
      font-size: 1.4rem;
      line-height: 1.8rem;
      letter-spacing: 0.4px;
      text-transform: uppercase;

      margin-bottom: 1rem;
      text-align: center;
    }

    &__subtext {
      font-weight: 400;
      font-size: 1.6rem;
      line-height: 2rem;
    }

    &__img {
      &--complete {
        cursor: pointer;
      }
    }
  }
}

.tooltip {
  display: block !important;
  z-index: 10000;
}

.tooltip .tooltip-inner {
  background: black;
  color: white;
  border-radius: 16px;
  padding: 5px 10px 4px;
}

.tooltip .tooltip-arrow {
  width: 0;
  height: 0;
  border-style: solid;
  position: absolute;
  margin: 5px;
  border-color: black;
  z-index: 1;
}
</style>
