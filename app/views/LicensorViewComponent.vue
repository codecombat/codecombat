<template lang="pug">
div.licensor.container(v-if="!$store.getters['me/isAdmin'] && !$store.getters['me/isLicensor']")
  h4 You must be logged in as a licensor or admin to view this page.
div.licensor.container(v-else)
  h3 Create New License
  form#prepaid-form
    h4.small(style="max-width: 700px" v-if="timeZone == 'Asia/Shanghai'") *All licenses granted after Oct 29, 2018 start at 12am CT on the start date and end at 11:59pm CT on the end date listed. All licenses that were granted before that date start and end at 3pm CT on the date listed.
    h4.small(style="max-width: 700px" v-else) *All licenses granted after July 9, 2018 start at 12am PT on the start date and end at 11:59pm PT on the end date listed. All licenses that were granted before that date start and end at 5pm PT on the date listed.
    .form-group
      label.small
      | Teacher email or Comma separated list of emails
      =" "
      input.form-control(type="text", name="email")
    .form-group
      label.small
      span Number of Licenses
      =" "
      input(type="number", min="1", name="maxRedeemers")
    .form-group
      label.small
      span Start Date
      =" "
      input(type="date", v-bind:value="timestampStart", name="startDate")
    .form-group
      label.small
      span End Date
      =" "
      input(type="date", v-bind:value="timestampEnd", name="endDate")
    .form-group
      div
        label.small(v-if="createLicenseIsLoading")
        span(v-if="createLicenseIsLoading") {{ createLicenseProgress.done }} / {{ createLicenseProgress.total }} emails processed
      button.btn.btn-primary(v-on:click.prevent="onCreateLicense", name="addLicense" v-bind:class="{'disabled' : !!createLicenseIsLoading}") Add Licenses

  h3 Show Licenses
  form#prepaid-show-form
    .form-group
      label.small
      | Teacher email
      =" "
      input.form-control(type="email", name="getEmail")
    .form-group
      button.btn.btn-primary(v-on:click.prevent="onShowLicense", name="showLicense") Show Licenses
  table.table.table-condensed#prepaid-table(v-if="prepaids.length > 0")
    tr
      th.border ID
      th.border Creator
      th.border Type
      th.border(v-if="timeZone == 'Asia/Shanghai'") Start (CT)
      th.border(v-else) Start (PT)
      th.border(v-if="timeZone == 'Asia/Shanghai'") End (CT)
      th.border(v-else) End (PT)
      th.border Used
    tr(v-for="prepaid in prepaids")
      td.border {{prepaid._id}}
      td.border {{prepaid.creator}}
      td.border {{prepaid.type}}
      td.border {{prepaid.startDate}}
      td.border {{prepaid.endDate}}
      td.border {{prepaid.used}} / {{prepaid.maxRedeemers || 0}}

  h3 Create/Edit API Client
  form#client-form
    .form-group
      label.small
      | Client name
      =" "
      input(type="text", name="clientName")
    .form-group
      label.small
      | licenseDaysGranted
      =" "
      input(type="number", :value="defaultClientVal.licenseDaysGranted.default", name="licenseDaysGranted")
    .form-group
      label.small
      | minimumLicenseDays
      =" "
      input(type="number", :value="defaultClientVal.minimumLicenseDays.default", name="minimumLicenseDays")
    .form-group
      label.small
      | manageLicensesViaUI
      =" "
      select(name="manageLicensesViaUI")
        option(:value="defaultClientVal.permissions.properties.manageLicensesViaUI.default") {{defaultClientVal.permissions.properties.manageLicensesViaUI.default}}
        option(:value="!defaultClientVal.permissions.properties.manageLicensesViaUI.default") {{!defaultClientVal.permissions.properties.manageLicensesViaUI.default}}
    .form-group
      label.small
      | manageLicensesViaAPI
      =" "
      select(name="manageLicensesViaAPI")
        option(:value="defaultClientVal.permissions.properties.manageLicensesViaAPI.default") {{defaultClientVal.permissions.properties.manageLicensesViaAPI.default}}
        option(:value="!defaultClientVal.permissions.properties.manageLicensesViaAPI.default") {{!defaultClientVal.permissions.properties.manageLicensesViaAPI.default}}
    .form-group
      label.small
      | revokeLicensesViaUI
      =" "
      select(name="revokeLicensesViaUI")
        option(:value="defaultClientVal.permissions.properties.revokeLicensesViaUI.default") {{defaultClientVal.permissions.properties.revokeLicensesViaUI.default}}
        option(:value="!defaultClientVal.permissions.properties.revokeLicensesViaUI.default") {{!defaultClientVal.permissions.properties.revokeLicensesViaUI.default}}
    .form-group
      label.small
      | revokeLicensesViaAPI
      =" "
      select(name="revokeLicensesViaAPI")
        option(:value="defaultClientVal.permissions.properties.revokeLicensesViaAPI.default") {{defaultClientVal.permissions.properties.revokeLicensesViaAPI.default}}
        option(:value="!defaultClientVal.permissions.properties.revokeLicensesViaAPI.default") {{!defaultClientVal.permissions.properties.revokeLicensesViaAPI.default}}
    .form-group
      label.small
      | manageSubscriptionViaAPI
      =" "
      select(name="manageSubscriptionViaAPI")
        option(:value="defaultClientVal.permissions.properties.manageSubscriptionViaAPI.default") {{defaultClientVal.permissions.properties.manageSubscriptionViaAPI.default}}
        option(:value="!defaultClientVal.permissions.properties.manageSubscriptionViaAPI.default") {{!defaultClientVal.permissions.properties.manageSubscriptionViaAPI.default}}
    .form-group
      label.small
      | revokeSubscriptionViaAPI
      =" "
      select(name="revokeSubscriptionViaAPI")
        option(:value="defaultClientVal.permissions.properties.revokeSubscriptionViaAPI.default") {{defaultClientVal.permissions.properties.revokeSubscriptionViaAPI.default}}
        option(:value="!defaultClientVal.permissions.properties.revokeSubscriptionViaAPI.default") {{!defaultClientVal.permissions.properties.revokeSubscriptionViaAPI.default}}
    .form-group
      button.btn.btn-primary(v-on:click.prevent="onCreateApiClient", name="createClient") Create API Client
      button.btn.btn-primary(v-on:click.prevent="onEditApiClient", name="editClient") Edit API Client
      h4.small *It will create a new API client and generate its secret

  h3 Toggle API Client Feature Flags
  form#client-features-form
    .form-group
      table.table.table-condensed#features-table(v-for="client in ownedClients")
        tr.border
          th API Client
          th Enabled
          th Name
          th Type
        tr.border(v-for="feature in client.features")
          td.center {{client.name}}
          td.center
            input(type="checkbox" v-model="feature.enabled" v-bind:name="client._id+feature.name")
          td.center {{feature.name}}
          td.center {{feature.type}}
    .form-group
      button.btn.btn-primary(v-on:click.prevent="onUpdateApiClientFeatures", name="updateClientFeatures") Update Client Feature Flags
      h4.small *Users created by this API Client will have this feature flag applied on their browser refresh or login

  h3 Show API Client
  form#client-show-form
    .form-group
      label.small
      | Client name
      =" "
      input(type="text", name="clientNameShow")
    .form-group
      button.btn.btn-primary(v-on:click.prevent="onShowApiClient", name="showClient") Show API Client
      button.btn.btn-primary(v-on:click.prevent="onShowAllApiClient", name="showAllClient") Show All API Clients
  table.table.table-condensed#client-table(v-if="clients.length == 1")
    tr
      th.border ID
      th.border Slug
      th.border Name
      th.border License days granted to client
      th.border minimumLicenseDays
      th.border License days used by client
      th.border License days remaining
      th.border Users having active licenses
    tr(v-for="client in clients")
      td.border {{client._id}}
      td.border {{client.slug}}
      td.border {{client.name}}
      td.border {{client.licenseDaysGranted}}
      td.border {{client.minimumLicenseDays}}
      td.border {{client.licenseDaysUsed}}
      td.border {{client.licenseDaysRemaining}}
      td.border {{client.activeLicenses}}
  label.border(v-if = "clients.length == 1" v-for = "client in clients")
    | Client permissions:
    =" "
    h4.small(v-for = "(value, key) in client.permissions")
      | {{key}}: {{value}}
  label.border(v-if="clients.length == 1" v-for="client in clients")
    | Client secret:
    =" "
    h4.small
      | {{client.secret}}
  table.table.table-condensed#client-table(v-if="clients.length > 1")
    tr
      th.border ID
      th.border Name
    tr(v-for="client in clients")
      td.border {{client._id}}
      td.border {{client.name}}

  h3 Create/Edit OAuth Provider
  #oauth-form.form
    .form-group
      label.small
      | Provider Name
      =" "
      input(type="text", name="oauthName")
    .form-group
      label.small
      | Lookup Url Template
      =" "
      input(type="text", name="lookupUrlTemplate")
    .form-group
      label.small
      | Lookup Id Property
      =" "
      input(type="text" name="lookupIdProperty")
    .form-group
      label.small
      | Token Url
      =" "
      input(type="text" name="tokenUrl")
    .form-group
      label.small
      | Token Method
      =" "
      select(name="tokenMethod")
        option(value='') None
        option(value="get") GET
        option(value="post") POST
    .form-group
      label.small
      | Token Auth User (Our client ID to access token url)
      =" "
      input(type="text" name="tokenAuthUser")
    .form-group
      label.small
      | Token Auth Password (Our client password to access token url)
      =" "
      input(type="text" name="tokenAuthPass")
    .form-group
      label.small
      | Strict SSL
      =" "
      select(name="strictSSL")
        option(value='') None
        option(value="true") True
        option(value="false") False
    .form-group
      label.small
      | Redirect Url After Login
      =" "
      input(type="text" name="redirectAfterLogin")
    .form-group
      button.btn.btn-primary(v-on:click.prevent="onCreateOauth", name="createProvider") Create Provider
      button.btn.btn-primary(v-on:click.prevent="onEditOauth", name="editProvider") Edit Provider
      h4.small *Edit will not remove any values that you leave blank here, it will only update if you populate any field

  h3 Show OAuthProvider
  form#oauth-show-form
    .form-group
      label.small
      | Provider name
      =" "
      input(type="text", name="oauthNameShow")
    .form-group
      button.btn.btn-primary(v-on:click.prevent="onShowOauth", name="showProvider") Show Provider
      button.btn.btn-primary(v-on:click.prevent="onShowAllOauth", name="showAllProvider") Show All Providers
  table.table.table-condensed#o-auth-table(v-if="oauthProvider.length == 1" v-for="oauth in oauthProvider")
    tr
      th.border(v-for="(value, key) in oauth") {{key}}
    tr
      td.border(v-for="(value, key) in oauth") {{value}}
  table.table.table-condensed#o-auth-table(v-if="oauthProvider.length > 1")
    tr
      th.border Name
    tr(v-for="oauth in oauthProvider")
      td.border {{oauth.name}}
