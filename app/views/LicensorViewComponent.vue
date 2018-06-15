<template lang="jade">
div.licensor.container(v-if="!$store.getters['me/isAdmin'] && !$store.getters['me/isLicensor']")
    h4 You must be logged in as a licensor or admin to view this page.
div.licensor.container(v-else)
    h3 Create New License
    form#prepaid-form
        .form-group
            label.small
            | Teacher email
            =" "
            input.form-control(type="email", name="email")
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
            button.btn.btn-primary(v-on:click.prevent="onCreateLicense", name="addLicense") Add Licenses

    h3 Show Licenses
    form#prepaid-show-form
        .form-group
            label.small
            | Teacher email
            =" "
            input.form-control(type="email", name="getEmail")
        .form-group
            button.btn.btn-primary(v-on:click.prevent="onShowLicense", name="showLicense") Show Licenses
    table.table.table-condensed#prepaid-table(v-if = "prepaids.length > 0")
      tr
        th.border ID
        th.border Creator
        th.border Type
        th.border Start
        th.border End
        th.border Used
      tr(v-for = "prepaid in prepaids")
        td.border {{prepaid._id}}
        td.border {{prepaid.creator}}
        td.border {{prepaid.type}}
        td.border {{prepaid.startDate}}
        td.border {{prepaid.endDate}}
        td.border {{prepaid.used}} / {{prepaid.maxRedeemers || 0}}

    h3 Create API Client
    form#client-form
        .form-group
            label.small
            | Client name
            =" "
            input(type="text", name="clientNameCreate")
        .form-group
            button.btn.btn-primary(v-on:click.prevent="onCreateApiClient", name="createClient") Create API Client
            h4.small *It will create a new API client and generate its secret

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
    table.table.table-condensed#client-table(v-if = "clients.length == 1")
        tr
            th.border ID
            th.border Slug
            th.border Name
            th.border No of license days assigned by client
            th.border No of users to whom licenses have been assigned
        tr(v-for = "client in clients")
            td.border {{client._id}}
            td.border {{client.slug}}
            td.border {{client.name}}
            td.border {{client.licenses}}
            td.border {{client.users}}
    label.border(v-if = "clients.length == 1" v-for = "client in clients")
        | Client secret:
        =" "
        h4.small
            | {{client.secret}}
    table.table.table-condensed#client-table(v-if = "clients.length > 1")
        tr
            th.border Name
        tr(v-for = "client in clients")
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
    table.table.table-condensed#o-auth-table(v-if = "oauthProvider.length == 1" v-for = "oauth in oauthProvider")
        tr
            th.border(v-for="(value, key) in oauth") {{key}}
        tr
            td.border(v-for="(value, key) in oauth") {{value}}
    table.table.table-condensed#o-auth-table(v-if = "oauthProvider.length > 1")
        tr
            th.border Name
        tr(v-for = "oauth in oauthProvider")
            td.border {{oauth.name}}
  
</template>

<script lang="coffee">
co = require('co')
api = require 'core/api'
moment = require('moment')
Prepaids = require 'collections/Prepaids'
forms = require 'core/forms'

module.exports = Vue.extend({
  data: ->
    prepaids: []
    clients: []
    oauthProvider: []

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
        unless forms.validateEmail(data.email)
            forms.setErrorToProperty(el, 'email', 'Please enter a valid email address')
            return
        unless data.maxRedeemers > 0
            forms.setErrorToProperty(el, 'maxRedeemers', 'No of licenses should be greater than 0')
            return
        unless data.endDate > data.startDate
            forms.setErrorToProperty(el, 'endDate', 'End Date should be greater than Start Date')
            return
        try
            email = data.email
            user = yield api.users.getByEmail({email})
            attrs = data
            attrs.maxRedeemers = parseInt(data.maxRedeemers)
            _.extend(attrs, {
                type: 'course'
                creator: user._id
                properties:
                    licensorAdded: me.id
            })
            prepaid = yield api.prepaids.post(attrs)
            alert("License created")
        catch err
            console.log(err)
            forms.setErrorToProperty(el, 'addLicense', 'Something went wrong')
            return

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
                prepaid.startDate = moment(prepaid.startDate).utc().format('l')
                prepaid.endDate = moment(prepaid.endDate).utc().format('l')
                Vue.set(prepaid, 'used' , (prepaid.redeemers || []).length)
            
        catch err
            console.log(err)
            forms.setErrorToProperty(el, 'showLicense', 'Something went wrong')
            return

    onCreateApiClient: co.wrap ->
        el = $('#client-form')
        requiredProps = ['clientNameCreate']
        data = @runValidation(el, requiredProps)
        unless data
            return

        try
            attrs = {
                name: data.clientNameCreate
            }
            apiCLient = yield api.apiClients.post(attrs)
            yield api.apiClients.createSecret({clientID: apiCLient._id})
            alert("Client created")
        catch err
            console.log(err)
            forms.setErrorToProperty(el, 'createClient', 'Something went wrong')
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
                clientPrepaids = yield api.prepaids.getByClient(client._id)
                if clientPrepaids.length > 0
                    Vue.set(client, 'users', clientPrepaids.length)
                    licenses = 0
                    for clientPrepaid in clientPrepaids
                        start = new Date(clientPrepaid.startDate)
                        end = new Date(clientPrepaid.endDate)
                        licenses += Math.ceil(Math.abs(end.getTime() - start.getTime()) / (1000 * 3600 * 24))
                    Vue.set(client, 'licenses', licenses)
                else
                    Vue.set(client, 'users', 0)
                    Vue.set(client, 'licenses', 0)

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
            alert("OAuth Provider created")
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
            alert("OAuth Provider updated")
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
            return moment().format('YYYY-MM-DD')
        timestampEnd: ->
            return moment().add(1, 'year').format('YYYY-MM-DD')
    
})

</script>

<style lang="sass">

.border
    border: thin solid grey

</style>
