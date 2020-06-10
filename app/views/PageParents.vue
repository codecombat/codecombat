<template>
    <div>
        <div class="jumbotron">
            <div class="row">
                <div class="col-lg-4 col-md-6">
                    <h1>Discover the magic of coding at home.</h1>
                </div>
            </div>
            <div class="row">
                <div class="col-lg-3 col-md-4">
                    <button class="full-width" @click="openDriftWelcomeCallPlaybook">Learn with an instructor</button>
                </div>
            </div>
            <div class="row">
                <div class="col-lg-3 col-md-4">
                    <button class="full-width" @click="openDriftWelcomeCallPlaybook">Learn at your own pace</button>
                </div>
            </div>
        </div>

        <div class="container-fluid gray-1-background">
            <div class="container">
                <div class="row title-row">
                    <div class="row">
                        <div class="col-lg-12">
                            <h1>Live Online Classes</h1>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <hr />
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <h3>Learn with an instructor</h3>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <h4>CodeCombat now offers live online computer science classes for students learning at home. Great for students who work best in 1:1 or small-group settings where learning outcomes are tailored to their needs.</h4>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-lg-6 device-image">
                        <img src="/images/pages/parents/device.svg" />
                    </div>
                    <div class="col-lg-6">
                        <ul>
                            <li>Small group or private lessons</li>
                            <li>JavaScript and Python coding, plus core Computer Science concepts</li>
                            <li>Taught by expert coding instructors</li>
                            <li>Individualized and instant feedback</li>
                            <li>Curriculum trusted by 80,000+ educators</li>
                        </ul>

                        <button class="default-top-spacing" @click="openDriftWelcomeCallPlaybook">Try a free 60 minute class</button>
                    </div>
                </div>

                <div class="row title-row add-spacing">
                    <div class="col-lg-12">
                        <h2>Pricing Plans</h2>
                    </div>
                </div>

                <div class="row equal-height">
                    <div class="col-lg-6">
                        <div class="pricing-pane">
                            <div class="pricing-pane-content">
                                <h3>Small group Coding Classes</h3>
                                <h4>4 Group Sessions / Mo.</h4>

                                <div>
                                    <div class="price">
                                        $159/mo
                                    </div>
                                    <div class="per-student-label">per student</div>
                                </div>

                                <button @click="openDriftWelcomeCallPlaybook">Choose Plan</button>

                                <ul>
                                    <li>4:1 student to instructor ratio</li>
                                    <li>60 minute classes</li>
                                    <li>Build projects and give feedback to other students</li>
                                    <li>Screen sharing to get live feedback on coding and debugging</li>
                                </ul>
                            </div>
                            <div class="discount">
                                15% Sibling Discount!
                            </div>
                        </div>
                    </div>

                    <div class="col-lg-6">
                        <div class="pricing-pane">
                            <div class="pricing-pane-content">
                                <h3>Private Coding Classes</h3>
                                <h4>4 or 8 Private Sessions / Mo.</h4>

                                <div>
                                    <div class="price">
                                        $219/mo or $399/mo
                                    </div>
                                    <div class="per-student-label">per student</div>
                                </div>

                                <button @click="openDriftWelcomeCallPlaybook">Choose Plan</button>

                                <ul>
                                    <li>1:1 student to instructor ratio</li>
                                    <li>60 minute classes</li>
                                    <li>Flexible schedule tailored to your needs</li>
                                    <li>Lesson plans and live feedback tailored to students' learning style, pace, and ability level</li>
                                </ul>
                            </div>
                            <div class="discount">
                                15% Sibling Discount!
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="container-fluid coco-premium">
            <div class="container">
                <div class="row title-row">
                    <div class="row">
                        <div class="col-lg-12">
                            <h1>CodeCombat Premium</h1>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <hr />
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <h3>Learn at Your Own Pace</h3>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-lg-12 character-images">
                        <img src="/images/pages/parents/characters.svg" />
                    </div>
                </div>

                <div class="row premium-pricing">
                    <div class="col-lg-3 col-lg-offset-3" :style="{ visibility: (productsLoading) ? 'hidden': 'visible' }">
                        <h5>${{ basicSubAmount }}/mo</h5>
                        <h6>Monthly Subscription</h6>

                        <button @click="openPremiumSubscribeModal">Buy now</button>
                    </div>
                    <div class="col-lg-3" :style="{ visibility: (productsLoading) ? 'hidden': 'visible' }">
                        <h5>${{ lifetimeSubAmount }}/mo</h5>
                        <h6>Lifetime Access</h6>

                        <button @click="openPremiumSubscribeModal">Buy now</button>
                    </div>
                </div>

                <div class="row premium-details">
                    <div class="col-lg-8 col-lg-offset-2">
                        <h5>Great for self-driven learners who thrive with complete autonomy.</h5>
                        <ul>
                            <li>Access to subscriber-only heroes, pets and skills</li>
                            <li>Receive bonus gems to buy gear, pets and more heroes</li>
                            <li>Unlock a deeper understanding of core concepts and skills like web and game development</li>
                            <li>Premium support for subscribers</li>
                            <li>Create private clans to invite friends and compete on a group leaderboard</li>
                        </ul>

                        <div class="buy-now-note">Need help or prefer Paypal? Email support@codecombat.com</div>
                    </div>
                </div>
            </div>
        </div>

        <div class="container trailer">
            <div class="row title-row">
                <div class="row">
                    <div class="col-lg-12">
                        <h2>Not sure if CodeCombat is right for your kid?  Ask them!</h2>
                    </div>
                </div>
                <div class="row">
                    <div class="col-lg-12">
                        <hr />
                    </div>
                </div>
                <div class="row">
                    <div class="col-lg-12">
                        <h3>Share our game trailer with your kid and have them create an account to get started.</h3>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-lg-7 video-col">
                    <div class="video-container">
                        <iframe
                                class="video"
                                src="https://www.youtube.com/embed/rOXRBQIXvlI?modestBranding=1&rel=0"
                                frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
                                allowfullscreen
                        ></iframe>
                    </div>
                </div>
            </div>
        </div>

        <div class="container-fluid gray-2-background">
            <div class="container">
                <div class="row title-row">
                    <div class="col-lg-12">
                        <h1>Why Kids Love CodeCombat</h1>
                    </div>
                </div>

                <div class="row equal-height">
                    <div class="col-lg-4">
                        <div class="kid-reason-why">
                            <img src="/images/pages/parents/learning_through_play.svg" />
                            <h3>Learning Through Play</h3>
                            <div class="description">Students grow their coding skills, and also use problem-solving skills to progress through levels and power up their heroes.</div>
                        </div>
                    </div>
                    <div class="col-lg-4">
                        <div class="kid-reason-why">
                            <img src="/images/pages/parents/skills_they_can_share.svg" />
                            <h3>Skills They Can Share</h3>
                            <div class="description">Students build real-world skills and create projects they can share with friends and family</div>
                        </div>
                    </div>
                    <div class="col-lg-4">
                        <div class="kid-reason-why">
                            <img src="/images/pages/parents/help_when_needed.svg" />
                            <h3>Help When They Need It</h3>
                            <div class="description">Using data, entry level has been built to be challenging, but never discouraging.  Students are supported with hints when they get stuck.</div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-lg-12 buy-now-row">
                        <button @click="openDriftWelcomeCallPlaybook">Book your first class</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="container-fluid gray-1-background">
            <div class="container">
                <div class="title-row">
                    <div class="col-lg-12">
                        <h1>Why Parents Love CodeCombat</h1>
                    </div>
                </div>

                <div class="row equal-height">
                    <div class="col-lg-4">
                        <div class="parent-reason-why">
                            <img srcset="/images/pages/parents/parent_3@1x.png 1x, /images/pages/parents/parent_3@2x.png 2x, /images/pages/parents/parent_3@3x.png 3x" src="/images/pages/parents/parent_3@1x.png" />
                            <div class="description">
                                <h3>The most engaging way to learn typed code</h3>
                                Your child will have everything they need at the tip of their fingers to program algorithms in Python or JavaScript, build websites and even design their own games, while learning material aligned with national curriculum standards.
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4">
                        <div class="parent-reason-why">
                            <img srcset="/images/pages/parents/parent_3@1x.png 1x, /images/pages/parents/parent_3@2x.png 2x, /images/pages/parents/parent_3@3x.png 3x" src="/images/pages/parents/parent_3@1x.png" />
                            <div class="description">
                                <h3>Building critical skills for the 21st centry</h3>
                                Your child will learn how to navigate and become citizens in the digital world. CodeCombat is a solution that enhances your child’s critical thinking, creativity, and resilience, empowering them with the skills they need for any industry.
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4">
                        <div class="parent-reason-why">
                            <img srcset="/images/pages/parents/parent_3@1x.png 1x, /images/pages/parents/parent_3@2x.png 2x, /images/pages/parents/parent_3@3x.png 3x" />
                            <div class="description">
                                <h3>Supported by parents like you</h3>
                                At CodeCombat, we’re parents. We’re coders. We’re educators. But most of all, we’re people who believe in giving our kids the best opportunity for success in whatever it is they decide to do.
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-lg-12 buy-now-row">
                        <button @click="openDriftWelcomeCallPlaybook">Book your first class</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="container concepts">
            <div class="row title-row">
                <div class="col-lg-12">
                    <h2>Everything they need to just start typing code on their own</h2>
                </div>
            </div>

            <div class="row equal-height">
                <div class="col-lg-4">
                    <div class="concept-overview">
                        <div class="image-container">
                            <img src="/images/pages/parents/beginner_concepts.svg" />
                        </div>
                        <h3>Beginner Concepts</h3>
                        <ul>
                            <li>Basic syntax</li>
                            <li>While loops</li>
                            <li>Arguments</li>
                            <li>Strings</li>
                            <li>Variables</li>
                            <li>Algorithms</li>
                        </ul>
                    </div>
                </div>
                <div class="col-lg-4">
                    <div class="concept-overview">
                        <div class="image-container">
                            <img src="/images/pages/parents/intermediate_concepts.svg" />
                        </div>
                        <h3>Intermediate Concepts</h3>
                        <ul>
                            <li>If statements</li>
                            <li>Boolean comparisons</li>
                            <li>Nested conditionals</li>
                            <li>Functions</li>
                            <li>Basic input handling</li>
                            <li>Basic game artificial intelligence</li>
                        </ul>
                    </div>
                </div>
                <div class="col-lg-4">
                    <div class="concept-overview">
                        <div class="image-container">
                            <img src="/images/pages/parents/advanced_concepts.svg" />
                        </div>
                        <h3>Advanced Concepts</h3>
                        <ul>
                            <li>Event handling</li>
                            <li>Conditional while loops</li>
                            <li>Object Literals</li>
                            <li>Parameters</li>
                            <li>Vectors</li>
                            <li>Math Library jOperations</li>
                            <li>Recursion</li>
                        </ul>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-lg-12 buy-now-row">
                    <button @click="openPremiumSubscribeModal">Get Started</button>
                </div>
            </div>
        </div>

        <div class="container-fluid gray-2-background testimonials">
            <div class="container">
                <div class="row title-row">
                    <div class="row">
                        <div class="col-lg-12">
                            <h2>What parents and kids are saying about CodeCombat</h2>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <hr />
                        </div>
                    </div>
                </div>

                <div class="row equal-height">
                    <div class="col-lg-6">
                        <div class="quote">"This is next level coding for kids and it’s pretty fun. I am going to learn a thing or two from this too."</div>
                        <div class="name">Francisco Navarro</div>
                        <div class="details">Parent, Chicago, IL</div>
                    </div>
                    <div class="col-lg-6">
                        <div class="quote">"I liked learning a new skill that I haven’t done before. I liked that when I was struggling, I could find the goals. I also liked that you could see the code work correctly."</div>
                        <div class="name">Avery</div>
                        <div class="details">Student, Grade 8</div>
                    </div>
                </div>

                <div class="row equal-height">
                    <div class="col-lg-6">
                        <div class="quote">“Oliver’s Python is coming along. He’s using CodeCombat to make his own video games. He challenges me to play his games, then laughs when I lose.” </div>
                        <div class="name">Alex Bain</div>
                        <div class="details">Parent, Chicago, IL</div>
                    </div>
                    <div class="col-lg-6">
                        <div class="quote">“This is one of my favorite things to do. Every morning I wake up and play CodeCombat. If I had to give CodeCombat a rating from 1 to 10, I would give it a 10!”</div>
                        <div class="name">Caleb S.</div>
                        <div class="details">Student, Grade 7</div>
                    </div>
                </div>
            </div>
        </div>

        <backbone-modal-harness :modal-view="SubscribeModal" :open="subscribeModalOpen" @close="subscribeModalClosed" />
    </div>
