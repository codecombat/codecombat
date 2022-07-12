<template>
  <div>
    <div class="library">
      <div class="container">
      <section class="row library__heading">
        <h2 class="library__heading-text pixel-text">
          Give your members access to the most engaging way to learn coding
        </h2>
        <button class="btn library__heading-btn btn-moon" @click="toggleLicenseModal">
          Contact Us
        </button>
      </section>

      <section class="library__sub">

        <div class="row library__sub-1">
          <div class="library__sub-text col-md-6">
            Libraries play an important role in advancing educational equity in their communities. Many young learners do not have access or exposure to computer science, and libraries can provide important resources to these underserved groups. That is why we are partnering with libraries across the country to provide access to our game-based learning tools and educational resources.
          </div>
          <div class="library__sub-image col-md-6">
            <img src="/images/pages/library/library-students.png" alt="Students in library" class="library__sub-image-img img-responsive">
          </div>
        </div>

        <div class="row library__sub-2">
          <div class="library__sub-image col-md-6">
            <img src="/images/pages/library/teach-real-code.png" alt="Teach real code" class="library__sub-image-img img-responsive">
          </div>
          <div class="library__sub-text col-md-6">
            Our games teach real typed Python, JavaScript and C++ coding languages through the power of play. The gameplay is paired with a scaffolded curriculum to allow self-paced learners the ability to master foundational programming concepts before moving on to the more complex. Each level challenges the player to type the code necessary to advance their hero and achieve the level goal.
          </div>
        </div>

      </section>

      <section class="library__needs">
        <div class="library__needs__heading pixel-text">
          Our platform is built to address the specific needs of libraries and their patrons:
        </div>
        <div class="row library__needs__info">
          <div class="col-md-6 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Accessible
            </div>
            <div class="library__needs__info__text-sub">
              A basic computer with internet access is all you need to sign-in and start playing. The content is intended for beginners with no prior coding experience.
            </div>
          </div>
          <div class="col-md-6 library__needs__info-img">
            <img src="/images/pages/library/kids-in-library.jpeg" alt="Students with computer" class="img-responsive">
          </div>
        </div>

        <div class="row library__needs__info">
          <div class="col-md-6 library__needs__info-img">
            <img src="/images/pages/library/self-paced-intuitive.png" alt="Self paced and intuitive" class="img-responsive">
          </div>
          <div class="col-md-6 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Self-Paced and Intuitive
            </div>
            <div class="library__needs__info__text-sub">
              Teachers are not required as players can dictate the pace at which they move through the curriculum. Our custom code engine and interpreter is designed for beginners, it understands the mistakes kids make and speaks to them using human, beginner-friendly terms.
            </div>
          </div>
        </div>
        <div class="row library__needs__info">
          <div class="col-md-6 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Engaging Content
            </div>
            <div class="library__needs__info__text-sub">
              Game-based learning drives engagement from the start but perhaps even more importantly keeps students engaged when the concepts get more challenging. In a game environment failure and success are expected and embraced as part of the play experience.
            </div>
          </div>
          <div class="col-md-6 library__needs__info-img">
            <img src="/images/pages/parents/power_of_play_capstone.gif" alt="Engaging" class="img-responsive">
          </div>
        </div>
        <div class="row library__needs__info">
          <div class="col-md-6 library__needs__info-img">
            <img src="/images/pages/library/calgary-home.png" alt="Calgary library page" class="img-responsive">
          </div>
          <div class="col-md-6 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              API integration
            </div>
            <div class="library__needs__info__text-sub">
              Our games can be easily incorporated into your digital library interface through EZProxy or other popular systems. This structure provides instant access with the members’ existing log in and no staff is needed to manage any logistics of licensing or access.
            </div>
          </div>
        </div>
        <div class="row library__needs__info library__needs-only-text">
          <div class="col-md-11 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Privacy
            </div>
            <div class="library__needs__info__text-sub">
              We take user safety, cybersecurity, and data privacy seriously, following many stringent privacy regulations, like COPPA, FERPA, SOPIPA, California AB 1584, CalOPPA, Fair Information Practices, CAN-SPAM, and GDPR. These policies and protective measures have let us securely serve over twenty million users around the world. See <a href="/privacy" target="_blank">our full privacy policy.</a>
            </div>
          </div>
        </div>
        <div class="row library__needs__info library__needs-only-text">
          <div class="col-md-11 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Communication Limits
            </div>
            <div class="library__needs__info__text-sub">
              To ensure the security of your members, we do not offer in-game chat or other communication features between players, however we do allow members to safely share their coding projects with friends, family and the CodeCombat community. We restrict any upsell or marketing messaging to provide an uninterrupted experience for your patrons.
            </div>
          </div>
        </div>
        <div class="row library__needs__info library__needs-only-text">
          <div class="col-md-11 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Usage Stats
            </div>
            <div class="library__needs__info__text-sub">
              Gain insight to your members’ usage with our snapshot reporting tool. It provides access to usage stats at any time, including monthly active users, licensed days used and more valuable data points.
            </div>
          </div>
        </div>
        <div class="row library__needs__info library__needs-only-text">
          <div class="col-md-11 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Academic Esports
            </div>
            <div class="library__needs__info__text-sub">
              Our esports program offers an opportunity to further engage your members through a fun and exciting competition. The AI League allows members to showcase their understanding of coding concepts in a new environment and practice problem solving strategies as they go head to head in battle against the global community.
            </div>
          </div>
        </div>
        <div class="library__continue">
          <img class="img-responsive" src="/images/pages/parents/graphic_07.svg" style="margin: 0 auto; transform: translate(-47%, 0);" loading="lazy"/>
        </div>
        <section class="library__footer">
          <div class="library__footer-content row">
            <div class="col-md-offset-2 col-md-8">
              <h2 class="library__footer-text pixel-text">
                Work with us to unlock the next generation of engineers, programmers and CS professionals in your community.
              </h2>
              <div class="library__footer-cta">
                <button class="btn library__footer-cta-btn btn-moon" @click="toggleLicenseModal">
                  Schedule a Demo
                </button>
              </div>
            </div>
          </div>
        </section>
      </section>
    </div>
    </div>
    <modal-get-licenses
      v-if="showLicenseModal"
      subtitle="Please complete this short form and one of our library specialists will reach out to provide a demo and custom pricing options!"
      email-message="Hi CodeCombat team! I’m interested in learning more about CodeCombat and how it can be used for my library or library network membership.

        Name of Library or Library Network:
        State or Region Served:
        My Role:
        My Phone Number:
      "
      :ask-school-info="askSchoolInfo"
      licenses-needed-text="Members Needing Access"
      licenses-needed-placeholder="Approximately how many members do you plan to provide access?"
      modal-title="Contact Our Team"
      @close="toggleLicenseModal"
      />
  </div>
