<template>
  <div id="page-hackstack-cyber">
    <HackstackHero
      variant="cyber"
      :title="$t('hackstack_cyber_page.header')"
      :powered-by-label="$t('hackstack_algebra_page.header_powered_by')"
      logo-src="/images/pages/hackstack/cyber/hackstack-logo.png"
      logo-alt="AI HackStack"
      :description="$t('hackstack_cyber_page.header_details')"
      :badges="alignmentBadges"
      :alignment-text="$t('hackstack_cyber_page.header_aligned')"
      media-src="/images/pages/hackstack/cyber/hero-simulation.png"
      media-alt="IT Help Desk Simulation"
    >
      <template #actions>
        <CTAButton
          v-if="!isPaidTeacherAccount"
          class="cta-button"
          @clickedCTA="onGetSolution"
        >
          {{ $t('schools_page.get_my_solution') }}
        </CTAButton>
        <CTAButton
          v-if="isAnonymous()"
          class="cta-button"
          @clickedCTA="createAccountModalOpen = true"
        >
          {{ $t('hackstack_cyber_page.cta_explore') }}
        </CTAButton>
        <CTAButton
          v-else
          href="/teachers/guide/hackstack/cyber"
          class="cta-button"
        >
          {{ $t('hackstack_cyber_page.cta_explore') }}
        </CTAButton>
      </template>
    </HackstackHero>
    <HackstackFeaturesSection
      variant="cyber"
      :title="$t('hackstack_cyber_page.features_title')"
      :features="cyberFeatures"
    />
    <HackstackPathwaySection
      variant="cyber"
      :title="$t('hackstack_cyber_page.pathways_title')"
      :items="cyberModules"
    >
      <template #cta>
        <CTAButton
          v-if="isAnonymous()"
          class="pathways__cta"
          @clickedCTA="createAccountModalOpen = true"
        >
          {{ $t('schools_page.free_teacher_account') }}
        </CTAButton>
        <CTAButton
          v-else
          href="/teachers/guide/hackstack/cyber"
          class="pathways__cta"
        >
          {{ $t('home_v3.try_it_now') }}
        </CTAButton>
        <p class="pathways__subtitle">
          {{ $t('schools_page.trial_the_curriculum') }}
        </p>
      </template>
      <template #tail>
        <CTAButton
          href="https://docs.google.com/spreadsheets/d/1CdVBDHLEoY9cUxGgfuQzmEKrFg9Ip4imURIX77Cna8c/edit?gid=1288109106#gid=1288109106"
          target="_blank"
          rel="noopener noreferrer"
          class="standards-cta"
        >
          {{ $t('hackstack_cyber_page.standards_cta') }}
        </CTAButton>
      </template>
    </HackstackPathwaySection>
    <HackstackInfoCard
      variant="cyber"
      image-src="/images/pages/hackstack/cyber/safety-shield.png"
      image-alt=""
      :title="$t('hackstack_cyber_page.safety_title')"
      :text="$t('hackstack_cyber_page.safety_text')"
      link-href="https://docs.google.com/document/d/1OfQw0B841BUu7iABRlS-UXMbHDb9npYLvOPgcsdIiH0"
      :link-text="$t('hackstack_page.learn_more')"
    />
    <HackstackFaq
      :title="$t('schools_page.faq_header')"
      :faq-items="faqItems"
      :see-more-text="$t('schools_page.faq_see_more')"
    />
    <backbone-modal-harness
      ref="createAccountModal"
      :modal-view="CreateAccountModal"
      :open="createAccountModalOpen"
      :modal-options="{ startOnPath: 'teacher' }"
      @close="createAccountModalOpen = false"
    />
  </div>
</template>

<script>
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import BackboneModalHarness from 'app/views/common/BackboneModalHarness.vue'
import CreateAccountModal from 'app/views/core/CreateAccountModal/CreateAccountModal.js'
import HackstackFaq from './shared/HackstackFaq.vue'
import HackstackFeaturesSection from './shared/HackstackFeaturesSection.vue'
import HackstackHero from './shared/HackstackHero.vue'
import HackstackInfoCard from './shared/HackstackInfoCard.vue'
import HackstackPathwaySection from './shared/HackstackPathwaySection.vue'
import { buildHackstackFaqItems } from './shared/hackstackFaqItems.js'
import { mapGetters, mapActions } from 'vuex'

export default Vue.extend({
  name: 'PageHackstackCyber',
  components: {
    CTAButton,
    BackboneModalHarness,
    HackstackFaq,
    HackstackFeaturesSection,
    HackstackHero,
    HackstackInfoCard,
    HackstackPathwaySection,
  },
  data () {
    return {
      CreateAccountModal,
      createAccountModalOpen: false,
      faqItems: buildHackstackFaqItems(this.$t.bind(this)),
      alignmentBadges: [
        {
          src: '/images/pages/hackstack/cyber/comptia-security-plus.png',
          alt: 'CompTIA Security+',
        },
        {
          src: '/images/pages/hackstack/cyber/ap-collegeboard.jpg',
          alt: 'AP College Board',
        },
      ],
    }
  },
  computed: {
    ...mapGetters({
      isPaidTeacher: 'me/isPaidTeacher',
    }),
    isPaidTeacherAccount () {
      return this.isTeacher() && this.isPaidTeacher
    },
    cyberFeatures () {
      return [1, 2, 3].map(featureNum => ({
        key: `feature-${featureNum}`,
        image: [
          '/images/pages/hackstack/cyber/pillar-certification.png',
          '/images/pages/hackstack/cyber/pillar-writing.png',
          '/images/pages/hackstack/cyber/pillar-delivery.png',
        ][featureNum - 1],
        title: this.$t(`hackstack_cyber_page.feature_${featureNum}_title`),
        description: this.$t(`hackstack_cyber_page.feature_${featureNum}_desc`),
      }))
    },
    cyberModules () {
      return [1, 2, 3, 4, 5].map(moduleNum => ({
        key: `module-${moduleNum}`,
        label: `${this.$t('hackstack_cyber_page.module')} ${moduleNum}`,
        title: this.$t(`hackstack_cyber_page.module_${moduleNum}_title`),
        description: this.$t(`hackstack_cyber_page.module_${moduleNum}_desc`),
        tagText: this.$t(`hackstack_cyber_page.module_${moduleNum}_tag`),
        imageSrc: `/images/pages/hackstack/cyber/module-${moduleNum}.jpg`,
        iconSrc: `/images/pages/hackstack/cyber/module-icon-${moduleNum}.png`,
      }))
    },
  },
  async created () {
    if (typeof me !== 'undefined' && me.isTeacher()) {
      await this.fetchTeacherPrepaids({ teacherId: me.get('_id') })
    }
  },
  methods: {
    ...mapActions({
      fetchTeacherPrepaids: 'prepaids/fetchPrepaidsForTeacher',
    }),
    isAnonymous () {
      return typeof me === 'undefined' || me.isAnonymous()
    },
    isTeacher () {
      return typeof me !== 'undefined' && me.isTeacher()
    },
    onGetSolution () {
      window.open('/schools?openContactModal=true', '_blank', 'noopener,noreferrer')
    },
  },
})
</script>

<style>
#page-container {
  max-width: 100vw;
  overflow-x: hidden;
}
</style>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

#page-hackstack-cyber {
  ::v-deep {
    @extend %frontend-page;
  }

  gap: 0;
  background: #021E27;
}
</style>
