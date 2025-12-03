import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:web_query/js.dart';
import 'package:web_query/query.dart';
import 'package:web_query/ui.dart';

import 'log.dart';

void main() {
  logInit();
  configureJsExecutor(FlutterJsExecutor());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DataQueryWidget Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageData = useState<PageData?>(null);
    final isLoading = useState(false);
    final urlController = useTextEditingController(
      text: 'https://example.com',
    );

    Future<void> loadUrl(String url) async {
      if (url.isEmpty) return;

      isLoading.value = true;
      try {
        final response = await http.get(Uri.parse(url));
        pageData.value = PageData.auto(url, response.body);
        if (response.statusCode == 200) {
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load: ${response.statusCode}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    // Load sample data on startup
    useEffect(() {
      loadSampleData(pageData);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DataQueryWidget Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // URL input section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: 'Enter URL to fetch',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    onSubmitted: loadUrl,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isLoading.value
                      ? null
                      : () => loadUrl(urlController.text),
                  icon: isLoading.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: const Text('Fetch'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => loadSampleData(pageData),
                  icon: const Icon(Icons.code),
                  label: const Text('Load Sample'),
                ),
              ],
            ),
          ),
          // DataQueryWidget
          Expanded(
            child: pageData.value == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Load a URL or sample data to start querying',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const _QueryExamplesCard(),
                      ],
                    ),
                  )
                : DataQueryWidget(
                    pageData: pageData.value,
                    title: 'Query Data',
                  ),
          ),
        ],
      ),
    );
  }

  void loadSampleData(ValueNotifier<PageData?> pageData) {
    const sampleHtml = r'''<HTML>
    <HEAD>
        <title>START-460</title>
        <meta name="description" content="START-460">
        <meta name="keywords" content="START-460">
        <meta name="robots" content="nofollow, noindex">
        <link rel="stylesheet" href="/css/main.css">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
        <meta name="theme-color" content="#FFF">
        <script src="/js/jquery.min.js"></script>
        <script src="/js/xupload.js"></script>
        <script src="/js/jquery.cookie.js"></script>
        <!-- Google tag (gtag.js) -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=G-2TL7NH453R"></script>
        <script>
            window.dataLayer = window.dataLayer || [];
            function gtag() {
                dataLayer.push(arguments);
            }
            gtag('js', new Date());

            gtag('config', 'G-2TL7NH453R');
        </script>
        <!-- Google tag (gtag.js) -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=G-E2BG6CPV2J"></script>
        <script>
            window.dataLayer = window.dataLayer || [];
            function gtag() {
                dataLayer.push(arguments);
            }
            gtag('js', new Date());

            gtag('config', 'G-E2BG6CPV2J');
        </script>
        <!-- Yandex.Metrika counter -->
        <script type="text/javascript">
            (function(m, e, t, r, i, k, a) {
                m[i] = m[i] || function() {
                    (m[i].a = m[i].a || []).push(arguments)
                }
                ;
                m[i].l = 1 * new Date();
                for (var j = 0; j < document.scripts.length; j++) {
                    if (document.scripts[j].src === r) {
                        return;
                    }
                }
                k = e.createElement(t),
                a = e.getElementsByTagName(t)[0],
                k.async = 1,
                k.src = r,
                a.parentNode.insertBefore(k, a)
            }
            )(window, document, "script", "https://mc.yandex.ru/metrika/tag.js", "ym");

            ym(102872415, "init", {
                clickmap: true,
                trackLinks: true,
                accurateTrackBounce: true,
                webvisor: true
            });
        </script>
        <noscript>
            <div>
                <img src="https://mc.yandex.ru/watch/102872415" style="position:absolute; left:-9999px;" alt=""/>
            </div>
        </noscript>
        <!-- /Yandex.Metrika counter -->
        <script>
            $.cookie('file_id', '65812407', {
                expires: 10
            });
            $.cookie('aff', '78', {
                expires: 10
            });
            $.cookie('ref_url', 'jav.guru', {
                expires: 10
            });

            var pickDirect = function(idads, link) {
                var d = document.createElement('script');
                d.textContent = `var  __directlink${idads}={
								init:function() {
									var link = '${link}';
									var div = document.createElement('div');
									var h = window.innerHeight, w = window.innerWidth;
									div.setAttribute('style', 'position:fixed;inset:0px;z-index:2147483647;background:black;opacity:0.01;height:'+h+'px;width:'+w+'px;cursor:pointer');
									div.onclick = function () {
										this.parentNode.removeChild(this);
										window.open(link, '_blank');
									};
									document.body.appendChild(div);
								}
							};
							__directlink${idads}.init();`;
                document.body.appendChild(d);
            }
        </script>
    </HEAD>
    <BODY topmargin=0 leftmargin=0 style="background:transparent;">
        <div style="position:relative;">
            <div id="adbd" class="overdiv">
                <div>
                    Please turn off AdBlock to view this video!
					
                    <p>
                        <a href="#" onclick="location.reload();" class="btn">Reload Page</a>
                    </p>
                </div>
            </div>
            <script type='text/javascript' src='/player/jw8/jwplayer.js?v=7'></script>
            <script type="text/javascript">
                jwplayer.key = "ITWMv7t88JGzI0xPwW8I0+LveiXX9SWbfdmt0ArUSyc=";
            </script>
            <script src="/js/localstorage-slim.js"></script>
            <div id='vplayer' style="width:100%;height:100%;text-align:center;">
                <img src="https://pixoraa.cc/sevnlrpx3cqb_xt.jpg" style="width:100%;height:100%;">
            </div>
            <style>
                .jw-icon-display, .jw-text, .jw-button-color, .jw-time-tip {
                    color: #c1c1d7 !important;
                }

                .jw-time-tip span {
                    background: #c1c1d7 !important;
                    color: #fff !important;
                }

                .jw-featured, .jw-rightclick {
                    display: none !important;
                }

                div.jw-icon-rewind {
                    display: none;
                    xdisplay: inherit;
                }

                .jw-display-icon-container .jw-icon-inline {
                    display: none;
                }
            </style>
        </div>
        <script type='text/javascript'>
            eval(function(p, a, c, k, e, d) {
                while (c--)
                    if (k[c])
                        p = p.replace(new RegExp('\\b' + c.toString(a) + '\\b','g'), k[c]);
                return p
            }('j 5z=[{"1p":"2b","y":"q://ad.6n.1a/6m?6l=6k&6j=6i","1n":0,"1q":0},{"1p":"2b","y":"q://df.de.1a/dd/dc","1n":0,"1q":60},{"1q":66,"1n":0,"1p":"2b","y":"q://ad.6n.1a/6m?6l=6k&6j=6i"},{"1n":0,"1q":db,"y":"q://6h.1a/t/9/6g/6f/6e/6d.2r","1p":"2b"},{"y":"q://6h.1a/t/9/6g/6f/6e/6d.2r","1p":"2b","1q":da,"1n":0}];j o={"1e":"q://6c.d9.d8/33/1e/6b/6a/69,l,n,h,.68/3v.d7","1g":"/d6/-d5/d4/d3/1w/3v.67","1d":"q://6c.d2.1a/1d/6b/6a/69,l,n,h,.68/3v.67?t=d1&s=d0&e=cz&f=1w&cy=33&i=0.4&cx=cw&cv=33&cu=33&ct=cs"};1f("cr").cq({cp:"1",co:[{1l:o.1g||o.1e||o.1d,3d:"3c"}],cn:"q://64.cc/cm.63",cl:"3u%",ck:"3u%",cj:"ci",ch:"65.cg",cf:\'ce\',cd:{cb:{2z:"#31",ca:"#31"},c9:{c8:"#31"},c7:{2z:"#31"}},c6:"1k",p:[{1l:"/2q?2p=c5&1r=65&c4=q://64.cc/c3.63",c2:"c1"}],4a:{c0:1,bz:\'#61\',by:\'#61\',bx:"bw",bv:0,bu:\'3u\',},"bt":{"bs":"5y","br":"bq"},\'bp\':{"bo":"bn","bm":"bl","bk":"bj"},bi:"bh-bg",bf:1k,be:"bd",bc:"q://bb.1a",ba:{},b9:1k,49:[0.25,0.5,0.75,1,1.25,1.5,2]});j 3q,3t;j b8=0,b7=0,b6=0;j a=1f();j 2t=0,1x=0,b5=0,16=0;$.b4({b3:{\'b2-b1\':\'b0-az\'}});a.18(\'1q\',k(x){b(5>0&&x.1i>=5&&3t!=1){3t=1;$(\'1v.ay\').ax(\'aw\')}j 3s=0;5z.av(w=>{b(w.1q<=x.1i&&w.1n==0){b(w.1p==\'5y\'){b(w.y.5w(\'q://\')){a.5x(w.y)}1j{j 2y=3r 5v().5u(w.y,"2z/2o");w.y="2a:au/at;as,"+ar(aq(ap(2y.5t.2w)));a.5x(w.y)}}1j b(w.1p==\'ao\'){an(3s,w.y)}1j{j 1o=w.y.am();j 1b=29.5p(\'1b\');b(1o.5w(\'q://\')){1b.5o=1o;1b.al=1k}1j{j 2y=3r 5v().5u(1o,"2z/2o");1o=2y.5t.2w;j 2x=1o.2x(/<1b[^>]*>([\\s\\ak]*?)<\\/1b>/i);b(2x){1b.2w=2x[1]}1j{1b.2w=1o}}29.5g.5f(1b)}w.1n=1}3s++});b(x.1i>=16+5||x.1i<16){16=x.1i;2h.aj(\'2f\',ai.ah(16),{ag:60*60*24*7})}b(x.af){2u=x.1i-2t;b(2u>5)2u=1;1x+=2u}2t=x.1i;3h.3g(1x);b(1x>=60){$.ae(\'q://ac.ab.1a/2q\',{2p:\'aa\',3o:\'1w-3n-3m-3k-3j\',a9:a8(1x),a7:1w,a6:\'3p\'},k(){},"a5");1x=0}});a.18(\'22\',k(x){2t=x.1i});a.18(\'4f\',k(x){5r(x)});a.18(\'a4\',k(){$(\'1v.5q\').a3();2h.a2(\'2f\')});a.18(\'a1\',k(x){});k a0(1y,5s,2k){j 2s=3r 9z();2s.9y(2s.9x()+(2k*9w));29.9v=1y+"="+5s+"; 9u="+2s.9t()+"; 9s=.9r.1a; 26=/; 9q=9p; 9o"}k 5r(x){$(\'1v.5q\').3f();$(\'#9n\').3f();b(3q)2d;3q=1;3i=0;9m 28=29.5p(\'1b\');28.5o=\'q://9l.9k.1a/2r/9j/9i.2r\';28.9h=()=>{$.2g(\'/2q?2p=5n&5m=3p&3o=1w-3n-3m-3k-3j&5l=1&5k=5j.5i&3i=1&1g=1\',k(2a){$(\'#5h\').2o(2a)})};28.9g=()=>{$.2g(\'/2q?2p=5n&5m=3p&3o=1w-3n-3m-3k-3j&5l=1&5k=5j.5i&3i=0&1g=1\',k(2a){$(\'#5h\').2o(2a)})};29.5g.5f(28);j 16=2h.2g(\'2f\');b(16>0){1f().22(16)}}k 9f(){j p=a.35(5e);3h.3g(p);b(p.1r>1){3y(i=0;i<p.1r;i++){b(p[i].1y==5e){3h.3g(\'!!=\'+i);a.3w(i)}}}}a.18(\'4e\',k(){1f().3b(\'<15 4z="4y://4x.4w.4v/4u/15" 4t="g-15-1m g-15-1m-9e" 4s="0 0 2m 2m" 4r="1s"><26 d="m 25.9d,57.9c v 9b.3 c 0.9a,2.99 2.98,4.97 4.8,4.8 h 62.7 v -19.3 h -48.2 v -96.4 5d 94.93 v 19.3 c 0,5.3 3.6,7.2 8,4.3 l 41.8,-27.9 c 2.92,-1.91 4.90,-5.8z 2.7,-8 -0.8y,-1.8x -1.8w,-2.8v -2.7,-2.7 l -41.8,-27.9 c -4.4,-2.9 -8,-1 -8,4.3 v 19.3 5d 30.8u c -2.8t,0.8s -4.8r,2.8q -4.9,4.9 z m 8p.8o,73.8n c -3.5c,-6.5b -10.5a,-10.59 -17.7,-10.6 -7.58,0.56 -13.55,4.54 -17.7,10.6 -8.2n,14.53 -8.2n,32.52 0,46.3 3.5c,6.5b 10.5a,10.59 17.7,10.6 7.58,-0.56 13.55,-4.54 17.7,-10.6 8.2n,-14.53 8.2n,-32.52 0,-46.3 z m -17.7,47.2 c -7.8,0 -14.4,-11 -14.4,-24.1 0,-13.1 6.6,-24.1 14.4,-24.1 7.8,0 14.4,11 14.4,24.1 0,13.1 -6.5,24.1 -14.4,24.1 z m -47.8m,9.8l v -51 l -4.8,4.8 -6.8,-6.8 13,-12.8k c 3.8j,-3.8i 8.8h,-0.8g 8.2,3.4 v 62.8f z"></26></15>\',"8e 10 2k",k(){1f().22(1f().4l()+10)},"50");$("1v[4k=50]").4i().4h(\'.g-1m-2i\');1f().3b(\'<15 4z="4y://4x.4w.4v/4u/15" 4t="g-15-1m g-15-1m-2i" 4s="0 0 2m 2m" 4r="1s"><26 d="8d.2,8c.8b.1h,21.1h,0,0,0-17.7-10.6,21.1h,21.1h,0,0,0-17.7,10.6,44.2l,44.2l,0,0,0,0,46.3,21.1h,21.1h,0,0,0,17.7,10.6,21.1h,21.1h,0,0,0,17.7-10.6,44.2l,44.2l,0,0,0,0-46.8a-17.7,47.2c-7.8,0-14.4-11-14.4-24.89.6-24.1,14.4-24.1,14.4,11,14.4,24.88.4,4q.87,95.5,4q.86-43.4,9.7v-85-4.8,4.8-6.8-6.8,13-84.8,4.8,0,0,1,8.2,3.83.7l-9.6-.82-81.80.7z.4p,4.4p,0,0,1-4.8,4.7y.6v-19.7x.2v-96.7w.7u.7t,5.3-3.6,7.2-8,4.3l-41.8-27.7s.4o,6.4o,0,0,1-2.7-8,5.4n,5.4n,0,0,1,2.7-2.7r.8-27.7q.4-2.9,8-1,8,4.7p.7o.7n.4m,4.4m,0,0,1,7m.1,57.7k"></26></15>\',"7j 10 2k",k(){j 2j=1f().4l()-10;b(2j<0)2j=0;1f().22(2j)},"4j");$("1v[4k=4j]").4i().4h(\'.g-1m-2i\');$("1v.g-1m-2i").3f()});a.18(\'7i\',k(1z){j 20=a.4d().1l;j 4g=a.7h().p||[];j 23=7g;b(20===o.1g){23=o.1e||o.1d}1j b(20===o.1e){23=o.1d}b(23){a.3e([{1l:23,p:4g}]);a.4f();a.7f(\'7e\',k(){j 16=2h.2g(\'2f\');b(16){a.22(16)}});2d 1k}});a.18(\'4e\',k(){j 20=a.4d().1l;b(o.1g&&20===o.1g){7d(o.1g,{7c:\'7b\'}).7a(4c=>{b(!4c.79&&(o.1e||o.1d)){a.4b();a.3e([{1l:o.1e||o.1d,3d:"3c"}]);}}).78(()=>{b(o.1e||o.1d){a.4b();a.3e([{1l:o.1e||o.1d,3d:"3c"}]);}})}});a.18("1c",k(1z){j p=a.35();b(p.1r<2)2d;$(\'.g-u-77-76\').74(k(){$(\'#g-u-r-1c\').38(\'g-u-r-2e\');$(\'.g-r-1c\').1u(\'1t-39\',\'1s\')});a.3b("/72/71.15","70 6z",k(){$(\'.g-45\').6y(\'g-u-42\');$(\'.g-u-4a, .g-u-49\').1u(\'1t-3a\',\'1s\');b($(\'.g-45\').6x(\'g-u-42\')){$(\'.g-r-1c\').1u(\'1t-3a\',\'1k\');$(\'.g-r-1c\').1u(\'1t-39\',\'1k\');$(\'.g-u-r-6w\').38(\'g-u-r-2e\');$(\'.g-u-r-1c\').6u(\'g-u-r-2e\')}1j{$(\'.g-r-1c\').1u(\'1t-3a\',\'1s\');$(\'.g-r-1c\').1u(\'1t-39\',\'1s\');$(\'.g-u-r-1c\').38(\'g-u-r-2e\')}},"6t");a.18("6s",k(1z){37.6r(\'36\',1z.p[1z.6q].1y)});b(37.40(\'36\')){6p("3z(37.40(\'36\'));",6o)}});j 34;k 3z(3x){j p=a.35();b(p.1r>1){3y(i=0;i<p.1r;i++){b(p[i].1y==3x){b(i==34){2d}34=i;a.3w(i)}}}}', 36, 484, '||||||||||player|if|||||jw|||var|function||||links|tracks|https|submenu|||settings||item||link|||||||svg|lastt||on||com|script|audioTracks|hls2|hls3|jwplayer|hls4|589|position|else|true|file|icon|loaded|code|xtype|time|length|false|aria|attr|div|65812407|tott|name|event|currentFile||seek|newFile|||path||ggima|document|data|popunder||return|active|ttsevnlrpx3cqb|get|ls|rewind|tt|sec|769|240|60009|html|op|dl|js|date|prevt|dt||textContent|match|doc|text||c1c1d7||qCsH3mKRD1SG2|current_audio|getAudioTracks|default_audio|localStorage|removeClass|expanded|checked|addButton|hls|type|load|hide|log|console|adb|c3224cee02840764701368d53759cc33|1764737823||154|222|hash|sevnlrpx3cqb|vvplay|new|itads|vvad|100|master|setCurrentAudioTrack|audio_name|for|audio_set|getItem||open|||controls||||playbackRates|captions|stop|res|getPlaylistItem|ready|play|currentTracks|insertAfter|detach|ff00|button|getPosition|974|887|013|867|178|focusable|viewBox|class|2000|org|w3|www|http|xmlns|ff11||06475|23525|29374|97928|30317||31579|29683|38421|30626|72072|H|track_name|appendChild|body|fviews|guru|jav|referer|embed|file_code|view|src|createElement|video_ad|doPlay|value|documentElement|parseFromString|DOMParser|startsWith|playAd|vast|uas||FFFFFF||jpg|pixoraa|8328||m3u8|urlset|sevnlrpx3cqb_|13162|01|Y36m66IkUlk1|7845f7e5|2078197|meow4|fret|diagramjawlineunhappy|COMMA_SEPARATED_KEYWORDS|kw|01KAH367W8QT59D1BNSWJT4GGQ|zone|adraw|twinrdengine|300|setTimeout|currentTrack|setItem|audioTrackChanged|dualSound|addClass||quality|hasClass|toggleClass|Track|Audio|dualy|images||mousedown||buttons|topbar|catch|ok|then|HEAD|method|fetch|firstFrame|once|null|getConfig|error|Rewind|778Z||214|2A4|3H209|3v19|9c4|7l41|9a6|3c0|1v19||4H79|3h48|8H146|3a4|2v125|130|1Zm162|4v62|13a4|51l|278Zm|278|1S103|1s6|3Zm|078a21|131|M113|Forward|69999|88605|21053|03598|02543|99999|72863|77056|04577|422413|163|210431|860275|03972|689569|893957|124979|52502|174985|57502|04363|13843|480087|93574|99396|160|||76396|164107|63589|03604|125|778|993957|rewind2|set_audio_track|onload|onerror|ima3|sdkloader|googleapis|imasdk|const|over_player_msg|Secure|None|SameSite|javclan|domain|toGMTString|expires|cookie|1000|getTime|setTime|Date|createCookieSec|pause|remove|show|complete|jsonp|file_real|file_id|parseInt|ss|view4|vectorrab|logs||post|viewable|ttl|round|Math|set|S|async|trim|pickDirect|direct|encodeURIComponent|unescape|btoa|base64|xml|application|forEach|slow|fadeIn|video_ad_fadein|cache|no|Cache|Content|headers|ajaxSetup|v2done|pop3done|vastdone2|vastdone1|playbackRateControls|cast|streamhg|aboutlink|StreamHG|abouttext|displaytitle|460|START|title|480p|1930|720p|1043|1080p|2378|qualityLabels|insecure|vpaidmode|client|advertising|fontOpacity|backgroundOpacity|Tahoma|fontFamily|backgroundColor|color|userFontScale|thumbnails|kind|sevnlrpx3cqb0000|url|get_slides|androidhls|menus|progress|timeslider|icons|controlbar||skin|auto|preload|06|duration|uniform|stretching|height|width|sevnlrpx3cqb_xt|image|sources|debug|setup|vplayer|4771|asn|p2|p1|500|sp|srv|129600|1764737824|VlnTEype2JGs0HMlODovjWBaSa9_xVU7XBKHfvcGSsc|premilkyway|1764781024|kjhhiuahiuhgihdf|UOxM80fXiGkg0tWXJ2NpA|stream|txt|shop|stellarcrestcreative|3600|450|132416|rGq0E09pKJub|wreckedulpan|nv'.split('|')))
        </script>
        <!--Function Adult-->
        <script src="/assets/jquery/function.js?type=adult&u=78&v=1.2"></script>
        <script>
            !function() {
                try {
                    var t = ["sandbox", "hasAttribute", "frameElement", "data", "indexOf", "href", "domain", "", "plugins", "undefined", "namedItem", "Chrome PDF Viewer", "object", "createElement", "onerror", "type", "application/pdf", "setAttribute", "style", "visibility:hidden;width:0;height:0;position:absolute;top:-99px;", "data:application/pdf;base64,JVBERi0xLg0KdHJhaWxlcjw8L1Jvb3Q8PC9QYWdlczw8L0tpZHNbPDwvTWVkaWFCb3hbMCAwIDMgM10+Pl0+Pj4+Pj4=", "appendChild", "body", "removeChild", "parentElement", "/blocked.html?referer=", "substring", "referrer"];
                    function e() {
                        try {
                            if (config.ampallow) {
                                var e = window.location.ancestorOrigins;
                                if (e[e.length - 1].endsWith("ampproject.org"))
                                    return
                            }
                        } catch (n) {}
                        setTimeout(function() {
                            location[t[5]] = "/blocked.html"
                        }, 900)
                    }
                    !function e(n) {
                        try {
                            if (window[t[2]][t[1]](t[0])) {
                                n();
                                return
                            }
                        } catch (r) {}
                        if (0 != location[t[5]][t[4]](t[3]) && document[t[6]] == t[7]) {
                            n();
                            return
                        }
                        if (typeof navigator[t[8]] != t[9] && typeof navigator[t[8]][t[10]] != t[9] && null != navigator[t[8]][t[10]](t[11])) {
                            var i = document[t[13]](t[12]);
                            i[t[14]] = function() {
                                n()
                            }
                            ,
                            i[t[17]](t[15], t[16]),
                            i[t[17]](t[18], t[19]),
                            i[t[17]](t[3], t[20]),
                            document[t[22]][t[21]](i),
                            setTimeout(function() {
                                i[t[24]][t[23]](i)
                            }, 150)
                        }
                    }(e),
                    function t() {
                        try {
                            document.domain = document.domain
                        } catch (e) {
                            try {
                                if (-1 != e.toString().toLowerCase().indexOf("sandbox"))
                                    return !0
                            } catch (n) {}
                        }
                        return !1
                    }() && e(),
                    function t() {
                        if (window.parent === window)
                            return !1;
                        try {
                            var e = window.frameElement
                        } catch (n) {
                            e = null
                        }
                        return null === e ? "" === document.domain && "data:" !== location.protocol : e.hasAttribute("sandbox")
                    }() && e()
                } catch (n) {}
            }();
        </script>
        <style>
            @media screen and (max-width: 480px) {
                .jw-flag-audio-player .jw-button-container .jw-icon, .jwplayer:not(.jw-flag-small-player) .jw-button-container .jw-icon {
                    flex: auto;
                }
            }
</style </BODY><script defer src="https://static.cloudflareinsights.com/beacon.min.js/vcd15cbe7772f49c399c6a5babf22c1241717689176015"integrity="sha512-ZpsOmlRQV6y907TI0dKBHq9Md29nnaEIPlkf84rnaERnq6zvWvPUqr2ft8M1aS28oN72PdrCzSjY4U6VaAw1EQ=="data-cf-beacon='{"version":"2024.11.0","token":"97cb4a761bdc412f8b2f1fa88394af7f","r":1,"server_timing":{"name":{"cfCacheStatus":true,"cfEdge":true,"cfExtPri":true,"cfL4":true,"cfOrigin":true,"cfSpeedBrain":true},"location_startswith":null}}'crossorigin="anonymous"></script></HTML>
''';

    pageData.value = PageData(
      'https://example.com/sample',
      sampleHtml,
    );
  }
}

class _QueryExamplesCard extends StatelessWidget {
  const _QueryExamplesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Query Examples',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildExample('HTML Queries', [
              'h1@text - Get h1 text content',
              '.intro@text - Get intro paragraph',
              '*li@text - Get all list items',
              'a@href - Get first link href',
              '.metadata/*span@text - Get all spans in metadata',
            ]),
            const SizedBox(height: 16),
            _buildExample('JSON Queries', [
              'json:title - Get title',
              'json:items/* - Get all items',
              'json:items/0/name - Get first item name',
              'json:metadata/author - Get author',
            ]),
            const SizedBox(height: 16),
            _buildExample('With Transforms', [
              'h1@text?transform=upper - Uppercase title',
              'a@href?regexp=/https:\\/\\/([^\\/]+).*\$/\$1/ - Extract domain',
              '*li@text?filter=JSON - Filter items containing "JSON"',
            ]),
            const SizedBox(height: 16),
            _buildExample('URL Queries', [
              'url: - Get full URL',
              'url:host - Get hostname',
              'url:?page=2 - Modify query param',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildExample(String title, List<String> examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...examples.map((example) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '• $example',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            )),
      ],
    );
  }
}
