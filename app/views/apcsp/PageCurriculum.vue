<template lang="pug">
  #apcsp-curriculum-page
    .container-fluid
      .header
        .container-fluid.header-part-top
          .width-container.text-center
            .row
              .col-lg-12
                h1.text-h1 {{ $t('apcsp_marketing.page_title') }}
        .container-fluid.header-part-bottom(ref="header")
          .width-container.text-center
            .row
              .col-lg-12
                p.text-p {{ $t('apcsp_marketing.page_description_endorsed') }}

    #nolicense.container-fluid(v-if="!hasLicense")
      .width-container.row.border-red
        .col.col-lg-12
          h2.text-h2 {{ $t('apcsp_curriculum.no_license') }}
          a.btn.btn-primary.btn-lg.btn-shadow(href="https://forms.gle/RAA37R3FJojZ7bfQ7" target="_blank") {{ $t('apcsp_curriculum.request_license') }}

    #greed-banner.container-fluid(v-if="hasLicense")
      .width-container.row.border-yellow
        .col.col-lg-12
          h2.text-h2(v-html="$t('apcsp_curriculum.access_syllabus', i18nData)")
          a.btn.btn-primary.btn-lg.btn-shadow(href="https://files.codecombat.com/docs/apcsp/CodeCombat_APCSP_Syllabus.pdf" target="_blank") {{ $t('apcsp_marketing.syllabus') }}
        .col.col-lg-12
          h2.text-h2(v-html="$t('apcsp_curriculum.access_pacing_guide', i18nData)")
          a.btn.btn-primary.btn-lg.btn-shadow(href="https://files.codecombat.com/docs/apcsp/CodeCombat_APCSP_Pacing_Guide_Full.pdf" target="_blank") {{ $t('apcsp_marketing.pacing_guide') }}


    #resources.width-container(v-if="hasLicense")
      .width-container.row
        .col-lg-12
          h2.text-h2 {{ $t('apcsp_curriculum.resources') }}
      .width-container.row-boxes-container
        .col-yellow-border.col-yellow-border-double
          h3.text-h3 Big Idea: Algorithms and Programming
            span
              | !{' '}(AAP)
          .row
            .col-lg-3.col-sm-6.col-xs-12
              h4.text-h4 Computer Science 1
              h5.text-h5 (6 Quests, 10 Sessions)
              ul
                li
                  a(href="https://docs.google.com/presentation/d/1-N9FzM0tvZrAFg8xYqhaKjkA2hZj8NsYMFTIP-VjrNw/edit?usp=sharing") Quest 0: Getting Started
                  span (CRD)
              li
                a(href="https://docs.google.com/presentation/d/1aw95kI5UIBjWIDHYMHANkOzOkgLGW3rJiyze7kW5uIA/edit?usp=sharing") Quest 1: Syntax & Sequences
                span (AAP)
              li
                a(href="https://docs.google.com/presentation/d/1BzohUmlboC_yugSpaEcc5-mcz1hKWwUkLGYKD4opo5c/edit?usp=sharing") Quest 2: Arguments & Properties
                span (AAP)
              li
                a(href="https://docs.google.com/presentation/d/1kqvX08F_eoac52B_xYD9Tx15gCJURw6F2SoPR8micak/edit?usp=sharing") Quest 3: While Loops
                span (AAP)
              li
                a(href="https://docs.google.com/presentation/d/1VEkhdZqAdaRfKlP4HQ-a7ugCCjVdez-m35GSUZ-d2HM/edit?usp=sharing") Quest 4: Variables
                span (AAP)
              li
                a(href="https://docs.google.com/presentation/d/1DpWgbbxCJKi7u4ClrPhcoPAhRyJ_WlVdzcUx4IzFT9I/edit?usp=sharing") Quest 5: Capstone Project
                span (CRD, AAP)
            .col-lg-3.col-sm-6.col-xs-12
              h4.text-h4 Computer Science 2
              h5.text-h5 (8 Quests, 15 Sessions)
              ul
                li
                  a(href="https://docs.google.com/presentation/d/1nHsP3MyLF3Ff44bBixvKtqQhL4NiZ_dbTmBE5xh7NL8/edit?usp=sharing") Quest 1: Coordinate Systems
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1g54vcO_c1exc901HYkZdUgEiBUrhvs7DjzXmg6nwphw/edit?usp=sharing") Quest 2: Conditional Statements (If)
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1eoR5GC-HGISOqvZXUle6PvRtQm5TfXQLR8ExTvfH6nw/edit?usp=sharing") Quest 3: Conditional Statements (Else)
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1ZeDyRszf2ppNAZoBvAmSKCA7xyEBaRVgKOa9T-GWJcE/edit?usp=sharing") Quest 4: Nested Conditionals
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/16Y0MzRtwAFzajfaxs1UZbyQmgAMp6W5XSrjQlfsG1MU/edit?usp=sharing") Quest 5: Functions
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/16JW7XFJC33n6mdbjujl3O89Tbbyrwhs4ai7gxM5AFCs/edit?usp=sharing") Quest 6: Functions with Parameters
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1sRA-UzcFIUqtKghiojvPKiTWXinJZ500KJ-gU9T1Oiw/edit?usp=sharing") Quest 7: Events
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1Z2eV0DBoJsu0Mf85DSdbyzwH5YJyaPT3eEuajfbieTE/edit?usp=sharing") Quest 8: Capstone Project
                  span (CRD, AAP)
            .col-lg-3.col-sm-6.col-xs-12
              h4.text-h4 Computer Science 3
              h5.text-h5 (10 Quests, 15 Sessions)
              ul
                li
                  a(href="https://docs.google.com/presentation/d/12VQOlwrpxnjx5OP9gnLV3k_dHrCjrrVPCLFXZ1XMrVg/edit?usp=sharing") Quest 1: Concatenation & Arithmetic
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1Pqjo2CIMTY1CaH9PkRP5PRX-qTiXG8pxyZKZB9ewtL8/edit?usp=sharing") Quest 2: Properties Revisited
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1rI4-eAdUojJWIY3LMp9GrGhp4KgzgzSDmVxI2E1h3Y4/edit?usp=sharing") Quest 3: Functions that Return
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1uBcZGlWCRV8sK42iq_XX-Oe6L9gmtTfr0w1A7GFTp1U/edit?usp=sharing") Quest 4: Comparison Operators
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1DCZhZyBR5ulhU4neDy3b9h8Yuo6kuDyg-0mRMTW6eHU/edit?usp=sharing") Quest 5: Logical Operators
                  span (CRD, AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1CUlJR21NNsJkiEJAYRBGw8j36Wx5jMye2Y7DLbLxsMU/edit?usp=sharing") Quest 6: Relative Movement
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/11eilsfqhH-V-_4bYsLnTMwuSq-z7R3LlcBS4x_j5WUs/edit?usp=sharing") Quest 7: Time & Health
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1rk6XHIQDoBGjhg-TLaoyX5xLwPT82m0ibGKyf2gDurs/edit?usp=sharing") Quest 8: Break & Continue
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/19-iBbPoKKnmgE084O9E34UuVPTc4uPTcdtBp0LYPO3U/edit?usp=sharing") Quest 9: Simulations
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/18am_Yw5y0L4X7rQ5xQaBmG3C3DjDshQkiLcGosMgxWQ/edit?usp=sharing") Quest 10: Capstone Project
                  span (CRD, AAP)
            .col-lg-3.col-sm-6.col-xs-12
              h4.text-h4 Computer Science 4
              h5.text-h5 (8 Quests, 15 Sessions)
              ul
                li
                  a(href="https://docs.google.com/presentation/d/1BxIXCxk61_fMh-8kAjZz9VZPWUN9tUB-BEY0QGybl60/edit?usp=sharing") Quest 1: While Loop Conditions
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1BFfCt-MyNi-PTkMR6pt5R7AP0BGn0Q6GfPWEWAjgUno/edit?usp=sharing") Quest 2: Lists
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1yr6gxCS-mnAm7d6ul3xzk49WvBROmRwFjcjkdNrsRi4/edit?usp=sharing") Quest 3: Using Lists
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1BwlPl8fHKfn6wUs3pMLNaIxLcTZ-CyYgh2GcRpv6k5g/edit?usp=sharing") Quest 4: Revisiting Movement
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1R-_gHpRChRsW5rZBXG7lKQlxvdoeg8RWPV5gKtesTE0/edit?usp=sharing") Quest 5: For Loops
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1AW9A_0YkPh2FzDxtsoNU-zLAmmHB3atEjyyJtdjtqMY/edit?usp=sharing") Quest 6: Common Algorithms
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1pjCDkfzuwzogcUGGYNN1yAGt7ht2PjxzNEiexrehOSQ/edit?usp=sharing") Quest 7: Undecidable Problems
                  span (AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1M3SohK7tdXIvnPoxedhOHdZZq3RK5X0vvgWNcLpuKRI/edit?usp=sharing") Quest 8: Capstone Project
                  span (CRD, AAP)

        .col-yellow-border
          h3.text-h3 Big Idea: Creative Development
            span
              | !{' '}(CRD)
          .row
            .col-lg-12
              h4.text-h4 Creative Development
              h5.text-h5 (4 Quests, 16 Sessions)
              ul
                li
                  a(href="https://docs.google.com/presentation/d/1SMF6n9TBpRZmUR3VKG6rHFP8_MIa0J2rLq-wtul3y6o") Quest 1: Create Task Overview
                  span (CRD, AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1lH25awu3jBh0EWKl8mtndwMRpmpfxbHmaQUDZn-La94") Quest 2: Written Response Overview
                  span (CRD, AAP)
                li
                  a(href="https://docs.google.com/presentation/d/15xgiGEhmgHXy_SQ70pXJ8Q-Csf_5_m9KQD7PFooQZC0") Quest 3: Pacing the Create Task
                  span (CRD, AAP)
                li
                  a(href="https://docs.google.com/presentation/d/1nBSoYNxz3Yj8VfSFI_r56gYQ1sigSfMSFcBuRW4YFz8") Quest 4: Create Task Submission
                  span (CRD)

        .col-yellow-border
          h3.text-h3 Big Idea: Computer Systems & Networks
            span
              | !{' '}(CSN)
          .row
            .col-lg-12
              h4.text-h4 Computer Systems & Networks
              h5.text-h5 (6 Quests, 15 Sessions)
              ul
                li
                  a(href="https://docs.google.com/presentation/d/1WyW5mdpwQl9oQsMYkFoMa_MDlBM2GJ_n0RzsdurjV3s/edit?usp=sharing") Quest 1: The Internet (Overview)
                  span (CSN)
                li
                  a(href="https://docs.google.com/presentation/d/1XG0Yju9mvSusiMNJL-PSJ10JmFG6D6l1OlTvnlDo5hY/edit?usp=sharing") Quest 2: The Internet (Routing)
                  span (CSN)
                li
                  a(href="https://docs.google.com/presentation/d/1ZVU3P5vYVmz37AIbnK1RNHFIeUOONNP5yvIkx73fx-A/edit?usp=sharing") Quest 3: The Internet (Packets)
                  span (CSN)
                li
                  a(href="https://docs.google.com/presentation/d/1VayHcuEmpR2bQXTyNTGvPl_7ictFmE6Mr4nMiY8d6Qc/edit?usp=sharing") Quest 4: World Wide Web vs. The Internet
                  span (CSN)
                li
                  a(href="https://docs.google.com/presentation/d/1vK-ydFZ5V8RdLUUrrMN_qOfGH2wb2sIBAeUyzqZlfzc/edit?usp=sharing") Quest 5: Parallel & Distributed Computing
                  span (CSN)
                li
                  a(href="https://docs.google.com/presentation/d/1Gy6qyJgjnwkKLrySXrI3dAgueCwzPTT4_vECx8qV0WE/edit?usp=sharing") Quest 6: Capstone Project
                  span (CSN, CRD)

        .col-yellow-border
          h3.text-h3 Big Idea: Data
            span
              | !{' '}(DAT)
          .row
            .col-lg-12
              h4.text-h4 Data
              h5.text-h5 (9 Quests, 16 Sessions)
              ul
                li
                  a(href="https://docs.google.com/presentation/d/1svmcKu3wZp-9SprI8Cr6vvDAWJAVQd8Hq-NAteMZ6Zw/edit?usp=sharing") Quest 1: Digital Information (Text)
                  span (DAT)
                li
                  a(href="https://docs.google.com/presentation/d/1lRAc4tTktQ23tErcJ1I86BbGlPzw5kQT7yMPYrUuD3U/edit?usp=sharing") Quest 2: Digital Information (Images)
                  span (DAT)
                li
                  a(href="https://docs.google.com/presentation/d/1oEy0Yf6lM-jEesFM1KxdNiYvsTnnT06jTgOfV19A3wg/edit?usp=sharing") Quest 3: Digital Information (Sound)
                  span (DAT)
                li
                  a(href="https://docs.google.com/presentation/d/1_lu9brdyeAnikWRFoSY4X2TNVmN6YLb2wQrz38t57eU/edit?usp=sharing") Quest 4: Limitations of Digital Representations
                  span (DAT)
                li
                  a(href="https://docs.google.com/presentation/d/1Hcbyt_ajAFE4OuDtaEMBrm_W5yohxnu_YEVwNN4VAQY/edit?usp=sharing") Quest 5: Data Compression
                  span (DAT)
                li
                  a(href="https://docs.google.com/presentation/d/1TtiUIsaE6CdmIY66ZaomFuy5bsB3RXNKnZBSYTlDzMQ/edit?usp=sharing") Quest 6: Data Analysis (Sourcing Data)
                  span (DAT)
                li
                  a(href="https://docs.google.com/presentation/d/1AtE600bauP9GcX7PzOJEHQHJSSK6YAXL1uq5-xhzQq4/edit?usp=sharing") Quest 7: Data Analysis (Cleaning Data)
                  span (DAT)
                li
                  a(href="https://docs.google.com/presentation/d/1gopS2iWBBGNgAdTfSM7_7jGjKTSkDU3SqR7qaHVl7UA/edit?usp=sharing") Quest 8: Data Analysis (Processing Data)
                  span (DAT)
                li
                  a(href="https://docs.google.com/presentation/d/1oKcDHeZ9uw5D6Pls9Q9F5ZprUAb5RUb_cXA-VK6kVb0/edit?usp=sharing") Quest 9: Capstone Project
                  span (DAT, CRD)

        .col-yellow-border
          h3.text-h3 Big Idea: Impact of Computing
            span
              | !{' '}(IOC)
          .row
            .col-lg-12
              h4.text-h4 Impact of Computing
              h5.text-h5 (9 Quests, 18 Sessions)
              ul
                li
                  a(href="https://docs.google.com/presentation/d/1XAar0ipd57A-NobEmLQIjPWVzeYAK8g_C7TVwQNCi1c/edit?usp=sharing") Quest 1: Computing Innovations
                  span (IOC, CRD)
                li
                  a(href="https://docs.google.com/presentation/d/1XnVULZHTRjUOACFlhAP7xNECoNGYV3BE7BShpUJXCgk/edit?usp=sharing") Quest 2: Digital Divide
                  span (IOC)
                li
                  a(href="https://docs.google.com/presentation/d/1h7mDmC7c5C2RwFHEcsxO5q4ybCbkSUnMU2i4IbdBw7g/edit?usp=sharing") Quest 3: Bias
                  span (IOC)
                li
                  a(href="https://docs.google.com/presentation/d/1Ht0232EgdfQbkGKUZrkNbUQ8Fw47Pq5qXLwX7A_Pp94/edit?usp=sharing") Quest 4: Citizen Science
                  span (IOC)
                li
                  a(href="https://docs.google.com/presentation/d/1szYpRP4-rkxoC6MJSRO-D-uk_9fQsUCGjvnhhTgXZM8/edit?usp=sharing") Quest 5: Legal & Ethical Concerns
                  span (IOC)
                li
                  a(href="https://docs.google.com/presentation/d/1-G2AL26y0CsAInAsY3CVQaQkFcEhBlSK0Cd7Ry3fU_A/edit?usp=sharing") Quest 6: Personal Identifiable Information
                  span (IOC)
                li
                  a(href="https://docs.google.com/presentation/d/1qgirFVdsLUYYDqYEnkm25jBoP4QS5BF2ggxjyjqa-1c/edit?usp=sharing") Quest 7: Protecting Digital Information
                  span (IOC)
                li
                  a(href="https://docs.google.com/presentation/d/14re2luFv1EMbgszdp2NvH6g2JMpOUxKM95cDz5I2nq4/edit?usp=sharing") Quest 8: Encryption & Decryption
                  span (IOC)
                li
                  a(href="https://docs.google.com/presentation/d/1CUUBkovwJpnNhYcONg8hwM-rfZLShBKvtlxrQ8ftOfU/edit?usp=sharing") Quest 9: Capstone Project
                  span (IOC, CRD, AAP, DAT)
        .col-yellow-border.col-yellow-border-double
          h3.text-h3 Big Idea: Examp Prep
          .row
            .col-lg-9
              h4.text-h4 Examp Prep
              h5.text-h5 (5 Quests, 10 Sessions)
              ul
                li
                  a(href="https://docs.google.com/presentation/d/1s3exkP4QVT6pq1fIVKFjVrKoGPv_kSOoaZqIfN4jUNA/edit?usp=sharing") Quest 1: Introduction to the AP CSP Exam Multiple Choice Format
                li
                  a(href="https://create.kahoot.it/groups/ed7457aa-8b38-4e17-81d9-2305533da20d/join?inviteCode=jfj71f9h3vm6mk6rdthc80922to250g9e2kikghked9v7i12ullnc98nl228jce2lhe8n90vurde") Quests 2 - 5: Kahoot! Quiz Practice
            .col-lg-3
              img(src="/images/pages/apcsp/kahoot-logo.png")

    #the-college-board.width-container.row.image-row
      .col.col-lg-12.text-box
        .content.row
          .col-lg-9
            .content {{ $t('apcsp_marketing.coco_recognized_blurb') }}
          .col-lg-3
            img(src="/images/pages/apcsp/APCSP_ProviderBadge_lg.png")

    #professional-development.container-fluid.container-fluid-gradient(v-if="hasLicense")
      .width-container.row
        .col.col-lg-12
          h1.text-h1 {{ $t('apcsp_marketing.professional_development') }}
      .width-container.row
        .col.col-lg-12
          .row-white
            .row
              .col.col-md-6.col-xs-12
                img.image18(src="/images/pages/apcsp/IMAGE18.png")
              .col.col-md-6.col-xs-12
                p.text-p(v-html="$t('apcsp_curriculum.professional_development_description', i18nData)")
                a(href="http://edappl.com" target="_blank")
                  img(src="/images/pages/apcsp/edapp-logo.png")
                p.text-p(v-html="$t('apcsp_curriculum.contact', i18nData)")

    #more-information.container-fluid
      .width-container.row.text-center
        .col.col-md-12
          h3.text-h3 For More Information
          .btn.btn-primary.btn-lg.btn-shadow.uppercase(@click="showModal=true") Get in touch

    modal-apcsp-contact(v-if="showModal" @close="showModal = false")
</template>

<script>
import { mapActions, mapGetters } from 'vuex'

import ModalAPCSPContact from 'app/components/common/ModalAPCSPContact.vue'

export default Vue.extend({
  components: {
    'modal-apcsp-contact': ModalAPCSPContact
  },

  async created () {
    this.me = me
    if (me.isTeacher()) {
      this.updateLicenseStatus()
    }
  },
  data () {
    return {
      showModal: false,
      icons: [
        {
          img: '/images/pages/apcsp/small-images/01-coding-levels.png',
          title: $.i18n.t('apcsp_marketing.icons_coding_levels')
        },
        {
          img: '/images/pages/apcsp/small-images/02-lesson-slidesB2.png',
          title: $.i18n.t('apcsp_marketing.icons_lesson_slides')
        },
        { img: '/images/pages/apcsp/small-images/kahoot1.png', title: $.i18n.t('apcsp_marketing.icons_kahoot') },
        {
          img: '/images/pages/apcsp/small-images/04-classroom-instructions.png',
          title: $.i18n.t('apcsp_marketing.icons_classroom_instructions')
        },
        {
          img: '/images/pages/apcsp/small-images/05-weeks-of-curriculum.png',
          title: $.i18n.t('apcsp_marketing.icons_weeks_of_curriculum')
        },
        {
          img: '/images/pages/apcsp/small-images/06-project-activities.png',
          title: $.i18n.t('apcsp_marketing.icons_project_activities')
        },
        {
          img: '/images/pages/apcsp/small-images/07-game-learning.png',
          title: $.i18n.t('apcsp_marketing.icons_game_learning')
        },
        {
          img: '/images/pages/apcsp/small-images/08-chromebook-compatibleB3.png',
          title: $.i18n.t('apcsp_marketing.icons_chromebook_compatible')
        },
        {
          img: '/images/pages/apcsp/small-images/08-text-coding.png',
          title: $.i18n.t('apcsp_marketing.icons_text_coding')
        },
        {
          img: '/images/pages/apcsp/small-images/10-standards-aligned.png',
          title: $.i18n.t('apcsp_marketing.icons_standards_aligned')
        },
      ],
      units: Array.from(Array(9).keys()).map((i) => ({
            title: $.i18n.t(`apcsp_marketing.course_outline_unit_${i + 1}`),
            course: $.i18n.t(`apcsp_marketing.course_outline_course_${i + 1}`),
            description: $.i18n.t(`apcsp_marketing.course_outline_description_${i + 1}`)
          })
      ),
      hasLicense: false
    }
  },
  computed: {
    ...mapGetters({
      teacherPrepaids: 'prepaids/getPrepaidsByTeacher'
    }),
    i18nData () {
      return {
        syllabus: `<a href='https://files.codecombat.com/docs/apcsp/CodeCombat_APCSP_Syllabus.pdf' target='_blank'>${$.i18n.t('apcsp_curriculum.college_board_approved_syllabus')}</a>`,
        pacing_guide: `<a href='https://files.codecombat.com/docs/apcsp/CodeCombat_APCSP_Pacing_Guide${this.hasLicense ? '_Full' : ''}.pdf' target='_blank'>${$.i18n.t('apcsp_curriculum.pacing_guide')}</a>`,
        edapp: '<a href=\'https://www.edapp.com/\' target=\'_blank\'>edapp.com</a>',
        apcsp_email: '<a href=\'mailto:apcsp@codecombat.com\' target=\'_blank\'>apcsp@codecombat.com</a>',
        interpolation: { escapeValue: false }
      }
    }
  },
  methods: {
    ...mapActions({
      fetchTeacherPrepaids: 'prepaids/fetchPrepaidsForTeacher'
    }),
    async updateLicenseStatus () {
      if (me.isPaidTeacher()) {
        this.hasLicense = true
        return
      }
      await this.fetchTeacherPrepaids({ teacherId: me.get('_id') })
      const prepaids = this.teacherPrepaids(me.get('_id'))
      if (prepaids.available.length > 0) {
        this.hasLicense = true
      }
    }
  }
})
</script>

<style lang='scss' scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";

$teal-dark: #0E4C60;
$apcsp-marketing-body-font: 'Arvo';

.text-h1 {
  font-family: $apcsp-marketing-body-font;
  font-style: normal;
  font-weight: 700;
  font-size: 60px;
  line-height: 103%;
  text-align: center;
  letter-spacing: 1.96px;
  color: #FCBB00;
  word-break: break-word;
}

.text-h2 {
  font-family: $apcsp-marketing-body-font;
  font-style: normal;
  font-weight: 700;
  font-size: 33px;
  line-height: 188%;
  text-align: center;
  letter-spacing: 1.96px;
  color: #FFFFFF;
}

.text-h3 {
  font-family: $apcsp-marketing-body-font;
  font-style: normal;
  font-weight: 700;
  font-size: 28px;
  line-height: 38px;
  /* identical to box height, or 136% */
  color: $teal-dark;
}


.text-h5 {
  font-family: $apcsp-marketing-body-font;
  font-size: 32px;
  line-height: 38px;
  letter-spacing: 0.48px;
  font-weight: normal;
}

p, .text-p {
  font-family: 'Open Sans';
  font-style: normal;
  font-weight: 400;
  font-size: 24px;
  line-height: 30px;
  color: $teal-dark;
}

.btn-primary {
  background-color: $yellow-dark;
  border-radius: 9.5px;
  color: $pitch;
  font-weight: bold;
  font-size: 20px;
  line-height: 16px;
  min-width: 268px;
  @media (max-width: $screen-md) {
    min-width: 180px;
  }
  min-height: 50px;
  padding: 16px 36px;

  &:hover {
    background-color: $yellow-light;
    transition: background-color .35s;
  }
}

#apcsp-curriculum-page {
  overflow: hidden;
  margin-bottom: -50px;

  .row-white {
    background: white;
    border-radius: 20px;
  }

  .width-container {
    max-width: 1360px;
    @media (max-width: $screen-lg-min) {
      max-width: 1040px;
    }

    @media (max-width: $screen-md) {
      max-width: 742px;
    }

    float: unset;
    margin: 0 auto;
  }

  .header {
    .header-part-top {
      background-size: cover;
      background-position: center center;
      background-image: url(/images/pages/apcsp/apcsp-header-image.jpg);
      height: 600px;
      display: flex;
      align-items: center;
      justify-content: center;

      .text-h1 {
        font-family: $apcsp-marketing-body-font;
        font-style: normal;
        font-weight: 700;
        font-size: 64px;
        line-height: 122%;

        display: flex;
        align-items: center;
        text-align: center;
        letter-spacing: 1.96px;

        color: $yellow-dark;

        text-shadow: 0px 0px 20px #000000;
      }

      .text-h2 {
        margin-top: 21px;
      }
    }

    .header-part-bottom {

      .text-p {
        font-family: $apcsp-marketing-body-font;
        font-style: normal;
        font-weight: 700;
        font-size: 33px;
        line-height: 62px;
        /* or 188% */

        text-align: center;
        letter-spacing: 2.58px;

        color: #FFFFFF;

        padding-top: 35px;
        padding-bottom: 12px;
      }

      background: linear-gradient(118.13deg, $teal-dark 0%, $forest 100%);
    }

    .row {
      padding: 30px 0;

      .pixelated {
        font-family: "lores12ot-bold", "VT323";
      }
    }
  }


  .row-top-margin {
    margin-top: 30px;
  }


  .container-fluid-gradient {
    background: linear-gradient(90deg, $teal-dark 19.5%, $forest 110.94%);
    overflow: hidden;

    .heading-text {
      font-weight: 700;
      font-size: 24px;
      line-height: 125%;
      text-align: center;

      p, ::v-deep a {
        font-family: $apcsp-marketing-body-font;
        font-style: normal;
        font-weight: 700;
        color: $yellow-dark;
      }
    }
  }

  .image-row {
    .text-box {
      border: 10px solid $teal-dark;
      border-radius: 25px;
    }
  }


  .border-blue {
    border: 5px dashed $teal-dark;
    border-radius: 20px;
    padding: 90px;

    @media (max-width: $screen-sm) {
      padding: 20px 10px;
    }
  }

  .border-yellow {
    @extend .border-blue;
    border-color: $yellow-dark;
  }

  .border-red {
    @extend .border-blue;
    border-color: $burgundy;
  }

  #greed-banner {
    background: url(/images/pages/apcsp/greed_banner_bg.jpg);
    background-size: cover;
    background-position: left bottom;
    overflow: hidden;

    .width-container {
      margin: 90px auto 230px;

      h2 {
        ::v-deep a {
          color: #FCBB00;
          text-decoration: none;

          &:hover {
            text-decoration: underline;
          }
        }
      }

      .btn {
        filter: none;
        display: block;
        margin: 50px auto;
        max-width: 168px;
      }
    }
  }

  #nolicense {
    margin: 90px 0;
    h2 {
      color: $burgundy;
    }
    .btn {
      filter: none;
      display: block;
      margin: 50px auto;
      max-width: 168px;
    }
  }

  #more-information {
    margin-bottom: -50px;
    margin-top: 0;
    height: 566px;
    background: url(/images/pages/apcsp/alejandro-art.png);
    background-size: cover;
    background-position: center center;

    .row {
      display: flex;
      flex-direction: row;
      justify-content: center;
      align-items: center;
      height: 100%;
    }

    .text-h3 {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 700;
      font-size: 33px;
      line-height: 188%;
      text-align: center;
      letter-spacing: 1.96px;
      color: $teal-dark;
      margin-bottom: 40px;
    }
  }

  #the-college-board {
    margin-bottom: 90px;
    margin-top: 90px;

    @media (max-width: $screen-lg-min) {
      max-width: 724px;
    }

    .content {
      background: white;
      margin: 0 -15px;
      border-radius: 25px;
      padding: 35px 35px;
      text-align: left;

      font-family: 'Open Sans';
      font-style: normal;
      font-weight: 400;
      font-size: 24px;
      line-height: 30px;
      color: $teal-dark;

      &.row {
        @media (min-width: $screen-md) {
          display: flex;
          flex-direction: row;
          justify-content: center;
          align-items: center;
        }
      }
    }
  }

  #professional-development {
    margin-top: 0;
    padding-bottom: 90px;

    .text-h1 {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 700;
      font-size: 60px;
      line-height: 103%;
      text-align: center;
      letter-spacing: 1.96px;

      color: $yellow-dark;
      margin: 45px auto;
    }

    .text-p {
      font-family: 'Open Sans';
      font-style: normal;
      font-weight: 400;
      font-size: 24px;
      line-height: 125%;
      color: $teal-dark;

      + a img {
        margin: 15px 0;
      }
    }

    .row-white {
      padding: 90px 90px 60px 90px;

      @media (min-width: $screen-md) {
        .row {
          display: flex;
          flex-direction: row;
          justify-content: center;
          align-items: flex-start;
        }
      }

      img {
        max-width: 100%;
      }
    }
  }


  .btn-shadow {
    filter: drop-shadow(0px 0px 20px #000000);
  }

  .text-footer-blurb {
    font-family: $apcsp-marketing-body-font;
    font-style: normal;
    font-weight: 400;
    font-size: 24px;
    line-height: 125%;
    text-align: center;
    color: #1FBAB4;
    margin: 67px auto;
  }

  .btn-talk {
    background-color: #1FBAB4;
    text-transform: uppercase;
    transition: background-color .35s;

    &:hover {
      background-color: #2dcec8;
    }
  }

  .fostering-confidence {
    @media (min-width: $screen-md) {
      transform: translateX(80px);
    }
  }

  .accessible-real-world {
    margin-top: 100px;
  }

  #resources {
    margin-top: 90px;

    .row-boxes-container {
      display: flex;
      flex-wrap: wrap;
      gap: 45px;
    }

    .col-yellow-border {


      border: 2px solid #FCBB00;
      border-radius: 20px;
      padding: 30px;

      .text-h2 {
        font-family: 'Arvo';
        font-style: normal;
        font-weight: 700;
        font-size: 33px;
        line-height: 62px;
        /* identical to box height, or 188% */

        text-align: center;
        letter-spacing: 2.58px;

        color: #0E4C60;
      }

      .text-h3 {
        font-family: 'Arvo';
        font-style: normal;
        font-weight: 700;
        font-size: 26px;
        line-height: 30px;
        /* identical to box height, or 115% */
        color: #0E4C60;
      }

      .text-h4 {
        font-family: 'Open Sans';
        font-style: normal;
        font-weight: 700;
        font-size: 20px;
        line-height: 30px;
        /* or 150% */
        color: #0E4C60;
      }

      .text-h5 {
        font-family: 'Open Sans';
        font-style: normal;
        font-weight: 400;
        font-size: 17px;
        line-height: 30px;
        /* or 176% */
        color: #0E4C60;
      }

      li {
        a {

          font-family: 'Open Sans';
          font-style: normal;
          font-weight: 400;
          font-size: 17px;
          line-height: 30px;
          /* or 176% */

          text-decoration-line: underline;

          color: #0E4C60;
        }

        span {
          padding-left: 0.5em;
          font-family: 'Open Sans';
          font-style: normal;
          font-weight: 700;
          font-size: 17px;
          line-height: 30px;
          /* or 176% */
          color: #FCBB00;
        }
      }
    }

    .col-yellow-border {
      width: calc(50% - 45px / 2);
      @media (max-width: $screen-md) {
        width: 100%;
      }
    }

    .col-yellow-border-double {
      width: 100%;
    }

    .text-h2 {
      font-family: 'Arvo';
      font-style: normal;
      font-weight: 700;
      font-size: 33px;
      line-height: 62px;
      /* identical to box height, or 188% */

      text-align: center;
      letter-spacing: 2.58px;

      color: #0E4C60;
      margin-bottom: 48px;
    }

    .text-h3 {
      font-family: 'Arvo';
      font-style: normal;
      font-weight: 700;
      font-size: 26px;
      line-height: 30px;
      color: #0E4C60;
      margin-bottom: 45px;

      span {
        color: #FCBB00;
      }
    }
  }

}


