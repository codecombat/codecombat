CocoView = require 'views/kinds/CocoView'
template = require 'templates/account/job_profile'
{me} = require 'lib/auth'

module.exports = class JobProfileView extends CocoView
  id: 'job-profile-view'
  template: template

  editableSettings: [
    'lookingFor', 'active', 'name', 'city', 'country', 'skills', 'experience', 'shortDescription', 'longDescription',
    'work', 'education', 'visa', 'projects', 'links', 'jobTitle', 'photoURL'
  ]
  readOnlySettings: []  #['updated']

  afterRender: ->
    super()
    return unless @supermodel.finished()
    _.defer => @buildJobProfileTreema()  # Not sure why, but the Treemas don't fully build without this if you reload the page.

  buildJobProfileTreema: ->
    visibleSettings = @editableSettings.concat @readOnlySettings
    data = _.pick (me.get('jobProfile') ? {}), (value, key) -> key in visibleSettings
    data.name ?= (me.get('firstName') + ' ' + me.get('lastName')).trim() if me.get('firstName')
    schema = _.cloneDeep me.schema().properties.jobProfile
    schema.properties = _.pick schema.properties, (value, key) -> key in visibleSettings
    schema.required = _.intersection schema.required, visibleSettings
    for prop in @readOnlySettings
      schema.properties[prop].readOnly = true
    treemaOptions =
      filePath: "db/user/#{me.id}"
      schema: schema
      data: data
      aceUseWrapMode: true
      callbacks: {change: @onJobProfileChanged}
      nodeClasses:
        'skill': SkillTagNode
        'link-name': LinkNameNode
        'city': CityNode
        'country': CountryNode

    @jobProfileTreema = @$el.find('#job-profile-treema').treema treemaOptions
    @jobProfileTreema.build()
    @jobProfileTreema.open()
    @updateProgress()

  onJobProfileChanged: (e) =>
    @hasEditedProfile = true
    @trigger 'change'
    @updateProgress()

  updateProgress: ->
    completed = 0
    totalWeight = 0
    next = null
    for metric in metrics = @getProgressMetrics()
      done = metric.fn()
      completed += metric.weight if done
      totalWeight += metric.weight
      next = metric.name unless next or done
    progress = Math.round 100 * completed / totalWeight
    bar = @$el.find('.profile-completion-progress .progress-bar')
    bar.css 'width', "#{progress}%"
    text = ''
    if progress > 19
      text = "#{progress}% complete"
    else if progress > 5
      text = "#{progress}%"
    bar.text text
    bar.parent().toggle Boolean progress
    @$el.find('.progress-next-item').text(next).toggle Boolean next

  getProgressMetrics: ->
    return @progressMetrics if @progressMetrics
    schema = me.schema().properties.jobProfile
    jobProfile = @jobProfileTreema.data
    exists = (field) -> -> jobProfile[field]
    modified = (field) -> -> jobProfile[field] and jobProfile[field] isnt schema.properties[field].default
    listStarted = (field, subfields) -> -> jobProfile[field]?.length and _.every subfields, (subfield) -> jobProfile[field][0][subfield]
    @progressMetrics = [
      {name: 'Mark yourself open to offers to show up in searches.', weight: 1, fn: modified 'active'}
      {name: 'Specify your desired job title.', weight: 0, fn: exists 'jobTitle'}
      {name: 'Provide your name.', weight: 1, fn: modified 'name'}
      {name: 'Choose your city.', weight: 1, fn: modified 'city'}
      {name: 'Pick your country.', weight: 0, fn: exists 'country'}
      {name: 'List at least five skills.', weight: 2, fn: -> jobProfile.skills.length >= 5}
      {name: 'Write a short description to summarize yourself at a glance.', weight: 2, fn: modified 'shortDescription'}
      {name: 'Fill in your main description to sell yourself and describe the work you\'re looking for.', weight: 3, fn: modified 'longDescription'}
      {name: 'List your work experience.', weight: 3, fn: listStarted 'work', ['role', 'employer']}
      {name: 'Recount your educational ordeals.', weight: 3, fn: listStarted 'education', ['degree', 'school']}
      {name: 'Show off up to three projects you\'ve worked on.', weight: 3, fn: listStarted 'projects', ['name']}
      {name: 'Add any personal or social links.', weight: 2, fn: listStarted 'links', ['link', 'name']}
      {name: 'Add an optional professional photo.', weight: 2, fn: modified 'photoURL'}
    ]

  getData: ->
    return {} unless me.get('jobProfile') or @hasEditedProfile
    _.pick @jobProfileTreema.data, (value, key) => key in @editableSettings

