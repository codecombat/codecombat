<script>
  import ModuleHeader from './ModuleHeader'
  import ModuleRow from './ModuleRow'
  import { mapGetters } from 'vuex'

  export default {
    components: {
      ModuleHeader,
      ModuleRow
    },

    props: {
      moduleNum: {
        required: true,
        type: String
      }
    },

    computed: {
      ...mapGetters({
        getModuleInfo: 'baseCurriculumGuide/getModuleInfo',
        getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse',
        getContentDescription: 'baseCurriculumGuide/getContentDescription',
        getSelectedLanguage: 'baseCurriculumGuide/getSelectedLanguage',
        isOnLockedCampaign: 'baseCurriculumGuide/isOnLockedCampaign'
      }),

      getContentTypes () {
        return (this.getModuleInfo?.[this.moduleNum] || []).map(({
          name,
          displayName,
          type,
          ozariaType,
          introLevelSlug,
          slug,
          introContent,
          _id
        }) => {
          let icon, url

          // TODO: Where is the language chosen in the curriculum guide?
          if (!ozariaType) {
            icon = type
            url = `/play/intro/${introLevelSlug}?course=${this.getCurrentCourse._id}&codeLanguage=${this.getSelectedLanguage}&intro-content=${introContent || 0}`
          } else if (ozariaType) {
            if (ozariaType === 'practice') {
              icon = 'practicelvl'
            } else if (ozariaType === 'capstone') {
              icon = 'capstone'
            } else if (ozariaType === 'challenge') {
              icon = 'challengelvl'
            }
            url = `/play/level/${slug}?course=${this.getCurrentCourse._id}&codeLanguage=${this.getSelectedLanguage}`
          }

          if (!url || !icon) {
            console.error('missing url or icon in curriculum guide')
          }

          return {
            icon,
            name: displayName || name,
            _id,
            description: this.getContentDescription(this.moduleNum, _id),
            url
          }
        })
      }
    }
  }
</script>
<template>
  <div>
    <module-header :module-num="moduleNum" />

    <div v-if="!isOnLockedCampaign" class="content-rows">
      <a
        v-for="{ icon, name, _id, url, description } in getContentTypes"
        :key="_id"
        :href="url"
        target="_blank"
        rel="noreferrer"
      >
        <module-row
          :icon-type="icon"
          :display-name="name"
          :description="description"
        />
      </a>
    </div>
    <div v-else class="content-rows">
      <module-row
        v-for="{ icon, name, _id, url, description } in getContentTypes"
        :key="_id"
        :icon-type="icon"
        :display-name="name"
        :description="description"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  .content-rows {
    background-color: white;
    box-shadow: 2px 2px 4px rgba(0, 0, 0, 0.12);

    margin-bottom: 29px;

    // Supports both locked and unlocked views.
    & a:nth-child(odd), & > div:nth-child(odd) {
      background-color: #f2f2f2;
    }

    a {
      display: block;
      text-decoration: none;
    }
  }
</style>