</template>

<script>
import ModalGetLicenses from '../../components/common/ModalGetLicenses'
export default {
  name: 'LibraryMainView',
  components: {
    ModalGetLicenses
  },
  data () {
    return {
      showLicenseModal: false,
      askSchoolInfo: false
    }
  },
  methods: {
    toggleLicenseModal () {
      this.showLicenseModal = !this.showLicenseModal
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/common/button";
@import "app/styles/style-flat-variables";
@import "app/styles/bootstrap/variables";

.library {
  font-size: 62.5%;
  font-family: "Work Sans", "Open Sans", sans-serif;

  padding-top: 3rem;
  background: linear-gradient(262.39deg, #D7EFF2 -1.56%, #FDFFFF 95.05%);
  &__heading {
    text-align: center;
    margin-bottom: 5rem;

    background-image: url(/images/pages/parents/image_cloud_3.svg);
    background-repeat: no-repeat;

    &-text {
      font-weight: 700;
      font-size: 4.5rem;
      line-height: 6rem;

      margin-bottom: 2rem;
    }
  }

  &__sub {
    background-image: url(/images/pages/parents/image_cloud_4.svg);
    background-repeat: no-repeat;
    background-position: center top;

    margin-bottom: 5rem;
    &-text {
      font-size: 2.4rem;
      line-height: 3rem;
      letter-spacing: 0.44px;
    }

    &-image {
      padding-top: 1rem;
    }

    &-1 {
      margin-bottom: 5rem;
    }
  }

  &__needs {
    background-image: url(/images/pages/parents/image_cloud_1.svg);
    background-repeat: no-repeat;
    background-position: right top;

    &-only-text:nth-child(even) {
      background-image: url(/images/pages/parents/image_cloud_4.svg);
      background-repeat: no-repeat;
      background-position: right top;
    }

    @media (min-width: $screen-md) {
      &-only-text {
        width: 80%;
      }
    }

    &__heading {
      font-weight: 700;
      font-size: 4rem;
      line-height: 5rem;

      background: url(/images/ozaria/home/heading_corner.svg) no-repeat left 0 top 0;
      padding: 12px 0 12px 20px;

      margin-bottom: 3rem;
    }

    &__info {
      margin-bottom: 6rem;

      &__text {
        &-heading {
          font-weight: 700;
          font-size: 2.5rem;
          line-height: 3.8rem;
          letter-spacing: .56px;

          margin-bottom: 1rem;
        }

        &-sub {
          font-size: 2.4rem;
          line-height: 3rem;
          letter-spacing: .444px;
        }
      }

      &-img {
        padding-top: 1rem;
      }

      @media (max-width: $screen-md) {
        &-img {
          display: none;
        }
      }
    }
  }

  &__footer {
    border-radius: 38px;
    border: 4px solid #6AE8E3;
    padding: 3rem;

    text-align: center;

    &-text {
      font-size: 2.6rem;
      line-height: 4rem;
      letter-spacing: 0.444px;
      font-weight: 400;
      margin-bottom: 2rem;
    }
  }
}

.pixel-text {
  font-family: $pixel-headline-font;
  color: $navy;
}
</style>