JobProfileView.commonSkills = commonSkills = ['c#', 'java', 'javascript', 'php', 'android', 'jquery', 'python', 'c++', 'html', 'mysql', 'ios', 'asp.net', 'css', 'sql', 'iphone', '.net', 'objective-c', 'ruby-on-rails', 'c', 'ruby', 'sql-server', 'ajax', 'wpf', 'linux', 'database', 'django', 'vb.net', 'windows', 'facebook', 'r', 'html5', 'multithreading', 'ruby-on-rails-3', 'wordpress', 'winforms', 'node.js', 'spring', 'osx', 'performance', 'visual-studio-2010', 'oracle', 'swing', 'algorithm', 'git', 'linq', 'apache', 'web-services', 'perl', 'wcf', 'entity-framework', 'bash', 'visual-studio', 'sql-server-2008', 'hibernate', 'actionscript-3', 'angularjs', 'matlab', 'qt', 'ipad', 'sqlite', 'cocoa-touch', 'cocoa', 'flash', 'mongodb', 'codeigniter', 'jquery-ui', 'css3', 'tsql', 'google-maps', 'silverlight', 'security', 'delphi', 'vba', 'postgresql', 'jsp', 'shell', 'internet-explorer', 'google-app-engine', 'sockets', 'validation', 'scala', 'oop', 'unit-testing', 'xaml', 'parsing', 'twitter-bootstrap', 'google-chrome', 'http', 'magento', 'email', 'android-layout', 'flex', 'rest', 'maven', 'jsf', 'listview', 'date', 'winapi', 'windows-phone-7', 'facebook-graph-api', 'unix', 'url', 'c#-4.0', 'jquery-ajax', 'svn', 'symfony2', 'table', 'cakephp', 'firefox', 'ms-access', 'java-ee', 'jquery-mobile', 'python-2.7', 'tomcat', 'zend-framework', 'opencv', 'visual-c++', 'opengl', 'spring-mvc', 'sql-server-2005', 'authentication', 'search', 'xslt', 'servlets', 'pdf', 'animation', 'math', 'batch-file', 'excel-vba', 'iis', 'mod-rewrite', 'sharepoint', 'gwt', 'powershell', 'visual-studio-2012', 'haskell', 'grails', 'ubuntu', 'networking', 'nhibernate', 'design-patterns', 'testing', 'jpa', 'visual-studio-2008', 'core-data', 'user-interface', 'audio', 'backbone.js', 'gcc', 'mobile', 'design', 'activerecord', 'extjs', 'video', 'stored-procedures', 'optimization', 'drupal', 'image-processing', 'android-intent', 'logging', 'web-applications', 'razor', 'database-design', 'azure', 'vim', 'memory-management', 'model-view-controller', 'cordova', 'c++11', 'selenium', 'ssl', 'assembly', 'soap', 'boost', 'canvas', 'google-maps-api-3', 'netbeans', 'heroku', 'jsf-2', 'encryption', 'hadoop', 'linq-to-sql', 'dll', 'xpath', 'data-binding', 'windows-phone-8', 'phonegap', 'jdbc', 'python-3.x', 'twitter', 'mvvm', 'gui', 'web', 'jquery-plugins', 'numpy', 'deployment', 'ios7', 'emacs', 'knockout.js', 'graphics', 'joomla', 'unicode', 'windows-8', 'android-fragments', 'ant', 'command-line', 'version-control', 'yii', 'github', 'amazon-web-services', 'macros', 'ember.js', 'svg', 'opengl-es', 'django-models', 'solr', 'orm', 'blackberry', 'windows-7', 'ruby-on-rails-4', 'compiler', 'tcp', 'pdo', 'architecture', 'groovy', 'nginx', 'concurrency', 'paypal', 'iis-7', 'express', 'vbscript', 'google-chrome-extension', 'memory-leaks', 'rspec', 'actionscript', 'interface', 'fonts', 'oauth', 'ssh', 'tfs', 'junit', 'struts2', 'd3.js', 'coldfusion', '.net-4.0', 'jqgrid', 'asp-classic', 'https', 'plsql', 'stl', 'sharepoint-2010', 'asp.net-web-api', 'mysqli', 'sed', 'awk', 'internet-explorer-8', 'jboss', 'charts', 'scripting', 'matplotlib', 'laravel', 'clojure', 'entity-framework-4', 'intellij-idea', 'xml-parsing', 'sqlite3', '3d', 'io', 'mfc', 'devise', 'playframework', 'youtube', 'amazon-ec2', 'localization', 'cuda', 'jenkins', 'ssis', 'safari', 'doctrine2', 'vb6', 'amazon-s3', 'dojo', 'air', 'eclipse-plugin', 'android-asynctask', 'crystal-reports', 'cocos2d-iphone', 'dns', 'highcharts', 'ruby-on-rails-3.2', 'ado.net', 'sql-server-2008-r2', 'android-emulator', 'spring-security', 'cross-browser', 'oracle11g', 'bluetooth', 'f#', 'msbuild', 'drupal-7', 'google-apps-script', 'mercurial', 'xna', 'google-analytics', 'lua', 'parallel-processing', 'internationalization', 'java-me', 'mono', 'monotouch', 'android-ndk', 'lucene', 'kendo-ui', 'linux-kernel', 'terminal', 'phpmyadmin', 'makefile', 'ffmpeg', 'applet', 'active-directory', 'coffeescript', 'pandas', 'responsive-design', 'xhtml', 'silverlight-4.0', '.net-3.5', 'jaxb', 'ruby-on-rails-3.1', 'gps', 'geolocation', 'network-programming', 'windows-services', 'laravel-4', 'ggplot2', 'rss', 'webkit', 'functional-programming', 'wsdl', 'telerik', 'maven-2', 'cron', 'mapreduce', 'websocket', 'automation', 'windows-runtime', 'django-forms', 'tkinter', 'android-widget', 'android-activity', 'rubygems', 'content-management-system', 'doctrine', 'django-templates', 'gem', 'fluent-nhibernate', 'seo', 'meteor', 'serial-port', 'glassfish', 'documentation', 'cryptography', 'ef-code-first', 'extjs4', 'x86', 'wordpress-plugin', 'go', 'wix', 'linq-to-entities', 'oracle10g', 'cocos2d', 'selenium-webdriver', 'open-source', 'jtable', 'qt4', 'smtp', 'redis', 'jvm', 'openssl', 'timezone', 'nosql', 'erlang', 'playframework-2.0', 'machine-learning', 'mocking', 'unity3d', 'thread-safety', 'android-actionbar', 'jni', 'udp', 'jasper-reports', 'zend-framework2', 'apache2', 'internet-explorer-7', 'sqlalchemy', 'neo4j', 'ldap', 'jframe', 'youtube-api', 'filesystems', 'make', 'flask', 'gdb', 'cassandra', 'sms', 'g++', 'django-admin', 'push-notification', 'statistics', 'tinymce', 'locking', 'javafx', 'firefox-addon', 'fancybox', 'windows-phone', 'log4j', 'uikit', 'prolog', 'socket.io', 'icons', 'oauth-2.0', 'refactoring', 'sencha-touch', 'elasticsearch', 'symfony1', 'google-api', 'webserver', 'wpf-controls', 'microsoft-metro', 'gtk', 'flex4', 'three.js', 'gradle', 'centos', 'angularjs-directive', 'internet-explorer-9', 'sass', 'html5-canvas', 'interface-builder', 'programming-languages', 'gmail', 'jersey', 'twitter-bootstrap-3', 'arduino', 'requirejs', 'cmake', 'web-development', 'software-engineering', 'startups', 'entrepreneurship', 'social-media-marketing', 'writing', 'marketing', 'web-design', 'graphic-design', 'game-development', 'game-design', 'photoshop', 'illustrator', 'robotics', 'aws', 'devops', 'mathematica', 'bioinformatics', 'data-vis', 'ui', 'embedded-systems', 'codecombat']

