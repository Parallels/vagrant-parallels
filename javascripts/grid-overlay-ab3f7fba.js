/*
* Heads-Up Grid
* Simple HTML + CSS grid overlay for web design and development.
*
* Files: hugrid.css, hugrid.js, example.html
*
* Example and documentation at: http://bohemianalps.com/tools/grid
*
* Shurane, thanks for your help! https://github.com/shurane
*
* Copyright (c) 2011 Jason Simanek
*
* Version: 1.5 (09/03/2011)
* Requires: jQuery v1.6+
*
* Licensed under the GPL license:
*   http://www.gnu.org/licenses/gpl.html
*/
!function(i){function e(){i("#hugrid").remove(),i("#hugridRows").remove(),i("#hugridUX").remove()}window.hugrid={toggleState:function(){"on"==window.hugrid.state?window.hugrid.state="off":"off"==window.hugrid.state&&(window.hugrid.state="on")}},makehugrid=function(){e();var t=document.createElement("div");t.id="hugrid",leftDiv=document.createElement("div"),leftDiv.className="mline mlineL",t.appendChild(leftDiv);for(var d=0;d<columns-1;d++)colDiv=document.createElement("div"),colDiv.className="hugcol",t.appendChild(colDiv),lineLDiv=document.createElement("div"),lineLDiv.className="lineL",colDiv.appendChild(lineLDiv),lineRDiv=document.createElement("div"),lineRDiv.className="lineR",colDiv.appendChild(lineRDiv);if(rightDiv=document.createElement("div"),rightDiv.className="mline mlineR",t.appendChild(rightDiv),document.body.appendChild(t),0!==rowheight){pageheight=i(document.body).height();var n=document.createElement("div");n.id="hugridRows";for(var d=0;d<pageheight/rowheight;d++)rowDiv=document.createElement("div"),rowDiv.className="hugrow",n.appendChild(rowDiv),lineB=document.createElement("div"),lineB.className="lineB",rowDiv.appendChild(lineB);document.body.appendChild(n)}i("#hugrid").css("width",pagewidth+pageUnits),"number"==typeof window.pageleftmargin?(i("#hugrid").css("left",pageleftmargin+pageUnits),i("#hugrid").css("margin","0")):"number"==typeof window.pagerightmargin?(i("#hugrid").css("right",pagerightmargin+pageUnits),i("#hugrid").css("left","auto"),i("#hugrid").css("margin","0")):"%"===pageUnits?(i("#hugrid").css("left",(100-pagewidth)/2+pageUnits),i("#hugrid").css("margin-left","auto")):i("#hugrid").css("margin-left","-"+pagewidth/2+pageUnits),i("#hugrid div.hugcol").css("margin-left",columnwidth+colUnits),i("#hugrid div.hugcol").css("width",gutterwidth+colUnits),i("#hugridRows").css("margin-top",pagetopmargin+"px"),i("#hugridRows div.hugrow").css("margin-top",rowheight-1+"px");var g=document.createElement("div");g.id="hugridUX",document.body.appendChild(g),i("#hugridUX").append('<div id="hugridButtonBkgd"></div><button id="hugridButton"></button>'),i("#hugridButton").append('<span id="hugbuttonON">ON</span>'),i("#hugridButton").append('<span id="hugbuttonOFF" style="display:none;">OFF</span>'),i("#hugridButton").click(function(){i("#hugridButton").toggleClass("buttonisoff"),i("#hugrid").toggle(),i("#hugridRows").toggle(),i("#hugridButton span").toggle(),window.hugrid.toggleState()})},setgridonload=function(){"off"===gridonload?(i("#hugridButton").toggleClass("buttonisoff"),i("#hugrid").toggle(),i("#hugridRows").toggle(),i("#hugridButton span").toggle(),window.hugrid.state="off"):window.hugrid.state="on"},setgridonresize=function(){"off"===window.hugrid.state&&(i("#hugridButton").toggleClass("buttonisoff"),i("#hugrid").toggle(),i("#hugridRows").toggle(),i("#hugridButton span").toggle())}}(jQuery);