const html = @"<!doctype html>
 
<html lang=""en"">
<head>
  <meta charset=""utf-8"" />
  <title>Neopixel Color Selector</title>
  <link rel=""stylesheet"" href=""https://code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css"" />
  <link href=""//d2c5utp5fpfikz.cloudfront.net/2_3_1/css/bootstrap.min.css"" rel=""stylesheet"">
  <link href=""//d2c5utp5fpfikz.cloudfront.net/2_3_1/css/bootstrap-responsive.min.css"" rel=""stylesheet"">
  <script src=""https://code.jquery.com/jquery-1.9.1.js""></script>
  <script src=""https://code.jquery.com/ui/1.10.3/jquery-ui.js""></script>
  <script src=""http://d2c5utp5fpfikz.cloudfront.net/2_3_1/js/bootstrap.min.js""></script>
  <style>
  #red, #green, #blue {
    float: left;
    clear: left;
    width: 300px;
    margin: 15px;
  }
  #swatch {
    width: 120px;
    height: 100px;
    margin-top: 18px;
    margin-left: 350px;
    background-image: none;
  }
  #red .ui-slider-range { background: #ef2929; }
  #red .ui-slider-handle { border-color: #ef2929; }
  #green .ui-slider-range { background: #8ae234; }
  #green .ui-slider-handle { border-color: #8ae234; }
  #blue .ui-slider-range { background: #729fcf; }
  #blue .ui-slider-handle { border-color: #729fcf; }
  </style>
  <script>
    function sendToImp(value){
        if (window.XMLHttpRequest) {devInfoReq=new XMLHttpRequest();}
        else {devInfoReq=new ActiveXObject(""Microsoft.XMLHTTP"");}
        try {
            devInfoReq.open('POST', document.URL, false);
            devInfoReq.send(value);
        } catch (err) {
            console.log('Error parsing device info from imp');
        }
    }
  function hexFromRGB(r, g, b) {
    var hex = [
      r.toString( 16 ),
      g.toString( 16 ),
      b.toString( 16 )
    ];
    $.each( hex, function( nr, val ) {
      if ( val.length === 1 ) {
        hex[ nr ] = ""0"" + val;
      }
    });
    return hex.join( """" ).toUpperCase();
  }
  function refreshSwatch() {
    var red = $( ""#red"" ).slider( ""value"" ),
      green = $( ""#green"" ).slider( ""value"" ),
      blue = $( ""#blue"" ).slider( ""value"" ),
      hex = hexFromRGB( red, green, blue );
    $( ""#swatch"" ).css( ""background-color"", ""#"" + hex );
    sendToImp('{""red"":""' + red +'"",""blue"":""' + blue + '"",""green"":""' + green + '""}');
  }
  $(function() {
    $( ""#red, #green, #blue"" ).slider({
      orientation: ""horizontal"",
      range: ""min"",
      max: 255,
      value: 127,
      
      stop: refreshSwatch
    });
    $( ""#red"" ).slider( ""value"", 255 );
    $( ""#green"" ).slider( ""value"", 255 );
    $( ""#blue"" ).slider( ""value"", 255 );
  });
  </script>
</head>
<body class=""ui-widget-content"" style=""border: 0;"">
 

<div class='well' style='max-width: 340px; margin: 0 auto 10px; height:220px; font-size:24px;'>
<p class=""ui-state-default ui-corner-all ui-helper-clearfix"" style=""padding: 4px; text-align:center;"">
  Neopixel Ring Color Picker
</p>
 
<div id=""red""></div>
<div id=""green""></div>
<div id=""blue""></div>
 
</div>
 
</body>
</html>";
function logTable(t, i = 0) {
    local indentString = "";
    for(local x = 0; x < i; x++) indentString += ".";
    
    foreach(k, v in t) {
        if (typeof(v) == "table" || typeof(v) == "array") {
            local par = "[]";
            if (typeof(v) == "table") par = "{}";
            
            server.log(indentString + k + ": " + par[0].tochar());
            logTable(v, i+4);
            server.log(par[1].tochar());
        } 
        else { 
            server.log(indentString + k + ": " + v);
        }
    }
}

http.onrequest(function(request,res){
    if (request.body == "") { //No HTTP body, respond with HTML
        res.send(200, html);
    }
    else
    {
        try {
            local json_req = http.jsondecode(request.body);
            local json_resp = "OK";
            if("red" in json_req && "green" in json_req && "blue" in json_req){
                server.log("RGB: " + request.body);
                device.send("rgb", json_req);
                resp.send(200, json_resp);
            } else {
                server.log("Unrecognized Body: "+request.body);
            }
        }    
        catch (ex) {
            res.send(500, "Internal Server Error: " + ex);  
        }
    }
});

class TwitterStream {
    // OAuth
    consumerKey = null;
    consumerSecret = null;
    accessToken = null;
    accessSecret = null;
    
    // URLs
    streamUrl = "https://stream.twitter.com/1.1/";
    
    // Streaming
    streamingRequest = null;
    
    constructor (_consumerKey, _consumerSecret, _accessToken, _accessSecret) {
        this.consumerKey = _consumerKey;
        this.consumerSecret = _consumerSecret;
        this.accessToken = _accessToken;
        this.accessSecret = _accessSecret;
    }
    
    function encode(str) {
        return http.urlencode({ s = str }).slice(2);
    }

    function oAuth1Request(postUrl, headers, post) {
        local time = time();
        local nonce = time;
 
        local parm_string = http.urlencode({ oauth_consumer_key = consumerKey });
        parm_string += "&" + http.urlencode({ oauth_nonce = nonce });
        parm_string += "&" + http.urlencode({ oauth_signature_method = "HMAC-SHA1" });
        parm_string += "&" + http.urlencode({ oauth_timestamp = time });
        parm_string += "&" + http.urlencode({ oauth_token = accessToken });
        parm_string += "&" + http.urlencode({ oauth_version = "1.0" });
        parm_string += "&" + http.urlencode(post);
        
        local signature_string = "POST&" + encode(postUrl) + "&" + encode(parm_string);
        
        local key = format("%s&%s", encode(consumerSecret), encode(accessSecret));
        local sha1 = encode(http.base64encode(http.hash.hmacsha1(signature_string, key)));
        
        local auth_header = "oauth_consumer_key=\""+consumerKey+"\", ";
        auth_header += "oauth_nonce=\""+nonce+"\", ";
        auth_header += "oauth_signature=\""+sha1+"\", ";
        auth_header += "oauth_signature_method=\""+"HMAC-SHA1"+"\", ";
        auth_header += "oauth_timestamp=\""+time+"\", ";
        auth_header += "oauth_token=\""+accessToken+"\", ";
        auth_header += "oauth_version=\"1.0\"";
        
        local headers = { 
            "Authorization": "OAuth " + auth_header
        };
        
        local url = postUrl + "?" + http.urlencode(post);
        local request = http.post(url, headers, "");
        return request;
    }
    
    function looksLikeATweet(data) {
        return (
            "created_at" in data &&
            "id" in data &&
            "text" in data &&
            "user" in data
        );
    }
    
    function defaultErrorHandler(errors) {
        foreach(error in errors) {
            server.log("ERROR " + error.code + ": " + error.message);
        }
    }
    
    function Stream(searchTerms, autoReconnect, onTweet, onError = null) {
		server.log("Opening stream for: " + searchTerms);
        // Set default error handler
        if (onError == null) onError = defaultErrorHandler.bindenv(this);
        
        local method = "statuses/filter.json"
        local headers = { };
        local post = { track = searchTerms };
        local request = oAuth1Request(streamUrl + method, headers, post);
        
        
        this.streamingRequest = request.sendasync(
            
            function(resp) {
                // connection timeout
                server.log("Stream Closed (" + resp.statuscode + ": " + resp.body +")");
                // if we have autoreconnect set
                if (resp.statuscode == 28 && autoReconnect) {
                    Stream(searchTerms, autoReconnect, onTweet, onError);
                }
            }.bindenv(this),
            
            function(body) {
                 try {
                    if (body.len() == 2) {
                        server.log("Twitter Keep Alive");
                        return;
                    }
                    
                    local data = http.jsondecode(body);
                    // if it's an error
                    if ("errors" in data) {
                        server.log("Got an error");
                        onError(data.errors);
                        return;
                    } 
                    else {
                        if (looksLikeATweet(data)) {
                            onTweet(data);
                            return;
                        }
                    }
                } catch(ex) {
                    // if an error occured, invoke error handler
                    onError([{ message = "Squirrel Error - " + ex, code = -1 }]);
                }
            }.bindenv(this)
        
        );
    }
}
 
_CONSUMER_KEY <- "YOUR CONSUMER KEY";
_CONSUMER_SECRET <- "YOUR CONSUMER SECRET";
_ACCESS_TOKEN <- "YOUR ACCESS TOKEN";
_ACCESS_SECRET <- "YOUR ACCESS SECRET";
_SEARCH_TERM <- "Neopixel";

color_red <- {"red":"25","green":"0","blue":"0"};
color_green <- {"red":"0","green":"25","blue":"0"};
color_blue <- {"red":"0","green":"0","blue":"25"};
color_white <- {"red":"25","green":"25","blue":"25"};
color_orange <- {"red":"25","green":"12","blue":"0"};
color_yellow <- {"red":"25","green":"25","blue":"0"};
color_black <- {"red":"0","green":"0","blue":"0"};
color_fire <- {"red":"25","green":"6","blue":"0"};
function onTweet(tweet) {
	//server.log("Got a tweet!");
	//server.log("User: " + tweet.user.screen_name);
	server.log("Text: " + tweet.text);
	//logTable(tweet);
    parseTweet(tweet.text);
}
function parseTweet(tweettext) {
	local tweetParsed = split(tweettext, " ");
    foreach(string in tweetParsed) {
        if (string == "#Red"){ device.send("rgb", color_red); }
        else if (string == "#Green") { device.send("rgb", color_green); }
        else if (string == "#Blue") { device.send("rgb", color_blue); }
        else if (string == "#White") { device.send("rgb", color_white); }
        else if (string == "#Orange") { device.send("rgb", color_orange); }
        else if (string == "#Yellow") { device.send("rgb", color_yellow); }
        else if (string == "#Black") { device.send("rgb", color_black); }
        else if (string == "#Fire") { device.send("rgb", color_fire);}
    }
}
stream <- TwitterStream(_CONSUMER_KEY, _CONSUMER_SECRET, _ACCESS_TOKEN, _ACCESS_SECRET);
stream.Stream(_SEARCH_TERM, true, onTweet);
