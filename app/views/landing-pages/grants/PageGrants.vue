
<template>
  <div id="page-grants" class="content-content">
    <div class="content-layout-header container-fluid">
      <div class="content-header-sec">
        <div class="content-header">
          <p class="content-grants-and-funding-g">Grants and Funding Guide</p>
          <div class="container">
            <div class="container sec-divider-container">
              <img src="/images/pages/grants/sec-divider-header.svg" />
            </div>
          </div>
          <p class="content-looking-for-funding">
            <b>Looking for funding but don’t know where to start?</b>
            Use our guide to find and apply for the perfect Computer Science and
            STEM grants.
          </p>
        </div>
        <div class="content-outline" />
      </div>
    </div>
    <div class="container">
      <div class="content-body">
        <div class="content-grants-template-sec">
          <div class="content-getting-started-details">
            <div class="content-text-getting-started">
              <p class="content-getting-started">Getting Started</p>
              <p class="content-as-you-begin-your-gr">
                As you begin your grant and funding efforts, you will need to:
              </p>
            </div>
            <div class="content-frame-1x">
              <div class="content-frame-8x">
                <div class="content-frame-step-box">
                  <div class="content-frame-7x">
                    <div class="content-frame-3x">
                      <p class="content-component">1</p>
                      <div class="content-plan"></div>
                    </div>
                  </div>
                  <p class="content-step-text">
                    Decide on how you will use the funds
                  </p>
                </div>
                <div class="step-arrow-container">

                </div>
                <div class="content-frame-step-box">
                  <div class="content-frame-3x">
                    <p class="content-component">2</p>
                    <div class="content-search"></div>
                  </div>
                  <p class="content-step-text">
                    Find funding sources that match your goals
                  </p>
                </div>
                <div class="step-arrow-container">

                </div>
                <div class="content-frame-step-box">
                  <div class="content-frame-3x">
                    <p class="content-component">3</p>
                    <div class="content-apply"></div>
                  </div>
                  <p class="content-step-text">
                    Collect the content you’ll need for the application
                  </p>
                </div>
              </div>
            </div>
          </div>
          <div class="content-template-sec">
            <div class="content-template-1sec">
              <div class="content-template-cta">
                <div class="content-text-template">
                  <p class="content-grant-application-te">
                    Grant Application Template
                  </p>
                  <p class="content-grant-applications-o">
                    Grant applications often ask about your CS curriculum
                    plans and objectives. Use this template to help plan out
                    your responses.
                  </p>
                </div>
                <div class="content-button-template">
                  <a class="btn btn-primary btn-lg"
                    href="/images/pages/grants/GrantApplicationTemplate.pdf"
                    target="_blank">Download the Template</a>
                </div>
              </div>
              <div class="content-template-visual">&nbsp;</div>
            </div>
          </div>
          <div class="content-frame-1x-2">
            <p class="content-explore-more-tips-an">
              Explore more tips and tricks on how to make the most of our
              template during your application process!
            </p>
            <carousel-component :items="carouselItems" :showTabs="true" :showDots="true"></carousel-component>
          </div>
        </div>

        <div class="content-layout-need-more-help">
          <div class="content-button-need-help">
            <a class="btn btn-primary btn-lg" @click="openModal(forms.needMoreHelp)">Need more help?</a>
          </div>
        </div>

        <div class="container sec-divider-container">
          <img src="/images/pages/grants/sec-divider.svg" />
        </div>
        <div>
          <div class="content-grants-list-sec">
            <div class="content-finding-grants-text">
              <p class="content-finding-grants">Finding Grants</p>
              <p class="content-not-sure-where-to-lo">
                Not sure where to look for grants? Check out these recommended
                resources!
              </p>
            </div>
            <div class="content-list-tabs">
              <div class="content-grantsgov-sec">
                <div class="content-grantsgov-visual">
                  <div class="content-grantsgov-logobg">
                    <div class="content-grantsgov-logo" />
                  </div>
                </div>
                <div class="content-grantsgov-cta">
                  <div class="content-text-grantsgov">
                    <p class="content-grants-gov">Grants.gov</p>
                    <p class="content-grants-gov-is-ahub">
                      Grants.gov is a hub for all federal grants. The searchable
                      database provides lots of filtering options around timing
                      and eligibility.
                    </p>
                  </div>
                  <div class="content-button-grantsgov">
                    <a class="btn btn-primary btn-lg" href="https://www.grants.gov/web/grants/search-grants.html"
                      target="_blank">Visit Grants.gov</a>
                  </div>
                </div>
              </div>
              <div class="content-curated-list-sec">
                <div class="content-curated-list-visual"></div>
                <div class="content-curated-list-cta">
                  <div class="content-text-curated-list">
                    <p class="content-code-combats-curated">
                      CodeCombat's Curated List
                    </p>
                    <p class="content-our-curated-list-of">
                      Our curated list of searchable STEM grant resources can be
                      filtered by criteria that matters to you! This includes
                      grade level, requirements, deadlines, and more.
                    </p>
                  </div>
                  <div class="content-button-curated-list">
                    <a class="btn btn-primary btn-lg" @click="openModal(forms.visitGrants)">Visit Our List</a>
                  </div>
                </div>
              </div>
            </div>
          </div>

        </div>
        <div class="container sec-divider-container">
          <img src="/images/pages/grants/sec-divider.svg" />
        </div>


        <div class="content-layout-22">
          <div class="content-got-grant-sec">
            <div class="content-got-grant-text">
              <p class="content-got-agrant">Got a Grant?</p>
              <p class="content-congratulations-let">
                Congratulations, let's work together!
              </p>
            </div>
            <div class="content-got-grant-cta">
              <div class="content-share-story">
                <p class="content-we-dlove-to-learn-m">
                  We'd love to learn more about your grant success so that we
                  can help other teachers.
                </p>
                <div class="content-button-share-story">
                  <a class="btn btn-primary btn-lg" @click="openModal(forms.yourStory)">Share Your Story</a>
                </div>
              </div>
              <div class="content-explore-next-steps">
                <p class="content-let-sexplore-how-we">
                  Let's explore how we can use funding to kickstart your
                  CodeCombat experience.
                </p>
                <div class="content-button-explore-next-steps">
                  <a class="btn btn-primary btn-lg" @click="openModal(forms.nextSteps)">Explore Next Steps</a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <ModalComponent v-if="activeForm" :title="activeForm.title" :name="activeForm.name" :inputs="activeForm.inputs"
      :blurb="activeForm.blurb" :buttonLabel="activeForm.buttonLabel" @close="handleClose" />
  </div>
