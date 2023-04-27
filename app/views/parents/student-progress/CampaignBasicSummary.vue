<template>
  <div
    v-if="campaign"
    class="basic"
  >
    <div class="content">
      <div class="content__img">
        <img
          :src="`/images/pages/play/campaign/${getCampaignImage(campaign.slug)}`"
          alt="Campaign image"
          class="content__level-img"
        >
      </div>
      <div class="content__info">
        <div class="content__title">
          {{ campaign.fullName || campaign.name }}
        </div>
        <div
          v-if="campaign?.course?.description"
          class="content__subtitle"
        >
          {{ campaign.course.description }}
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
              <option :selected="selectedLang === 'python'" value="python" class="content__language__option">Python</option>
              <option :selected="selectedLang === 'javascript'" value="javascript" class="content__language__option">Javascript</option>
            </select>
            <a
              :href="`/teachers/campaign-solution/${campaign.slug}/${selectedLanguage}`"
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
      <img src="/images/pages/parents/dashboard/certificate.png" alt="Certificate image" class="certicate__img">
      <div class="certificate__text">
        certificate of completion
      </div>
      <div class="certificate__subtext">
        course incomplete
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
  name: 'LevelBasicSummary',
  props: {
    campaign: {
      type: Object,
      default: null
    },
    selectedLanguage: {
      type: String,
      default: 'python'
    }
  },
  data () {
    return {
      selectedLang: this.selectedLanguage
    }
  },
  computed: {
    levelConcepts () {
      const capitalize = str => str[0].toUpperCase() + str.substring(1)
      return this.campaign?.description?.split(',').map(d => d.trim().split(' ').map(capitalize).join(' '))
    }
  },
  methods: {
    updateLanguage (e) {
      this.selectedLang = e.target.value
      this.$emit('languageUpdated', this.selectedLang)
    },
    getCampaignImage (slug) {
      return campignSlugImageMap[slug]
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";

.basic {
  display: grid;
  grid-template-columns: 2fr 1fr;
  background: #F2F2F2;

  @media (max-width: $screen-lg) {
    grid-template-columns: repeat(2, minmax(min-content, max-content));
  }

  .content {
    display: grid;
    grid-template-columns: 1fr 3fr;
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
      background: #476fb1;
      border: 1.5px solid #355ea0;
      border-radius: 4px;
      color: #f7d047;
      width: 150px;
      padding: 8px 5px;
      font-weight: 600;
      font-size: 14px;
      line-height: 20px;
    }

    &__solution-guide {
      background-color: #5db9ac;
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
  }
}
</style>
