# Analytics tags added to main.html when on cp.codecombat.com

module.exports =
    header: '''
    <!-- Facebook Pixel Code -->
    <script>
        !function(f,b,e,v,n,t,s){if(f.fbq)return;n=f.fbq=function(){n.callMethod?
                n.callMethod.apply(n,arguments):n.queue.push(arguments)};if(!f._fbq)f._fbq=n;
            n.push=n;n.loaded=!0;n.version='2.0';n.queue=[];t=b.createElement(e);t.async=!0;
            t.src=v;s=b.getElementsByTagName(e)[0];s.parentNode.insertBefore(t,s)}(window, document,'script','//connect.facebook.net/en_US/fbevents.js');
        fbq('init', '126738420993822');
        fbq('track', "PageView");</script>
    <noscript><img height="1" width="1" style="display:none" src="https://www.facebook.com/tr?id=126738420993822&ev=PageView&noscript=1"/></noscript>
    <!-- End Facebook Pixel Code —>
     
    <!-- start of lenovo tag -->
    <script type="text/javascript">
        (function(a,b,c,d){
            a='//tags.tiqcdn.com/utag/lenovo/landing-pages/prod/utag.js';
            b=document;c='script';d=b.createElement(c);d.src=a;d.type='text/java'+c;d.async=true;
            a=b.getElementsByTagName(c)[0];a.parentNode.insertBefore(d,a);
        })();
    </script>
    <!-- end of lenovo tag —>
     
    <!--
    Start of DoubleClick Floodlight Tag: Please do not remove
    Activity name of this tag: Lenovo Indie Gaming
    URL of the webpage where the tag is expected to be placed: https://www.lenovo.com/gamestate/
    This tag must be placed between the <body> and </body> tags, as close as possible to the opening tag.
    Creation Date: 11/17/2015
    -->
    <script type="text/javascript">
        var axel = Math.random() + "";
        var a = axel * 10000000000000;
        document.write('<iframe src="https://4276718.fls.doubleclick.net/activityi;src=4276718;type=pagev0;cat=lenov0;dc_lat=;dc_rdid=;tag_for_child_directed_treatment=;ord=' + a + '?" width="1" height="1" frameborder="0" style="display:none"></iframe>');
    </script>
    <noscript>
        <iframe src="https://4276718.fls.doubleclick.net/activityi;src=4276718;type=pagev0;cat=lenov0;dc_lat=;dc_rdid=;tag_for_child_directed_treatment=;ord=1?" width="1" height="1" frameborder="0" style="display:none"></iframe>
    </noscript>
    <!-- End of DoubleClick Floodlight Tag: Please do not remove -->

    <!-- Google Tag Manager -->
    <noscript><iframe src="//www.googletagmanager.com/ns.html?id=GTM-NBV9T9"
                      height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
    <script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
            new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
            j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
            '//www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
    })(window,document,'script','dataLayer','GTM-NBV9T9');</script>
    <!-- End Google Tag Manager -->

'''
    footer: ''