</template>

<script lang="coffee">
co = require('co')
api = require 'core/api'
moment.timezone = require('moment-timezone')
forms = require 'core/forms'
{getQueryVariable} = require('core/utils')
clientSchema = require '../schemas/models/api-client.schema'

module.exports = Vue.extend({
  data: ->
    prepaids: []
    clients: []
    currentClientFeatures: {}
    ownedClients: []
    oauthProvider: []
    defaultClientVal: clientSchema.properties
    timeZone: 'America/Los_Angeles'
    createLicenseProgress: {
      done: 0,
      total: 0
    }

  created: ->
    return unless me.isAdmin() or me.isLicensor()
    if features?.chinaInfra
      this.timeZone = 'Asia/Shanghai'
    api.apiClients.getAll().then (clients) =>
      @ownedClients = clients
      $.ajax
        type: 'GET',
        url: '/db/feature'
        success: (features) =>
          showGlobalToggles = getQueryVariable('showGlobalToggles', false)
          for i in [0...@ownedClients.length]
            client = @ownedClients[i]
            client.features ?= {}
            @currentClientFeatures[client._id] ?= {}
            for feature in features
              if showGlobalToggles or feature.type isnt 'global'
                client.features[feature._id] = _.assign(_.cloneDeep(feature), client.features[feature._id] ? {})
                @currentClientFeatures[client._id][feature._id] = client.features[feature._id]?.enabled ? false
              else
                delete client.features[feature._id]
            Vue.set(@ownedClients, i, client) # https://vuejs.org/v2/guide/list.html#Caveats
        error: (data) =>
          noty text: 'Failed to find fetch features', type: 'error'
          console.error(data)

  methods:
    runValidation: (element, requiredProps) ->
      forms.clearFormAlerts(element)
      data = forms.formToObject(element[0])
      result = tv4.validateMultiple(data, {required: requiredProps})
      unless result.valid
        forms.applyErrorsToForm(element, result.errors)
        return
      return data

    onCreateLicense: co.wrap ->
      el = $('#prepaid-form')
      requiredProps = ['email', 'maxRedeemers','startDate', 'endDate']
      data = @runValidation(el, requiredProps)
      unless data
        return
      unless data.maxRedeemers > 0
        forms.setErrorToProperty(el, 'maxRedeemers', 'No of licenses should be greater than 0')
        return
      unless data.endDate > data.startDate
        forms.setErrorToProperty(el, 'endDate', 'End Date should be greater than Start Date')
        return

      emails = data.email.split(',').map((s) -> s.trim())
      @createLicenseProgress.total = emails.length
      @createLicenseProgress.done = 0
      errors = []
      for email in emails
        @createLicenseProgress.done += 1
        unless forms.validateEmail(email)
          errors.push("#{email} - invalid email")
          continue
        try
          user = yield api.users.getByEmail({email})
          attrs = data
          attrs.maxRedeemers = parseInt(data.maxRedeemers)
          attrs.endDate = attrs.endDate + " " + "23:59"   # Otherwise, it ends at 12 am by default which does not include the date indicated
          attrs.startDate = moment.timezone.tz(attrs.startDate, this.timeZone).toISOString()
          attrs.endDate = moment.timezone.tz(attrs.endDate, this.timeZone).toISOString()
          _.extend(attrs, {
            type: 'course'
            creator: user._id
            properties:
              licensorAdded: me.id
          })
          prepaid = yield api.prepaids.post(attrs)
          noty text: "License created for #{email}", timeout: 2000, type: 'success'
        catch err
          console.log(err)
          errors.push("#{email} - #{err?.message || 'unknown error. Check console.'}")

      if errors.length
        forms.setErrorToProperty(el, 'addLicense', "Error<br />#{errors.join("<br />")}")

    onShowLicense: co.wrap ->
      el = $('#prepaid-show-form')
      requiredProps = ['getEmail']
      data = @runValidation(el, requiredProps)
      unless data
        return
      unless forms.validateEmail(data.getEmail)
        forms.setErrorToProperty(el, 'getEmail', 'Please enter a valid email address')
        return

      try
        email = data.getEmail
        user = yield api.users.getByEmail({email})
        this.prepaids = yield api.prepaids.getByCreator(user._id, {data: {allTypes: true}})
        unless this.prepaids.length>0
          forms.setErrorToProperty(el, 'showLicense', 'No licenses found for this user')
          return
        for prepaid in this.prepaids
          prepaid.startDate = moment.timezone(prepaid.startDate).tz(this.timeZone).format('l')
          prepaid.endDate = moment.timezone(prepaid.endDate).tz(this.timeZone).format('l')
          Vue.set(prepaid, 'used' , (prepaid.redeemers || []).length)

      catch err
        console.log(err)
        forms.setErrorToProperty(el, 'showLicense', 'Something went wrong')
        return

    onCreateApiClient: co.wrap ->
      el = $('#client-form')
      requiredProps = ['clientName', 'licenseDaysGranted', 'minimumLicenseDays', 'manageLicensesViaUI', 'manageLicensesViaAPI', 'revokeLicensesViaUI', 'revokeLicensesViaAPI', 'manageSubscriptionViaAPI', 'revokeSubscriptionViaAPI']
      data = @runValidation(el, requiredProps)
      unless data
        return

      if data.minimumLicenseDays < 1
          forms.setErrorToProperty(el, 'minimumLicenseDays', 'minimumLicenseDays should be greater than 0')
          return

      if data.licenseDaysGranted < 0
        forms.setErrorToProperty(el, 'licenseDaysGranted', 'licenseDaysGranted should be greater than or equal to 0')
        return
      
      try
        attrs = {
          name: data.clientName
          licenseDaysGranted: parseInt(data.licenseDaysGranted)
          minimumLicenseDays: parseInt(data.minimumLicenseDays)
          permissions: {
            manageLicensesViaUI: (data.manageLicensesViaUI == 'true')
            manageLicensesViaAPI: (data.manageLicensesViaAPI == 'true')
            revokeLicensesViaUI: (data.revokeLicensesViaUI == 'true')
            revokeLicensesViaAPI: (data.revokeLicensesViaAPI == 'true')
            manageSubscriptionViaAPI: (data.manageSubscriptionViaAPI == 'true')
            revokeSubscriptionViaAPI: (data.revokeSubscriptionViaAPI == 'true')
          }
        }
        apiCLient = yield api.apiClients.post(attrs)
        yield api.apiClients.createSecret({clientID: apiCLient._id})
        noty text: 'Client created', timeout: 3000, type: 'success'
      catch err
        console.log(err)
        forms.setErrorToProperty(el, 'createClient', 'Something went wrong')
        return

    onUpdateApiClientFeatures: co.wrap ->
      el = $('#client-features-form')
      requiredProps = []
      for client in @ownedClients
        for featureId, feature of client.features
          requiredProps.push client._id + feature.name
      data = @runValidation(el, requiredProps)
      return unless data
      try
        for client in @ownedClients
          for featureId, feature of client.features
            newSetting = data[client._id + feature.name]?[0] is 'on'
            if @currentClientFeatures[client._id][featureId] isnt newSetting
              yield api.apiClients.updateFeature({clientID: client._id, featureID: feature._id}, {enabled: newSetting})
              @currentClientFeatures[client._id][featureId] = newSetting
        noty text: 'Feature flags updated', timeout: 3000, type: 'success'
      catch err
        console.log(err)
        forms.setErrorToProperty(el, 'updateClientFeatures', 'Something went wrong')
    
    onEditApiClient: co.wrap ->
      el = $('#client-form')
      requiredProps = ['clientName', 'licenseDaysGranted', 'minimumLicenseDays', 'manageLicensesViaUI', 'manageLicensesViaAPI', 'revokeLicensesViaUI', 'revokeLicensesViaAPI', 'manageSubscriptionViaAPI', 'revokeSubscriptionViaAPI']
      data = @runValidation(el, requiredProps)
      unless data
        return

      if data.minimumLicenseDays < 1
        forms.setErrorToProperty(el, 'minimumLicenseDays', 'minimumLicenseDays should be greater than 0')
        return
      
      if data.licenseDaysGranted < 0
        forms.setErrorToProperty(el, 'licenseDaysGranted', 'licenseDaysGranted should be greater than or equal to 0')
        return
      
      try
        apiClient = yield api.apiClients.getByName(data.clientName)
        unless apiClient.length>0
          forms.setErrorToProperty(el, 'editClient', 'API client not found')
          return
        attrs = {
          name: data.clientName
          licenseDaysGranted: parseInt(data.licenseDaysGranted)
          minimumLicenseDays: parseInt(data.minimumLicenseDays)
          permissions: {
            manageLicensesViaUI: (data.manageLicensesViaUI == 'true')
            manageLicensesViaAPI: (data.manageLicensesViaAPI == 'true')
            revokeLicensesViaUI: (data.revokeLicensesViaUI == 'true')
            revokeLicensesViaAPI: (data.revokeLicensesViaAPI == 'true')
            manageSubscriptionViaAPI: (data.manageSubscriptionViaAPI == 'true')
            revokeSubscriptionViaAPI: (data.revokeSubscriptionViaAPI == 'true')
          }
        }
        attrs.id = apiClient[0]._id
        apiClient = yield api.apiClients.editClient(attrs)
        noty text: 'API Client updated', timeout: 3000, type: 'success'
      catch err
        console.log(err)
        forms.setErrorToProperty(el, 'editClient', 'Something went wrong')
        return

    onShowApiClient: co.wrap ->
      el = $('#client-show-form')
      requiredProps = ['clientNameShow']
      data = @runValidation(el, requiredProps)
      unless data
        return

      try
        this.clients = yield api.apiClients.getByName(data.clientNameShow)
        unless this.clients.length > 0
          forms.setErrorToProperty(el, 'showClient', 'No API CLient found')
          return 
        for client in this.clients
          stats = yield api.apiClients.getLicenseStats(client._id)
          Vue.set(client, 'licenseDaysUsed', stats.licenseDaysUsed)
          Vue.set(client, 'activeLicenses', stats.activeLicenses)
          Vue.set(client, 'licenseDaysRemaining', stats.licenseDaysRemaining)
      catch err
        console.log(err)
        forms.setErrorToProperty(el, 'showClient', 'Something went wrong')
        return

    onShowAllApiClient: co.wrap ->
      el = $('#client-show-form')

      try
        this.clients = yield api.apiClients.getAll()
        unless this.clients.length > 0
          forms.setErrorToProperty(el, 'showAllClient', 'No API CLient found')
          return

      catch err
        console.log(err)
        forms.setErrorToProperty(el, 'showAllClient', 'Something went wrong')
        return

    onCreateOauth: co.wrap ->
      el = $('#oauth-form')
      requiredProps = ['oauthName', 'lookupUrlTemplate', 'tokenUrl']
      data = @runValidation(el, requiredProps)
      unless data
        return

      try
        attrs = _.pick(data, 'lookupUrlTemplate', 'tokenUrl', 'tokenMethod', 'lookupIdProperty', 'redirectAfterLogin')
        attrs.name = data.oauthName
        attrs.tokenAuth = {
          user: data.tokenAuthUser
          pass: data.tokenAuthPass
        }
        if data.strictSSL
          attrs.strictSSL = (data.strictSSL == 'true')
        oauthProvider = yield api.oauth.post(attrs)
        noty text: 'OAuth Provider created', timeout: 3000, type: 'success'
      catch err
        console.log(err)
        forms.setErrorToProperty(el, 'createProvider', 'Something went wrong')
        return

    onEditOauth: co.wrap ->
      el = $('#oauth-form')
      requiredProps = ['oauthName']
      data = @runValidation(el, requiredProps)
      unless data
        return

      try
        oauthProvider = yield api.oauth.getByName(data.oauthName)
        unless oauthProvider.length>0
          forms.setErrorToProperty(el, 'editProvider', 'OAuth Provider not found')
          return
        attrs = _.pick(data, 'lookupUrlTemplate', 'tokenUrl', 'tokenMethod', 'lookupIdProperty', 'redirectAfterLogin')
        if data.strictSSL
          attrs.strictSSL = (data.strictSSL == 'true')
        attrs.tokenAuth = {
          user: data.tokenAuthUser
          pass: data.tokenAuthPass
        }
        attrs.id = oauthProvider[0]._id
        oauthProvider = yield api.oauth.editProvider(attrs)
        noty text: 'OAuth Provider updated', timeout: 3000, type: 'success'
      catch err
        console.log(err)
        forms.setErrorToProperty(el, 'editProvider', 'Something went wrong')
        return

    onShowOauth: co.wrap ->
      el = $('#oauth-show-form')
      requiredProps = ['oauthNameShow']
      data = @runValidation(el, requiredProps)
      unless data
        return

      try
        this.oauthProvider = yield api.oauth.getByName(data.oauthNameShow)
        unless this.oauthProvider.length > 0
          forms.setErrorToProperty(el, 'showProvider', 'No OAuth Provider found')
          return
      catch err
        console.log(err)
        forms.setErrorToProperty(el, 'showProvider', 'Something went wrong')
        return

    onShowAllOauth: co.wrap ->
      el = $('#oauth-show-form')

      try
        this.oauthProvider = yield api.oauth.getAll()
        unless this.oauthProvider.length > 0
          forms.setErrorToProperty(el, 'showAllProvider', 'No OAuth Provider found')
          return
      catch err
        console.log(err)
        forms.setErrorToProperty(el, 'showAllProvider', 'Something went wrong')
        return


  computed:
    timestampStart: ->
      return moment.timezone().tz(this.timeZone).format('YYYY-MM-DD')
    timestampEnd: ->
      return moment.timezone().tz(this.timeZone).add(1, 'year').format('YYYY-MM-DD')
    createLicenseIsLoading: ->
      return @createLicenseProgress.done != @createLicenseProgress.total

})

</script>

<style lang="sass">
.border
  border: thin solid grey
</style>
