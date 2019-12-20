require('app/styles/contact-geek.sass')
RootView = require 'views/core/RootView'
template = require 'templates/contact-geek-view'


module.exports = class ContactGEEKView extends RootView
  id: 'contact-geek-view'
  template: template

  events:
    'click .one': 'onClickOne'
    'click .two': 'onClickTwo'

  initialize: (options) ->

  afterInsert: ->
    value = @getCookie("name");
    console.log value
    if value == 1
      this.render()
      f = ->
        window.location.href = 'https://koudashijie.com/'
      setTimeout f, 5000
    else
      this.render()
      f = ->
        window.location.href = 'https://codecombat.163.com/#/'
      setTimeout f, 5000


  getRenderData: ->
    c = super(arguments...)
    c.value = @getCookie("name");
    c

  onClickOne: (e) ->
    console.log e
    @setCookie("name","1");

  onClickTwo: (e) ->
    console.log e
    @setCookie("name","2");

  setCookie:(name,value) ->
    Days = 30;
    exp = new Date();
    exp.setTime(exp.getTime() + Days*24*60*60*1000);
    document.cookie = name + "="+  (value) + ";expires=" + exp.toGMTString();

  getCookie:(name) ->
    arr
    reg=new RegExp("(^| )"+name+"=([^;]*)(;|$)");
    if(arr=document.cookie.match(reg))
      return unescape(arr[2]);
    else
      return null;