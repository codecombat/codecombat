# Analytics tags added to main.html when on il.codecombat.com

module.exports =
    header: '''
    <script type="text/javascript">
      // Helper.World for Israel pilot
      if(features.israel) {
        var _hw = _hw || {};
        _hw.protocol = window.location.protocol == 'file:' ? 'http:' : window.location.protocol;
        _hw.source = _hw.protocol + '//helper.world/';
        _hw.skillID = 'c4ea28a95ed34412870afa07f98c6dfb';
        _hw.clientID = 'unknown';
        _hw.recording = false;
        (function() {
        var vmb = document.createElement('script');
        vmb.type = 'text/javascript';
        vmb.async = false; vmb.charset='utf-8';
        vmb.src = _hw.source + 'client.js';
        var s = document.getElementsByTagName('script')[0];
        s.parentNode.insertBefore(vmb, s);
        })();
      }
    </script>

    <!-- Google Tag Manager -->
    <noscript><iframe src="//www.googletagmanager.com/ns.html?id=GTM-KDGMWZ5"
                      height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
    <script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
            new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
            j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
            '//www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
    })(window,document,'script','dataLayer','GTM-KDGMWZ5');</script>
    <!-- End Google Tag Manager -->

'''
    footer: ''