.bubble-img-container {
  position: relative;
  width: 480px;

  @media (min-width: $screen-md) and (max-width: $screen-lg-min) {
    width: 335px;
    margin-left: 130px;
    margin-top: 30px;
  }

  @media (max-width: $screen-md) {
    margin: 0 auto 90px;
  }

  aspect-ratio: 8 / 5;
  z-index: 1;

  .img-bg {
    position: absolute;
    right: -2%;
    top: -39%;
    z-index: -1;
    width: 129.1667%;
  }

  .img-picture {
    width: 100%;
    position: absolute;
    top: 0;
    left: 0;
    z-index: 2;
    border-radius: 20px;
  }

  &.exam {
    @media (min-width: $screen-md) and (max-width: $screen-lg-min) {
      margin-left: -106px;
    }

    .img-bg {
      right: -27.2%;
      top: -19.7%;
      width: 142.291667%;
    }
  }

  &.realworld {
    @media (min-width: $screen-md) and (max-width: $screen-lg-min) {
      margin-left: 122px;
      margin-top: -5px;
    }

    .img-bg {
      right: -16.2%;
      top: -3.2%;
      width: 138.958333%;
    }
  }
}

.uppercase {
  text-transform: uppercase;
}

.image18 {
  border-radius: 25px;
}
</style>