</template>

<script>
  import { mapActions, mapState, mapGetters } from 'vuex'

  import SubscribeModal from 'views/core/SubscribeModal'
  import BackboneModalHarness from './common/BackboneModalHarness'

  export default {
    inject: ['openLegacyModal'],

    components: {
      BackboneModalHarness,
    },

    data: () => ({
      SubscribeModal,
      subscribeModalOpen: false
    }),

    computed: {
      ...mapState('products', {
        productsLoading: (s) => s.loading.products,
      }),

      ...mapGetters('products', [
        'basicSubscriptionForCurrentUser',
        'lifetimeSubscriptionForCurrentUser'
      ]),

      basicSubAmount () {
        const sub = this.basicSubscriptionForCurrentUser
        console.log(sub)
        return (sub) ? sub.amount / 100 : 0
      },

      lifetimeSubAmount() {
        const sub = this.lifetimeSubscriptionForCurrentUser
        return (sub) ? sub.amount / 100: 0
      }
    },

    methods: {
      openDriftWelcomeCallPlaybook () {
        window.drift.api.startInteraction({ interactionId: 161673 });
      },

      subscribeModalClosed() {
        this.subscribeModalOpen = false
      },

      ...mapActions({
        loadProducts: 'products/loadProducts'
      }),

      openPremiumSubscribeModal () {
        this.subscribeModalOpen = true
      }
    },

    mounted () {
      this.loadProducts()
    }
  }
