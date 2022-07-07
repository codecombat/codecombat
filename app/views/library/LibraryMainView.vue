<template>
  <div>
    <div class="library container">
      <section class="row library__heading">
        <h2 class="library__heading-text">
          We support equity in computer science by partnering with libraries
        </h2>
        <button class="btn library__heading-btn btn-moon" @click="toggleLicenseModal">
          Talk with our Team
        </button>
      </section>

      <section class="library__sub">

        <div class="row library__sub-1">
          <div class="library__sub-text col-md-5">
            Libraries play an important role in advancing educational equity in their communities. Many young learners do not have access or exposure to computer science, and libraries can provide important resources to these underserved groups. That is why we are partnering with libraries across the country to provide access to our game-based learning tools and educational resources.
          </div>
          <div class="library__sub-image col-md-offset-1 col-md-6">
            <img src="/images/pages/library/library-students.png" alt="Students in library" class="library__sub-image-img img-responsive">
          </div>
        </div>

        <div class="row library__sub-2">
          <div class="library__sub-image col-md-6">
            <img src="/images/pages/library/teach-real-code.png" alt="Teach real code" class="library__sub-image-img img-responsive">
          </div>
          <div class="library__sub-text col-md-offset-1 col-md-5">
            Our games teach real typed Python, JavaScript and C++ coding languages through the power of play. The gameplay is paired with a scaffolded curriculum to allow self-paced learners the ability to master foundational programming concepts before moving on to the more complex. Each level challenges the player to type the code necessary to advance their hero and achieve the level goal.
          </div>
        </div>

      </section>

      <section class="library__needs">
        <div class="library__needs__heading">
          Our platform is built to address the specific needs of libraries and their patrons:
        </div>
        <div class="row library__needs__info">
          <div class="col-md-5 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Accessible
            </div>
            <div class="library__needs__info__text-sub">
              A basic computer with internet access is all you need to sign-in and start playing. The content is intended for beginners with no prior coding experience.
            </div>
          </div>
          <div class="col-md-offset-1 col-md-6 library__needs__info-img">
            <img src="/images/pages/home-v2/pd-image.png" alt="Students with computer" class="img-responsive">
          </div>
        </div>

        <div class="row library__needs__info">
          <div class="col-md-6 library__needs__info-img">
            <img src="/images/pages/library/self-paced-intuitive.png" alt="Self paced and intuitive" class="img-responsive">
          </div>
          <div class="col-md-offset-1 col-md-5 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Self-Paced and Intuitive
            </div>
            <div class="library__needs__info__text-sub">
              Teachers are not required as players can dictate the pace at which they move through the curriculum. Our custom code engine and interpreter is designed for beginners, it understands the mistakes kids make and speaks to them using human, beginner-friendly terms.
            </div>
          </div>
        </div>
        <div class="row library__needs__info">
          <div class="col-md-5 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Engaging Content
            </div>
            <div class="library__needs__info__text-sub">
              Game-based learning drives engagement from the start but perhaps even more importantly keeps students engaged when the concepts get more challenging. In a game environment failure and success are expected and embraced as part of the play experience.
            </div>
          </div>
          <div class="col-md-offset-1 col-md-6 library__needs__info-img">
            <img src="/images/pages/parents/power_of_play_capstone.gif" alt="Engaging" class="img-responsive">
          </div>
        </div>
        <div class="row library__needs__info">
          <div class="col-md-6 library__needs__info-img">
            <img src="/images/pages/library/calgary-home.png" alt="Calgary library page" class="img-responsive">
          </div>
          <div class="col-md-offset-1 col-md-5 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              API integration
            </div>
            <div class="library__needs__info__text-sub">
              Our games can be easily incorporated into your digital library interface through EZProxy or other popular systems. This structure provides instant access with the members’ existing log in and no staff is needed to manage any logistics of licensing or access.
            </div>
          </div>
        </div>
        <div class="row library__needs__info">
          <div class="col-md-5 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Academic Esports
            </div>
            <div class="library__needs__info__text-sub">
              Our esports program offers an opportunity to further engage your members through a fun and exciting competition. The AI League allows members to showcase their understanding of coding concepts in a new environment and practice problem solving strategies as they go head to head in battle against the global community.
            </div>
          </div>
          <div class="col-md-offset-1 col-md-6 library__needs__info-img">
            <img src="/images/pages/home-v2/league-image.png" alt="AI League" class="img-responsive">
          </div>
        </div>
        <div class="row library__needs__info">
          <div class="col-md-11 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Privacy
            </div>
            <div class="library__needs__info__text-sub">
              We take user safety, cybersecurity, and data privacy seriously, follow many stringent privacy regulations, like COPPA, FERPA, SOPIPA, California AB 1584, CalOPPA, Fair Information Practices, CAN-SPAM, as well as GDPR, and these policies and protective measures have let us serve 20M+ users around the world without incident.
            </div>
          </div>
        </div>
        <div class="row library__needs__info">
          <div class="col-md-11 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Communication Limits
            </div>
            <div class="library__needs__info__text-sub">
              While members do have the ability to share their coding projects with friends, family and the CodeCombat community, there are no in-game chat or other communication features. Marketing and any upsell messaging is disabled for this execution.
            </div>
          </div>
        </div>
        <div class="row library__needs__info">
          <div class="col-md-11 library__needs__info__text">
            <div class="library__needs__info__text-heading">
              Usage Stats
            </div>
            <div class="library__needs__info__text-sub">
              Snapshot reporting tool where you can see usage stats at any time, including stats like monthly active users.
            </div>
          </div>
        </div>
      </section>
    </div>
    <section class="library__footer container-fluid">
      <div class="library__footer-content row">
        <div class="col-md-offset-2 col-md-8">
          <h2 class="library__footer-text">
            Work with us to unlock the next generation of engineers, programmers and CS professionals in your community.
          </h2>
          <div class="library__footer-cta">
            <button class="btn library__footer-cta-btn btn-moon" @click="toggleLicenseModal">
              Contact Us
            </button>
          </div>
        </div>
      </div>
    </section>
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

.library {
  font-size: 62.5%;
  font-family: "Work Sans", "Open Sans", sans-serif;

  padding-top: 3rem;
  &__heading {
    text-align: center;
    margin-bottom: 5rem;

    &-text {
      font-weight: 700;
      font-size: 4.5rem;
      line-height: 6rem;

      margin-bottom: 2rem;
    }
  }

  &__sub {
    margin-bottom: 5rem;
    &-text {
      font-size: 2.4rem;
      line-height: 3.4rem;
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
    }
  }

  &__footer {
    height: 56.4vw;
    display: flex;
    justify-content: center;
    align-items: center;
    position: relative;

    color: white;

    &::before {
      content: "";
      background: url(/images/ozaria/home/background_cta_1.png) no-repeat center;
      background-size: cover;
      position: absolute;
      top: 0;
      right: 0;
      bottom: 0;
      left: 0;
      filter: brightness(0.6);
    }

    &-content {
      z-index: 1;
      text-align: center;
    }

    &-text {
      font-size: 2.6rem;
      line-height: 4rem;
      letter-spacing: 0.444px;
      color: #fff;
      font-weight: 400;
      margin-bottom: 2rem;
    }
  }
}
</style>
