<template>
  <div
    id="pd-view"
    class="container"
  >
    <trophy-header />
    <a name="implementation" />
    <pd-box
      :title="$t('pd_page.implementation_training_title')"
      :blurb="$t('pd_page.implementation_training_blurb')"
      :list="[
        $t('pd_page.list_1'),
        $t('pd_page.list_2'),
        $t('pd_page.list_3')
      ]"
      :modal="{
        subtitle: $t('pd_page.modal_subtitle'),
        emailMessage: $t('pd_page.email_message')
      }"
      image="/images/pages/pd/implementation.webp"
    />
    <a name="professional" />
    <pd-box
      :title="$t('pd_page.professional_development_title')"
      :blurb="$t('pd_page.professional_development_blurb')"
      :list="[
        $t('pd_page.list_4'),
        $t('pd_page.list_5'),
        $t('pd_page.list_6')
      ]"
      :buttons="[
        {
          text: $t('pd_page.download_table_of_contents'),
          href: 'https://drive.google.com/file/d/1lFkiS2_hjddQGoskzLFv-QRGoNp7R6Va/view'
        }
      ]"
      :modal="{
        subtitle: $t('pd_page.modal_subtitle'),
        emailMessage: $t('pd_page.email_message')
      }"
      image="/images/pages/pd/conditionals.webp"
      sample-lesson-src="https://web.edapp.com/lessons/6047c494b8c984000128e504/"
      :logo-badges="['/images/pages/schools/logo/SNHU-Logo.webp']"
    />
    <a name="apcsp" />
    <pd-box
      :title="$t('pd_page.ap_csp_professional_development_title')"
      :blurb="$t('pd_page.ap_csp_professional_development_blurb')"
      :list="[
        $t('pd_page.list_7'),
        $t('pd_page.list_8'),
        $t('pd_page.list_9')
      ]"
      :buttons="[{
        text: $t('pd_page.download_syllabus'),
        href: 'https://files.codecombat.com/docs/apcsp/CodeCombat_APCSP_Syllabus.pdf'
      }]"
      :modal="{
        subtitle: $t('pd_page.modal_subtitle'),
        emailMessage: $t('pd_page.email_message')
      }"
      image="/images/pages/pd/algorithms.webp"
      sample-lesson-src="https://trainingpreview.edapp.com/p/1GvFJ98La2KPvduiz5QK2ifR"
      :logo-badges="['/images/pages/apcsp/apcsp_logo.webp','/images/pages/schools/logo/SNHU-Logo.webp']"
    />
  </div>
</template>

<script>
import { COMPONENT_NAMES, PAGE_TITLES } from '../../../ozaria/site/components/teacher-dashboard/common/constants.js'
import { mapActions, mapMutations } from 'vuex'
import TrophyHeader from './TrophyHeader.vue'
import PDBox from './PDBox.vue'

export default {
  name: COMPONENT_NAMES.PD,
  components: {
    TrophyHeader,
    'pd-box': PDBox
  },
  mounted () {
    if (this.$route.path.startsWith('/teachers/professional-development')) {
      this.startLoading()
      this.setComponentName(this.$options.name)
      this.setPageTitle(PAGE_TITLES[this.$options.name])
      this.fetchData({ componentName: this.$options.name, options: { loadedEventName: 'PD: Loaded' } })
    }
  },
  methods: {
    ...mapMutations({
      setPageTitle: 'teacherDashboard/setPageTitle',
      setComponentName: 'teacherDashboard/setComponentName',
      startLoading: 'teacherDashboard/startLoading'
    }),
    ...mapActions({
      fetchData: 'teacherDashboard/fetchData',
    })
  },
}
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";
#pd-view {
  display: flex;
  flex-direction: column;
  gap: 40px;
  ::v-deep {
    @extend %frontend-page;
  }
}
</style>
