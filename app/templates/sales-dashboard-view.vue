
  <div class="container">
    <ol class="skipped-contacts" v-if="skippedContacts.loaded">
      <li v-for="skippedContact in skippedContacts.models">
        <li class="skipped-contact"></li>
          <!-- - var trialRequest = skippedContact.get('trialRequest') -->
          <!-- if trialRequest -->
          {{message}}
            <h2 v-if="skippedContact.get('trialRequest')">
              {{trialRequest.properties.email}}
            </h2>
          <!-- if skippedContact.get('archived') -->
            <button v-if="skippedContact.get('archived')" class="unarchive-contact" :data-contact-id="skippedContact.id">
              Unarchive
            </button>
          <!-- else
            button.archive-contact(data-contact-id=skippedContact.id)
              | Archive
          if !skippedContact.get('archived')
            div
              = "Reason skipped: "
              = skippedContact.get('reasonSkipped')
            pre
              = JSON.stringify(skippedContact.attributes, null, 4)
            pre
              = noteData(skippedContact) -->
      </li>
    </ol>
  </div>
