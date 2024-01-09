<template>
  <div class="FA-qs">
    <div class="frame">
      <div class="heading">
        Frequently Asked Questions
      </div>
      <div
        id="accordion"
        class="faq-list"
      >
        <FaqItem
          id="collapseOne"
          question="Is there an age requirement?"
          href="#collapseOne"
        >
          Participants must be aged 13-17 and be able to provide legal documentation to travel.
        </FaqItem>
        <FaqItem
          id="collapseTwo"
          question="Can I travel with my child?"
          href="#collapseTwo"
        >
          Some parents do choose to travel, however the activities, events, travel and accommodations are only provided for students.
        </FaqItem>
        <FaqItem
          id="collapseThree"
          question="How much experience do you need to participate?"
          href="#collapseThree"
        >
          A basic understanding of programming in any language is all that a student must know. Since we are grouping them into teams of varying experience levels we expect those with more experience to support those with less.
        </FaqItem>
        <FaqItem
          id="collapseFour"
          question="Should I bring my laptop?"
          href="#collapseFour"
        >
          We will supply all the hardware and software needed to participate in the hackathons. While we will allow participants to use their personal computers, our team may not be able to fully support or troubleshoot all issues, so we recommend using the equipment provided.
        </FaqItem>
        <FaqItem
          id="collapseFive"
          question="Do I need bring any identification supporting materials?"
          href="#collapseFive"
        >
          Domestic - if the participant is traveling alone, we ask their parent or legal guardian to complete an emergency contact form that includes identification information about their child.<br>
          Global - global students need to bring their passports (with VISA) with them.
        </FaqItem>
        <FaqItem
          id="collapseSix"
          question="What accommodations can my child expect?"
          href="#collapseSix"
        >
          All participants and chaperones will be staying at [hotel], with separate accommodations for participants and chaperones. Participants will share a room with a fellow participant. Staff members are never allowed to be alone with participants. Parents who wish to accompany their child will share a room together.
        </FaqItem>
        <FaqItem
          id="collapseSeven"
          question="What if my child is allergic to certain foods or has medical needs?"
          href="#collapseSeven"
        >
          Any health concerns pertaining to your child should be identified in the emergency contact form.
        </FaqItem>
        <FaqItem
          id="collapseEight"
          question="Who will be chaperoning my child?"
          href="#collapseEight"
        >
          Our pledge is to put your children in the company of the most trustworthy and capable individuals we can hire–[certified instructors and counselors] who are well suited to the task of caring for participants. Each staff member undergoes an intense background and reference check; the effort we put into screening and selecting our staff is part of that pledge.<br><br>
          Our staff work with your children in the context of a visible, well scrutinized environment that has many built-in checks and balances. Instructors and counselors are guided by clear, firm policies regarding behavior. Their actions are visible to co-workers and participants.
        </FaqItem>
        <FaqItem
          id="collapseNine"
          question="What general safety measures do you have in place?"
          href="#collapseNine"
        >
          All staff go through emergency and crisis management training.
        </FaqItem>
        <FaqItem
          id="collapseTen"
          question="What is your refund policy?"
          href="#collapseTen"
        >
          Deposits to hold your space are refundable up until travel is booked for the participant. Once travel is booked we will not be able to provide a refund.
        </FaqItem>
      </div>
      <p class="p">
        <span class="span">See more frequently asked questions in our </span>
        <a
          href="https://codecombat.zendesk.com/hc/en-us"
          rel="noopener noreferrer"
          target="_blank"
        >
          <span class="text-wrapper-2">help center</span><span class="span">.</span>
        </a>
      </p>
    </div>
  </div>
</template>

<script>
import FaqItem from './FaqItem.vue'

export default {
  name: 'FaQs',
  components: {
    FaqItem
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
.FA-qs {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 40px;
  justify-content: center;
  padding: 100px 135px;
  position: relative;
  @media (max-width: $screen-md-max) {
    padding: 100px 40px;
  }

  .frame {
    align-items: center;
    display: inline-flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 80px;
    justify-content: center;
    position: relative;
    width: 100%;
  }

  .heading {
    font-family: "Plus Jakarta Sans-Medium", Helvetica;
    font-size: 36px;
    font-weight: 500;
    letter-spacing: 0;
    line-height: 45px;
    margin-top: -1px;
    position: relative;
    text-align: center;
  }

  .faq-list {
    align-items: flex-start;
    display: inline-flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 0;
    position: relative;
    width: 100%;
  }

  .p {
    color: transparent;
    font-family: "Plus Jakarta Sans-Medium", Helvetica;
    font-size: 28px;
    font-weight: 500;
    letter-spacing: 0;
    line-height: 36px;
    position: relative;
    text-align: center;
  }

  .span {
    color: #111928;
  }

  .text-wrapper-2 {
    color: #4799A9;
  }
}
</style>