JobProfileView.commonLinkNames = commonLinkNames = ['GitHub', 'Facebook', 'Twitter', 'G+', 'LinkedIn', 'Personal Website', 'Blog']

JobProfileView.commonCountries = commonCountries = ['Afghanistan', 'Albania', 'Algeria', 'American Samoa', 'Andorra', 'Angola', 'Anguilla', 'Antarctica', 'Antigua and Barbuda', 'Argentina', 'Armenia', 'Aruba', 'Australia', 'Austria', 'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus', 'Belgium', 'Belize', 'Benin', 'Bermuda', 'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei Darussalam', 'Bulgaria', 'Burkina Faso', 'Burundi', 'Cambodia', 'Cameroon', 'Canada', 'Cape Verde', 'Cayman Islands', 'Central African Republic', 'Chad', 'Chile', 'China', 'Christmas Island', 'Cocos (Keeling) Islands', 'Colombia', 'Comoros', 'Democratic Republic of the Congo (Kinshasa)', 'Congo, Republic of (Brazzaville)', 'Cook Islands', 'Costa Rica', 'Ivory Coast', 'Croatia', 'Cuba', 'Cyprus', 'Czech Republic', 'Denmark', 'Djibouti', 'Dominica', 'Dominican Republic', 'East Timor', 'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia', 'Ethiopia', 'Falkland Islands', 'Faroe Islands', 'Fiji', 'Finland', 'France', 'French Guiana', 'French Polynesia', 'French Southern Territories', 'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana', 'Gibraltar', 'Great Britain', 'Greece', 'Greenland', 'Grenada', 'Guadeloupe', 'Guam', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti', 'Holy See', 'Honduras', 'Hong Kong', 'Hungary', 'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Jamaica', 'Japan', 'Jordan', 'Kazakhstan', 'Kenya', 'Kiribati', 'North Korea', 'South Korea', 'Kosovo', 'Kuwait', 'Kyrgyzstan', 'Lao, People\'s Democratic Republic', 'Latvia', 'Lebanon', 'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg', 'Macau', 'Macedonia, Rep. of', 'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta', 'Marshall Islands', 'Martinique', 'Mauritania', 'Mauritius', 'Mayotte', 'Mexico', 'Micronesia, Federal States of', 'Moldova, Republic of', 'Monaco', 'Mongolia', 'Montenegro', 'Montserrat', 'Morocco', 'Mozambique', 'Myanmar, Burma', 'Namibia', 'Nauru', 'Nepal', 'Netherlands', 'Netherlands Antilles', 'New Caledonia', 'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'Niue', 'Northern Mariana Islands', 'Norway', 'Oman', 'Pakistan', 'Palau', 'Palestinian territories', 'Panama', 'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Pitcairn Island', 'Poland', 'Portugal', 'Puerto Rico', 'Qatar', 'Reunion Island', 'Romania', 'Russian Federation', 'Rwanda', 'Saint Kitts and Nevis', 'Saint Lucia', 'Saint Vincent and the Grenadines', 'Samoa', 'San Marino', 'Sao Tome and Principe', 'Saudi Arabia', 'Senegal', 'Serbia', 'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia', 'Solomon Islands', 'Somalia', 'South Africa', 'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Swaziland', 'Sweden', 'Switzerland', 'Syria, Syrian Arab Republic', 'Taiwan', 'Tajikistan', 'Tanzania; officially the United Republic of Tanzania', 'Thailand', 'Tibet', 'Timor-Leste', 'Togo', 'Tokelau', 'Tonga', 'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Turkmenistan', 'Turks and Caicos Islands', 'Tuvalu', 'Uganda', 'Ukraine', 'United Arab Emirates', 'United Kingdom', 'USA', 'Uruguay', 'Uzbekistan', 'Vanuatu', 'Vatican City State', 'Venezuela', 'Vietnam', 'Virgin Islands (British)', 'Virgin Islands (U.S.)', 'Wallis and Futuna Islands', 'Western Sahara', 'Yemen', 'Zambia', 'Zimbabwe']

JobProfileView.commonCities = commonCities = ['Tokyo', 'Jakarta', 'Seoul', 'Delhi', 'Shanghai', 'Manila', 'Karachi', 'New York', 'Sao Paulo', 'Mexico City', 'Cairo', 'Beijing', 'Osaka', 'Mumbai (Bombay)', 'Guangzhou', 'Moscow', 'Los Angeles', 'Calcutta', 'Dhaka', 'Buenos Aires', 'Istanbul', 'Rio de Janeiro', 'Shenzhen', 'Lagos', 'Paris', 'Nagoya', 'Lima', 'Chicago', 'Kinshasa', 'Tianjin', 'Chennai', 'Bogota', 'Bengaluru', 'London', 'Taipei', 'Ho Chi Minh City (Saigon)', 'Dongguan', 'Hyderabad', 'Chengdu', 'Lahore', 'Johannesburg', 'Tehran', 'Essen', 'Bangkok', 'Hong Kong', 'Wuhan', 'Ahmedabad', 'Chongqung', 'Baghdad', 'Hangzhou', 'Toronto', 'Kuala Lumpur', 'Santiago', 'Dallas-Fort Worth', 'Quanzhou', 'Miami', 'Shenyang', 'Belo Horizonte', 'Philadelphia', 'Nanjing', 'Madrid', 'Houston', 'Xi\'an-Xianyang', 'Milan', 'Luanda', 'Pune', 'Singapore', 'Riyadh', 'Khartoum', 'Saint Petersburg', 'Atlanta', 'Surat', 'Washington', 'Bandung', 'Surabaya', 'Yangoon', 'Alexandria', 'Guadalajara', 'Harbin', 'Boston', 'Zhengzhou', 'Qingdao', 'Abidjan', 'Barcelona', 'Monterrey', 'Ankara', 'Suzhou', 'Phoenix-Mesa', 'Salvador', 'Porto Alegre', 'Rome', 'Accra', 'Sydney', 'Recife', 'Naples', 'Detroit', 'Dalian', 'Fuzhou', 'Medellin', 'San Francisco', 'Silicon Valley', 'Portland', 'Seattle', 'Austin', 'Denver', 'Boulder']

autoFocus = true  # Not working right now, possibly a Treema bower thing.

class SkillTagNode extends TreemaNode.nodeMap.string
  buildValueForEditing: (valEl) ->
    super(valEl)
    valEl.find('input').autocomplete(source: commonSkills, minLength: 1, delay: 0, autoFocus: autoFocus)
    valEl

class LinkNameNode extends TreemaNode.nodeMap.string
  buildValueForEditing: (valEl) ->
    super(valEl)
    valEl.find('input').autocomplete(source: commonLinkNames, minLength: 0, delay: 0, autoFocus: autoFocus)
    valEl

class CityNode extends TreemaNode.nodeMap.string
  buildValueForEditing: (valEl) ->
    super(valEl)
    valEl.find('input').autocomplete(source: commonCities, minLength: 1, delay: 0, autoFocus: autoFocus)
    valEl

class CountryNode extends TreemaNode.nodeMap.string
  buildValueForEditing: (valEl) ->
    super(valEl)
    valEl.find('input').autocomplete(source: commonCountries, minLength: 1, delay: 0, autoFocus: autoFocus)
    valEl