</template>

<script>
import CarouselComponent from './assets/CarouselComponent.vue';
import ModalComponent from './assets/ModalComponent.vue';
import { email, required } from 'vuelidate/lib/validators'


export default {
  components: {
    CarouselComponent,
    ModalComponent
  },

  data: () => {
    const i18nData = {
      'sign-up': `<a href="https://codecombat.com/parents">${$.i18n.t('roblox_landing.bottom_blurb_sign_up')}</a>`,
      'reach-out': `<a href="https://codecombat.com/partners">${$.i18n.t('roblox_landing.bottom_blurb_reach_out')}</a>`,
      interpolation: { escapeValue: false }
    }

    const defaultInputs = [
      {
        type: 'text',
        label: 'Full Name',
        validations: { required },
        name: 'full-name'
      },
      {
        type: 'text',
        label: 'Organization\'s Name',
        validations: { required },
        name: 'organization'
      },
      {
        type: 'text',
        label: 'Job Title',
        validations: {},
        name: 'job-title'
      },
      {
        type: 'email',
        label: 'Email Address',
        validations: { required, email },
        name: 'email'
      }
    ]

    return {
      i18nData,
      carouselItems: [
        {
          title: 'Organization',
          image: '/images/pages/grants/organization.webp',
          text: "Use our template to outline and organize the essential sections of the application. Keeping an organized application helps reviewers focus on your content and enhances the credibility of your proposal. Sections can include an: <i>Introduction, Project Description, Goals, Methodology, Budget, and Evaluation</i>."
        },
        {
          title: 'Time Efficiency',
          image: '/images/pages/grants/time-efficacy.png',
          text: "Crafting a grant application from scratch can be time-consuming and labor-intensive. To save time, use the template’s example responses as a starting point. Then customize and tailor it to your specific project."
        },
        {
          title: 'Be Specific',
          image: '/images/pages/grants/be-specific.png',
          text: "Provide as much detail as you can in each section of the application. For example, check out the budgeting section of our template. We provide examples of how to list and describe each of your project expenses."
        },
        {
          title: 'Evaluation',
          image: '/images/pages/grants/evaluation.png',
          text: "Most grants will ask that you identify how you’ll measure the success of your project. Check out the implementation and evaluation sections of our template to see how you can describe your objectives and your assessment strategies."
        }
      ],
      forms: {
        needMoreHelp: {
          name: 'needMoreHelp',
          title: 'Need more help?',
          blurb: 'The grant application process can be confusing! We\'re here to help.',
          inputs: [
            ...defaultInputs,
            {
              name: 'kind-of-help',
              type: 'textarea',
              label: 'What kind of help do you need?',
              validations: { required }
            }
          ]
        },
        nextSteps: {
          name: 'nextSteps',
          title: 'Got a grant? Explore next steps!',
          blurb: 'Want to use grant funding to kickstart your CodeCombat classroom? We\'re here to help.',
          inputs: [
            ...defaultInputs,
            {
              name: 'questions',
              type: 'textarea',
              label: 'Do you have any specific questions about how to get started?',
              validations: {}
            }
          ]
        },
        yourStory: {
          name: 'yourStory',
          title: 'Got a grant? Share your story!',
          blurb: 'We would love to hear about your grant application journey so that we can support other teachers through the process.',
          inputs: [
            ...defaultInputs,
            {
              name: 'story',
              type: 'textarea',
              label: 'Share your story!',
              validations: { required }
            }
          ]
        },
        visitGrants: {
          name: 'visitGrants',
          title: 'Just a step away...',
          blurb: 'To better understand what resources to build for our educators, please fill out this quick form before accessing the grants list!',
          buttonLabel: 'View Grants List',
          inputs: [
            ...defaultInputs,
            {
              name: 'contact-number',
              type: 'text',
              label: 'Contact Number',
              validations: {}
            },
            {
              name: 'checkbox-title',
              type: 'label',
              label: 'I am here because (select all that apply):*',
              validations: {}
            },
            {
              name: 'interested-in-grants',
              type: 'checkbox',
              label: 'I am interested in grants',
              validations: {
                atleastOneChecked() {
                  return this['interested-in-grants'] || this['need-help'];
                }
              }
            },
            {
              name: 'need-help',
              type: 'checkbox',
              label: 'I need help writing grants',
              validations: {
                atleastOneChecked() {
                  return this['interested-in-grants'] || this['need-help'];
                }
              }
            }
          ]

        }
      },
      activeForm: null,
    }
  },

  methods: {
    openModal(form) {
      this.activeForm = form
    },
    handleClose() {
      this.activeForm = null;
    }
  }
}
</script>
 
<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "./content";
</style>
