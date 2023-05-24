/*!	
* FitText.js 1.1
*
* Copyright 2011, Dave Rupert http://daverupert.com
* Released under the WTFPL license 
* http://sam.zoy.org/wtfpl/
*
* Date: Thu May 05 14:23:00 2011 -0600
*/
!function(n){n.fn.fitText=function(t,i){var e=t||1,o=n.extend({minFontSize:Number.NEGATIVE_INFINITY,maxFontSize:Number.POSITIVE_INFINITY},i);return this.each(function(){var t=n(this),i=function(){t.css("font-size",Math.max(Math.min(t.width()/(10*e),parseFloat(o.maxFontSize)),parseFloat(o.minFontSize)))};i(),n(window).on("resize",i)})}}(jQuery);