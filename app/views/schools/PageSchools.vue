<template>
  <div id="page-schools">
    <div class="container">
      <header-component class="container__header">
        <template #header-text>
          <h1 class="text-h1">
            <mixed-color-label text="The most effective computer science solution for **schools**" />
          </h1>
          <p class="text-24">
            Our comprehensive implementation empowers teachers, engages students and delivers successful outcomes.
          </p>
          <CTAButton>Get My Solution</CTAButton>
          <p class="text-14">
            <mixed-color-label text="**Let us craft a custom program for you!**" />
          </p>
        </template>
        <template #image>
          <content-box :main-image-bg="true">
            <template #image>
              <div style="position: relative; padding-top: 56.25%;">
                <iframe
                  src="https://customer-burj9xtby325x4f1.cloudflarestream.com/da0d63c489741f4bd20448af1846292a/iframe?preload=true&loop=true&autoplay=true&poster=https%3A%2F%2Fcustomer-burj9xtby325x4f1.cloudflarestream.com%2Fda0d63c489741f4bd20448af1846292a%2Fthumbnails%2Fthumbnail.jpg%3Ftime%3D%26height%3D600&controls=false"
                  style="border: none; position: absolute; top: 0; left: 0; height: 100%; width: 100%;"
                  allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
                  allowfullscreen="true"
                />
              </div>
            </template>
          </content-box>
        </template>
      </header-component>
    </div>

    <background-container
      type="colored"
      class="testimonals"
    >
      <div class="container">
        <carousel-component
          :show-tabs="false"
          :show-dots="true"
          :has-background="false"
        >
          <template
            v-for="(item, index) in testimonals"
            #[`${index}`]
          >
            <carousel-item :key="index">
              <testimonial-component
                class="testimonals__item"
                :quote="item.quote"
                :name="item.name"
                :title="item.title"
                :image="item.image"
                :link="item.link"
              />
            </carousel-item>
          </template>
        </carousel-component>
      </div>
    </background-container>

    <div class="container">
      <turnkey-solutions />
    </div>

    <div class="container">
      <image-and-text
        title="A Flexible Standards Aligned Curriculum"
        text="Our scaffolded approach covers computer science fundamentals up through advanced courses and features **College Board endorsed AP CSP**, web and game development. We build customized pathways to deliver a personalized learning experience that meets CSTA, ISTE and Common Core State Standards. The flexible curriculum offers the ability to teach Python, JavaScript, C++, Luau and more."
        image="/images/pages/schools/boxes/box_1.gif"
      />
      <image-and-text
        title="Comprehensive Tools & Resources"
        text="The teacher resource hub empowers all educators to teach on day one. Easily access lesson plans, student-facing lesson slides, rubrics, extension activities, capstone projects and assessments. Our safe AI integrations accelerate student potential and allow educators to optimize class time. For real-world practice and application, we offer competitive coding esports, Roblox game design and web design options. Additionally, educators can control student pacing with content assignment and locking features."
        image="/images/pages/schools/boxes/box_2.gif"
        :reverse="true"
      />
    </div>

    <BackgroundContainer>
      <stats-component class="container" />
    </BackgroundContainer>

    <div class="container">
      <image-and-text
        title="Accessible Data & Insights"
        text="We provide administrators the insight they need with real-time usage data and progress reports at the class, school, district and state level. Student level progress tracking enables educators to easily identify when intervention is needed and the built in pre and post module assessments measure student comprehension."
        image="/images/pages/schools/boxes/box_3.gif"
      />
      <two-column-block :reverse="true">
        <template #column-one>
          <content-box :main-image-bg="true">
            <template #image>
              <img src="/images/pages/schools/boxes/box_4.gif">
            </template>
          </content-box>
        </template>
        <template #column-two>
          <h3>High Quality Professional Development</h3>
          <p>
            <mixed-color-label
              text="**Endorsed by the Computer Science Teachers Association (CSTA)**, the course provides 44+ hours of self-directed, web-based, and on-demand learning. The program is self-paced and designed to fit any busy schedule. The course prepares anyone with or without teaching experience to successfully implement a CS curriculum."
            />
          </p>
          <p>
            Earn up to 3 graduate credits with this course.
            <img src="/images/pages/home-v3/logo/southern-new-hampshire-university.webp">
          </p>
        </template>
      </two-column-block>
    </div>

    <background-container type="sides">
      <div class="container">
        <div class="row">
          <div class="col-md-12">
            <content-box>
              <template #text>
                <mission-component />
              </template>
            </content-box>
          </div>
        </div>
      </div>
    </background-container>

    <background-container
      type="colored"
      class="maximize"
    >
      <div class="container">
        <h2 class="text-h2">
          All the tools to maximize learning outcomes
        </h2>
        <box-panel
          :title="'Core Curriculum'"
          :items="coreCurriculum"
        />
        <box-panel
          :title="'Practice & Enrichment'"
          :items="practiceEnrichment"
        />
        <box-panel
          :title="'Student Acceleration & AP CSP'"
          :items="studentAcceleration"
        />
        <box-panel
          :title="'Young Learners'"
          :items="youngLearners"
        />
        <box-panel
          :title="'Funding Solutions'"
          :items="fundingSolutions"
          arrangement="horizontal"
        />
        <box-panel
          :title="'Support & Development'"
          :items="supportDevelopment"
        />
      </div>
    </background-container>

    <div class="container">
      <image-and-text
        title="AI Support & Acceleration"
        text="We use AI to make teaching time more effective. CodeCombat now supports an AI hints feature that evaluates code, points out errors, and explains how to fix them. Most importantly, it provides all the context needed to understand the why, without revealing the entire solution. Students will still need to work through each level’s coding challenge but now you don’t need to stop class to address individual needs. **Teachers receive an allocation of 100 AI hints per day** and **each student gets 5 AI hints per day**, to ensure they always have the support they need. "
        image="/images/pages/schools/boxes/aisupport_1.png"
      />
      <image-and-text
        text="For those new to AI, we offer **CodeCombat AI HackStack**. This innovative tool not only teaches students how to use AI but provides secure access to many of the latest LLMs including ChatGPT-4, Claude, Stable Diffusion, DALL-E and others. After just a short time working through the training mode, users unlock the full creative potential of the tool, allowing prompt-to-code-to-published projects in minutes. This AI-powered application enables users to generate games, art, websites, code and more. **Teachers receive an allocation of 100 AI prompts per month** and **each student gets 10 AI prompts per week**, to create multiple AI projects."
        image="/images/pages/schools/boxes/aisupport_2.jpeg"
        :reverse="true"
      />
    </div>

    <background-container
      type="colored"
      class="pathway"
    >
      <div class="container">
        <custom-table
          :header-contents="['Elementary School', 'CodeCombat Jr.', 'AI HacksStack Jr.', 'CodeCombat Worlds']"
          :table-rows="[
            { year: '1', percents: [50, 50, null], contents: ['K', 'Icons & Block-Based', 'Introduction to AI', null] },
            { year: '2', percents: [50, 50, null], contents: ['Grade 1', 'Icons & Block-Based', 'Simple AI Templates', null] },
            { year: '3', percents: [60, 20, 20], contents: ['Grade 2', 'Icons & Block-Based', 'Complex AI Templates', 'Explorations'] },
            { year: '4', percents: [70, 10, 20], contents: ['Grade 3', 'Block-Based', 'Complex AI Templates', 'Explorations'] },
            { year: '5', percents: [45, 10, 45], contents: ['Grade 4', 'Block-Based & Text', 'Complex AI Templates', 'Explorations'] },
            { year: '6', percents: [45, 10, 45], contents: ['Grade 5', 'Text', 'Complex AI Templates', 'Explorations'] }
          ]"
        />
        <p>
          <mixed-color-label
            text="Our K-5 Implementation Pathway will introduce two new **beginner friendly** platforms which include CodeCombat Junior, our flagship elementary level curriculum features a progression of learning levels that **teach basic coding concepts at a slower pace**, and AI HackStack Junior, a **multimodal  AI tool** that allows students to sketch, write, and design their own digital products.This scaffolded progression will let students grow with our immersive content and explore a wide variety of computational thinking and computer science concepts"
          />
        </p>
        <custom-table
          :header-contents="['Middle School', 'Ozaria', 'CodeCombat Worlds', 'AI HackStack', 'AI League']"
          :table-rows="[
            { year: '1', percents: [75, null, 25, null], contents: ['Grade 6', 'Introduction to Coding', 'Introduction to Luau Coding', 'Introduction to AI', 'Introduction to Coding Esports'] },
            { year: '2', percents: [25, null, 75, null], contents: ['Grade 7', 'Loops & Structures', 'Introduction to Creative Mode', 'AI Scenarios', 'Competitive Coding Arenas'] },
            { year: '3', percents: [25, null, 75, null], contents: ['Grade 8', 'Functions & Data', 'Game Development', 'Open-Ended AI Projects', 'Competitive Coding Arenas'] }
          ]"
        />
        <p>
          <mixed-color-label
            :text="`Our middle school implementation establishes a **foundation of coding concepts** with Ozaria, our core
                    Computer Science curriculum. This eventually expands to more voice and choice, where students will
                    **explore coding and AI** across three diverse platforms. The **educator and students can choose** how
                    deeply they will explore each of these additional platforms.
                    `"
          />
        </p>
        <custom-table
          :header-contents="['Middle School', 'CodeCombat', 'CodeCombat Worlds', 'AI HackStack', 'AI League']"
          :table-rows="[
            { year: '1', percents: [90, null, 10, null], contents: ['AP CSP', 'CS1-4 \n Data Science \n Cybersecurity \n Exam Content', 'Game Development', 'Open-Ended AI Projects', 'Competitive Coding Arenas'] },
            { year: '2', percents: [35, 25, 25, 15], contents: ['Advanced CS', 'CS 5-6 \n GD 1-3 \n WD 1-2', 'Advanced Game Development', 'Advanced AI Projects', 'Global Esports tournament'] }
          ]"
        />
        <p>
          <mixed-color-label
            :text="`The first year of our high school curriculum focuses on **AP CS Principles**, which includes our
                    CodeCombat courses, CS1−CS4 and exam curriculum content such as **Data Science** and **Computing
                    Systems**. The more advanced year allows students to explore more of our **advanced CS courses** and
                    offers voice and choice across our three platforms.
                    `"
          />
        </p>
      </div>
    </background-container>

    <div
      id="contact-us"
      class="container"
    >
      <div class="row">
        <div class="col-md-12">
          <h2 class="text-h2">
            <h2 class="text-h2">
              <mixed-color-label :text="$t('home_v3.faq_visit_help_center')" />
            </h2>
          </h2>
        </div>
      </div>
      <div class="row">
        <div class="col-md-12">
          <CTAButton>{{ $t('home_v3.contact_us') }}</CTAButton>
          <p>{{ $t('home_v3.for_further_questions') }}</p>
        </div>
      </div>
    </div>

    <background-container
      type="colored"
    >
      <div class="container">
        <faq-component :faq-items="faqItems" />
      </div>
    </background-container>
  </div>
</template>

<script>
import CarouselComponent from '../../components/common/elements/CarouselComponent.vue'
import CarouselItem from '../../components/common/elements/CarouselItem.vue'
import MixedColorLabel from '../../components/common/labels/MixedColorLabel.vue'
import BackgroundContainer from '../../components/common/backgrounds/BackgroundContainer.vue'
import ContentBox from '../../components/common/elements/ContentBox.vue'
import BoxPanel from '../../components/common/elements/BoxPanel.vue'
import CTAButton from '../../components/common/buttons/CTAButton.vue'
import HeaderComponent from '../../components/common/elements/HeaderComponent.vue'
import ImageAndText from '../../components/common/elements/ImageAndText.vue'
import TwoColumnBlock from '../../components/common/elements/TwoColumnBlock.vue'
import MissionComponent from '../common/MissionComponent.vue'
import TestimonialComponent from '../../components/common/elements/TestimonialComponent.vue'
import FaqComponent from '../../components/common/elements/FaqComponent.vue'

import TurnkeySolutions from './TurnkeySolutions.vue'
import StatsComponent from './StatsComponent.vue'
import CustomTable from './CustomTable.vue'

export default Vue.extend({
  name: 'PageHome',
  components: {
    CarouselComponent,
    CarouselItem,
    MixedColorLabel,
    BackgroundContainer,
    ContentBox,
    BoxPanel,
    CTAButton,
    HeaderComponent,
    ImageAndText,
    TurnkeySolutions,
    StatsComponent,
    TwoColumnBlock,
    MissionComponent,
    CustomTable,
    TestimonialComponent,
    FaqComponent
  },
  data () {
    return {
      testimonals: [
        {
          quote: '“Let me make this clear first. I recommend your product because it is the best programming teaching tool currently on Earth.”',
          name: 'Seth Reichelson',
          title: 'AP Computer Science Teacher, Lake Brantley High School. White House Champion of Change Winner',
          image: '/images/pages/schools/avatar/avatar_seth.png'
        },
        {
          quote: '“[Ozaria] is a full curriculum for computer science education, it’s super impressive, very extensive [...] It’s got everything you need [...] I don\'t know that we\'ve seen anything with this much extra stuff to help you teach it well.”',
          name: 'Tanner Higgin',
          title: 'Editorial Director - Learning Content, Common Sense Education',
          link: 'https://www.youtube.com/watch?v=hCbn7viOf7A&t=60s&ab_channel=CommonSenseEducation',
          image: '/images/pages/schools/avatar/avatar_tanner.png'
        },
        {
          quote: '“CodeCombat was one of the easiest to implement programs we’ve piloted and student engagement was extremely high. The way the content is designed, scaffolds perfectly and allows students to quickly move into high level programming skills far beyond anything we could have hoped for.”',
          name: 'Steve Kong',
          title: 'Instructional Services Specialist, Riverside Unified School District',
          image: '/images/pages/schools/avatar/avatar_steve.png'
        },
        {
          quote: '“One thing I am able to do now that I could not do before is actually believe I can code.”',
          title: 'Mountain Ridge Middle School Student',
          image: '/images/pages/schools/avatar/avatar_student.png'
        },
        {
          quote: '“CodeCombat has transformed how I teach coding...I utilize the great teacher resources including Curriculum Guides, Project Guides, and Solutions. Using CodeCombat has helped me to teach fairly advanced concepts in a way the students enjoy and understand. What I love the most about CodeCombat is that it does not simplify coding. The students are learning to write actual code, yet doing it in such a way that they are having fun.”',
          name: 'Sandra Ahlstrom',
          title: 'Teacher, Sheridan County School District #2',
          image: '/images/pages/schools/avatar/avatar_sandra.png'
        }
      ],
      faqItems: [
        {
          question: 'Is there an age requirement?',
          answer: 'Participants must be aged 13-17 and be able to provide legal documentation to travel.'
        },
        {
          question: 'Can I travel with my child?',
          answer: 'Some parents do choose to travel, however the activities, events, travel and accommodations are only provided for students.'
        },
        {
          question: 'How much experience do you need to participate?',
          answer: 'A basic understanding of programming in any language is all that a student must know. Since we are grouping them into teams of varying experience levels we expect those with more experience to support those with less.'
        }
      ],
      coreCurriculum: [
        {
          title: 'Ozaria Classroom',
          text: 'A narrative coding adventure that establishes the fundamentals of computer science.',
          link: 'https://ozaria.com',
          linkText: 'Try it now',
          image: '/images/pages/schools/boxes/maximize_1.png'
        },
        {
          title: 'CodeCombat Classroom',
          text: 'A full CS curriculum that builds from core concepts all the way through web development, game development and **AP CSP**.',
          link: 'https://codecombat.com/#teacher-signup',
          linkText: 'Try it now',
          image: '/images/pages/schools/boxes/maximize_2.png'
        }
      ],
      practiceEnrichment: [
        {
          title: 'CodeCombat AI League Esports',
          text: 'An epic competitive coding esports platform that encourages creative programming in a game-based environment.',
          link: 'https://codecombat.com/league',
          linkText: 'Try it now',
          image: '/images/pages/schools/boxes/maximize_3.png'
        },
        {
          title: 'CodeCombat Worlds on Roblox',
          text: 'In partnership with Roblox Education, this AI enabled experience super-charges student coding abilities and provides a real-world platform to create amazing games and experiences.',
          link: 'https://codecombat.com/roblox',
          linkText: 'Try it now',
          image: '/images/pages/schools/boxes/maximize_4.png'
        }
      ],
      studentAcceleration: [
        {
          title: 'CodeCombat AI HackStack',
          text: 'The first generative AI companion tool specifically crafted for those new to AI with a focus on student privacy and safety. Blending simplicity and power, the platform accelerates student abilities and unleashes their creative potential.',
          link: 'https://codecombat.com/ai/',
          linkText: 'Try it now',
          image: '/images/pages/schools/boxes/maximize_5.png'
        },
        {
          title: 'AP CSP Exam Preperations',
          text: 'We are recognized by the College Board as an endorsed provider of curriculum and professional development for AP® Computer Science Principles (AP CSP). Our AP CSP curriculum provides game-based and turnkey tools to prepare students for the AP exam.',
          // link: 'https://codecombat.com/roblox',
          linkText: 'Try it now',
          image: '/images/pages/schools/boxes/maximize_6.png'
        }
      ],
      youngLearners: [
        {
          title: 'CodeCombat Jr.',
          text: 'Our flagship K-5 curriculum features a progression of learning levels that teach basic coding concepts at a slower pace, modeled specifically for elementary students.',
          link: '#',
          linkText: 'Sign up for Beta Access',
          image: '/images/pages/schools/boxes/maximize_7.png'
        },
        {
          title: 'AI HackStack Jr.',
          text: 'Introduces multi-modal generative AI in a simple and intuitive platform designed specifically for K-5 students.',
          link: '#',
          linkText: 'Sign up for Beta Access',
          image: '/images/pages/schools/boxes/maximize_8.png'
        }
      ],
      fundingSolutions: [
        {
          title: 'Grant and Funding Sources',
          text: 'We understand the funding hurdles that schools encounter and are passionate about helping to overcome these obstacles. Check out our comprehensive guide to grant funding or speak with our team to learn more.',
          linkText: 'Learn More',
          link: 'https://codecombat.com/grants',
          hasPadding: false,
          mainImageBg: true,
          equalWidth: true,
          image: '/images/pages/schools/boxes/maximize_9.png'
        }
      ],
      supportDevelopment: [
        {
          title: 'Live Online Classes',
          text: 'Want to provide high-quality CS instruction, but don’t have the staff to execute? Our team of master instructors can provide engaging virtual lessons perfect for in-class or after school programs.',
          link: '#',
          linkText: 'Sign up for Beta Access',
          image: '/images/pages/schools/boxes/maximize_10.png'
        },
        {
          title: this.$t('home_v3.solutions_1_title'),
          text: this.$t('home_v3.solutions_1_text'),
          link: 'https://www.ozaria.com/pd',
          linkText: this.$t('home_v3.solutions_1_linkText'),
          frameImage: '/images/pages/home-v3/logo/southern-new-hampshire-university.webp',
          image: '/images/pages/home-v3/solutions/box_1.webp'
        }
      ]
    }
  }
})
</script>

<style>
#page-schools {
  max-width: 100vw;
  overflow-x: hidden;
}
</style>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.testimonals {

  padding-bottom: 80px;

  &__item {
    text-align: center;
  }
}

#page-schools {
  @extend %frontend-page;

  .container {
    &__header {
      padding-top: 80px;
    }

    .text-h1 {
      @extend %font-44;
      text-align: left;
    }

    padding-bottom: 80px;
  }

  #trends {
    ::v-deep .text-h2 {
      margin: 80px auto;
    }

    padding-bottom: 160px;
  }

  #contact-us {
    text-align: center;

    p {
      margin-top: 8px;
      color: $purple;
      text-align: center;
      font-size: 14px;
      font-style: normal;
      font-weight: 700;
      line-height: 32px;
    }
  }

  .pathway {
    .container {
      display: flex;
      flex-direction: column;
      gap: 70px;
    }
  }
}
</style>
