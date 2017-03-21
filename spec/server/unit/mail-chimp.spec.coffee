mailChimp = require '../../../server/lib/mail-chimp'

describe '/server/lib/mail-chimp', ->
  describe '.makeSubscriberUrl()', ->
    it 'works according to the example', ->
      # http://developer.mailchimp.com/documentation/mailchimp/guides/manage-subscribers-with-the-mailchimp-api/
      
      # > ...to get the MD5 hash of the email address Urist.McVankab@freddiesjokes.com, first convert the address 
      # > to its lowercase version: urist.mcvankab@freddiesjokes.com. The MD5 hash of 
      # > urist.mcvankab@freddiesjokes.com is 62eeb292278cc15f5817cb78f7790b08.
      
      url = mailChimp.makeSubscriberUrl('Urist.McVankab@freddiesjokes.com')
      expect(url.indexOf('62eeb292278cc15f5817cb78f7790b08')).toBeGreaterThan(-1)
