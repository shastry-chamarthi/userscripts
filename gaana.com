// ==UserScript==
// @name            Gaana Dark Auto-Enable & Auto-Play with clean UI - noads / nonsense links
// @description     Auto-enables Gaana Dark theme. Works only on gaana.com
// @author          sathya - autoplay is forged - navchandar
// @version         1.7
// @grant           none
// @match           *://*.gaana.com/*
// @run-at          document-start
// @icon            https://css375.gaanacdn.com/images/favicon.ico
// @license         MIT
// @require         http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js
// @grant           GM_addStyle
// ==/UserScript==

function readCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for (var i = 0; i < ca.length; i++) {
    var c = ca[i];
    while (c.charAt(0) == ' ') {
      c = c.substring(1, c.length);
    }
    if (c.indexOf(nameEQ) === 0) {
      return c.substring(nameEQ.length, c.length);
    }
  }
  return null;
}

function createCookie(name, value, days) {
  var expires = ""
  if (days) {
    var date = new Date();
    date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
    expires = "; expires=" + date.toGMTString();
  }
  else {
    expires = "";
  }
  document.cookie = name + "=" + value + expires + "; domain='gaana.com'; path=/";
}

function eraseCookie(name) {
  createCookie(name, "", -1);
}

// Make theme black
createCookie('hd_marker', true, 100);
createCookie('themecolor_v1', 'black', 100);
createCookie('themedetect1', 1, 100);

// Play HD songs
createCookie('songquality', 'HD', 100);

// Removes ADs hopefully.
eraseCookie('globalAdsCounterThreeMin');
eraseCookie('globalAdsCounterTwoMin');
eraseCookie('globalAdsCounterTwoMinBg');
createCookie('globalAdsCounterThreeMin', 0, 100);
createCookie('globalAdsCounterTwoMin', 0, 100);
createCookie('globalAdsCounterTwoMinBg', 0, 100);

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
async function sleepFunc() {
  await sleep(3000);
}

//CLicks the Play All Button
setTimeout(function () {
  sleepFunc();
  document.querySelector('#p-list-play_all').click()
}, 3000)

/*--- waitForKeyElements():  A utility function, for Greasemonkey scripts,
    that detects and handles AJAXed content.

    Usage example:

        waitForKeyElements (
            "div.comments"
            , commentCallbackFunction
        );

        //--- Page-specific function to do what we want when the node is found.
        function commentCallbackFunction (jNode) {
            jNode.text ("This comment changed by waitForKeyElements().");
        }

    IMPORTANT: This function requires your script to have loaded jQuery.
*/
function waitForKeyElements(selectorTxt, actionFunction, bWaitOnce, iframeSelector) {
  var targetNodes, btargetsFound;
  if (typeof iframeSelector == "undefined")
    targetNodes = $(selectorTxt);
  else
    targetNodes = $(iframeSelector).contents()
    .find(selectorTxt);

  if (targetNodes && targetNodes.length > 0) {
    btargetsFound = true;
    /*--- Found target node(s).  Go through each and act if they
        are new.
    */
    targetNodes.each(function () {
      var jThis = $(this);
      var alreadyFound = jThis.data('alreadyFound') || false;

      if (!alreadyFound) {
        //--- Call the payload function.
        var cancelFound = actionFunction(jThis);
        if (cancelFound)
          btargetsFound = false;
        else
          jThis.data('alreadyFound', true);
      }
    });
  }
  else {
    btargetsFound = false;
  }

  //--- Get the timer-control variable for this selector.
  var controlObj = waitForKeyElements.controlObj || {};
  var controlKey = selectorTxt.replace(/[^\w]/g, "_");
  var timeControl = controlObj[controlKey];

  //--- Now set or clear the timer as appropriate.
  if (btargetsFound && bWaitOnce && timeControl) {
    //--- The only condition where we need to clear the timer.
    clearInterval(timeControl);
    delete controlObj[controlKey]
  }
  else {
    //--- Set a timer, if needed.
    if (!timeControl) {
      timeControl = setInterval(function () {
        waitForKeyElements(selectorTxt, actionFunction, bWaitOnce, iframeSelector);
      }, 300);
      controlObj[controlKey] = timeControl;
    }
  }
  waitForKeyElements.controlObj = controlObj;
}

function addCustomSearchResult(jNode) {
  //CLicks the Play All Button
  setTimeout(function () {
    sleepFunc();
    document.querySelector('#p-list-play_all').click()
  }, 1500)
}


// CLick the button everytime the page reloads.
waitForKeyElements("#p-list-play_all", addCustomSearchResult);

jQuery(document).ready(function(){
    var styles = " picture, iframe, header, #popup, .ads-section, footer, .adunit, #smsbanner, .overlay  { display: none !important; visibility:hidden !important; position: absolute !important; z-index: -99; top: -999999em !important; left: -99999em !important; width: 0  !important; height: 0  !important; }";
    styles += " .main { padding: 10px !important; }, ..innercontainer { top: 0 !important; }";
    jQuery('<style type="text/css" />').html(styles).appendTo($('body'));
});