</script>

<style scoped>
    h1 {
        font-size: 46px;
        font-style: normal;
        font-weight: bold;
        line-height: 57px;

        color: #0E4C60;
    }

    button {
        padding: 13px;

        text-transform: uppercase;
        border-radius: 4px;
        background-color: #1FBAB4;
        color: #000;
        line-height: 25px;
        font-size: 18px;
        font-style: normal;
        font-weight: bold;

        border: 2px solid #1FBAB4;
    }

    button.full-width {
        width: 100%;
    }

    button.default-top-spacing {
        margin-top: 30px;
    }

    ul {
        margin: 0;
        padding: 0;

        font-style: normal;
        font-weight: 300;
        font-size: 18px;
        line-height: 25px;
        color: #0E4C60;

        list-style: none;
    }

    ul li::before {
        content: "\2022";
        color: #1FBAB4;
        font-weight: bold;
        display: inline-block;
        margin-left: -20px;
        margin-right: 10px
    }

    .jumbotron, .container-fluid {
        padding: 0 70px;
        margin-bottom: 0;
    }

    .container-fluid {
        padding-top: 60px;
    }

    .jumbotron {
        padding: 110px;
        min-height: 580px;

        background-image: url("/images/pages/parents/jumbotron@1x.png");
        background-size: cover;
        background-repeat: no-repeat;
        background-position: center;

    }

    .jumbotron h1 {
        margin-bottom: 40px;
    }

    .jumbotron button {
        margin-bottom: 30px;
    }

    @media (-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi) {
        .jumbotron {
            background-image: url("/images/pages/parents/jumbotron@2x.png");
        }
    }

    .row.equal-height {
        display: flex;
        flex-wrap: wrap;
    }

    .row.equal-height > [class*='col-'] {
        display: flex;
        flex-direction: column;
    }

    .gray-1-background {
        background-color: #F7F9F9;
    }

    .gray-1-background h3 {
        color: #1FBAB4;
    }

    .gray-2-background {
        background-color: #EAEEEE;
    }

    .gray-2-background .title-row h1, .gray-2-background .title-row h2 {
        color: #1FBAB4;
    }

    .title-row {
        text-align: center;
    }

    .title-row.add-spacing {
        margin-top: 60px;
        margin-bottom: 40px;
    }

    .title-row hr {
        height: 5px;
        width: 150px;
        background-color: #FF6978;
        margin: 15px auto;
        border: 0 none;
    }

    .title-row h2 {
        font-family: Arvo, serif;
        font-style: normal;
        font-weight: bold;
        font-size: 33px;
        line-height: 41px;
        color: #0E4C60;
    }

    .title-row h3 {
        font-family: "Open Sans", sans-serif;
        font-style: normal;
        font-weight: normal;
        font-size: 24px;
        line-height: 33px;

        color: #000;
    }

    .title-row h4 {
        font-weight: bold;
        font-size: 24px;
        line-height: 33px;
        margin: 30px 0;
        color: #1FBAB4;
    }

    .device-image {
        text-align: center;
    }

    .device-image img {
        width: 100%;
        max-width: 655px
    }

    .pricing-pane {
        display: flex;
        flex-direction: column;
        align-items: center;

        height: 100%;

        background: linear-gradient(180deg, #1FBAB4 0%, #F2BE19 100%);

        padding: 7px;
        margin-bottom: 60px;
    }

    .pricing-pane h3, .pricing-pane h4 {
        font-family: Arvo, serif;
        font-style: normal;
        font-weight: bold;
        font-size: 33px;
        line-height: 41px;
        color: #0E4C60;
        text-align: center;
    }

    .pricing-pane h3 {
        font-size: 30px;
        line-height: 37px;
    }

    .pricing-pane h4 {
        font-size: 24px;
        line-height: 30px;
    }

    .pricing-pane .pricing-pane-content {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: space-around;

        flex-grow: 1;

        padding: 31px 43px;

        width: 100%;
        height: 100%;
        background-color: #FFFAFA;
    }

    .pricing-pane-content .price {
        margin-top: 30px;

        font-style: normal;
        font-weight: bold;
        font-size: 36px;
        line-height: 49px;

        text-align: center;

        color: #1FBAB4;
    }

    .pricing-pane-content .per-student-label {
        margin-bottom: 30px;

        font-style: normal;
        font-weight: bold;
        font-size: 24px;
        line-height: 33px;

        text-align: center;

        color: #1FBAB4;
    }

    .pricing-pane .discount {
        flex-grow: 0;

        font-style: normal;
        font-weight: bold;
        font-size: 18px;
        line-height: 25px;
        /* identical to box height */

        text-align: center;

        color: #232323;
        margin: 21px;
    }

    .pricing-pane button {
        margin-bottom: 30px;
        width: 50%;
        max-width: 250px;
    }

    .pricing-pane-content ul {
        align-self: flex-end;
    }

    .coco-premium {
        background-color: #0E4C60;
        color: #FFF;
    }

    .coco-premium .title-row h1 {
        color: #1FBAB4;
    }

    .coco-premium .title-row h3 {
        color: #FFF;
    }

    .coco-premium .character-images img {
        margin: 40px auto 20px;

        width: 100%;
        max-width: 676px;
        display: block;
    }

    .coco-premium h5 {
        font-family: Open Sans, sans-serif;
        font-style: normal;
        font-weight: bold;
        font-size: 24px;
        line-height: 33px;

        text-align: center;

        color: #FFFFFF;
    }

    .coco-premium ul li {
        font-style: normal;
        font-weight: 300;
        font-size: 18px;
        line-height: 25px;
        color: #FFF;
    }

    .coco-premium .premium-pricing {
        color: #1FBAB4;
        text-align: center;
    }

    .coco-premium .premium-pricing h5, .coco-premium .premium-pricing h6 {
        font-family: Open Sans, sans-serif;
        font-style: normal;
        font-weight: bold;
        text-align: center;

        color: #1FBAB4;
    }

    .coco-premium .premium-pricing h5 {
        font-size: 36px;
        line-height: 49px;
    }

    .coco-premium .premium-pricing h6 {
        font-size: 24px;
        line-height: 33px;
    }

    .coco-premium .premium-pricing button {
        margin-top: 15px;
        width: 100%;
        margin-bottom: 52px;
    }

    .coco-premium .buy-now-note {
        margin-top: 35px;
        margin-bottom: 60px;

        font-style: normal;
        font-weight: normal;
        font-size: 14px;
        line-height: 19px;

        text-align: center;

        color: #FFFFFF;
    }

    .trailer {
        padding-top: 60px;
    }

    .video-col {
        margin: 0 auto;
        float: unset;
    }

    .video-col .video-container {
        margin-top: 40px;
        margin-bottom: 60px;

        position: relative;
        height: 0;
        padding-bottom: 56.25%;
    }

    .video-col .video-container .video {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
    }

    .kid-reason-why {
        margin-top: 40px;

        height: 100%;
        display: flex;
        flex-direction: column;

        align-items: center;
    }

    .kid-reason-why h3 {
        font-style: normal;
        font-weight: bold;
        font-size: 24px;
        line-height: 30px;

        color: #1FBAB4;
    }

    .kid-reason-why img {
        width: 100%;
        max-width: 255px;

        margin-bottom: 20px;
    }

    .kid-reason-why .description {
        margin-top: 10px;

        font-style: normal;
        font-weight: 300;
        font-size: 18px;
        line-height: 25px;

        color: #0E4C60;
    }

    .buy-now-row {
        margin-top: 40px;
        margin-bottom: 60px;
        text-align: center;
    }

    .parent-reason-why {
        margin: 40px auto 0;

        width: 100%;
        height: 100%;

        max-width: 362px;
        box-shadow: 2px 2px 6px rgba(155, 155, 155, 0.510671);

    }

    .parent-reason-why img {
        width: 100%;
    }

    .parent-reason-why .description {
        padding: 20px;

        font-style: normal;
        font-weight: 300;
        font-size: 18px;
        line-height: 25px;

        color: #0E4C60;
    }

    .parent-reason-why h3 {
        font-style: normal;
        font-weight: bold;
        font-size: 24px;
        line-height: 30px;

        color: #1FBAB4;
    }

    .concepts {
        padding-top: 60px;
    }

    .concept-overview {
        margin: 40px auto 0;

        width: 100%;
        max-width: 310px;
    }

    .concept-overview .image-container {
        position: relative;

        display: flex;
        align-items: center;
        justify-content: center;

        width: 100%;
        height: 190px;
    }

    .concept-overview h3 {
        font-style: normal;
        font-weight: bold;
        font-size: 24px;
        line-height: 30px;

        color: #1FBAB4;

        margin-top: 30px;
        margin-bottom: 18px;
    }

    .testimonials {
        padding-bottom: 70px;

        /* Remove margin added by footer */
        margin-bottom: -50px;
    }

    .testimonials .quote {
        margin-top: 60px;

        font-style: normal;
        font-weight: bold;
        font-size: 18px;
        line-height: 25px;

        color: #0E4C60;
    }

    .testimonials .name {
        margin-top: 10px;

        font-style: normal;
        font-weight: bold;
        font-size: 18px;
        line-height: 25px;

        color: #1FBAB4;
    }

    .testimonials .details {
        font-style: normal;
        font-weight: normal;
        font-size: 14px;
        line-height: 19px;

        color: #1FBAB4;
    }
</style>
