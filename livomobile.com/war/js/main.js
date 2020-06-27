/*
Theme Name: Trype
Author: CREATEBRILLIANCE - Media & Consulting
Author URI: http://www.createbrilliance.com
Version: 1.2
*/


var Trype;

( function($) {"use strict";

Trype = window.Trype || {};

/****************************************************************************************************
 * NAV
 *
 *
 *
****************************************************************************************************/
Trype.nav= function(options){

	// add class after scrolling
	//don't do this on small devices
	

	$(window).resize(function(){
		scrollEffect();
	});
	
	function scrollEffect() {

			if(!($(window).width() > 768)){	
				if(!$(".navbar-fixed-top").hasClass("top-nav-collapse")){
					$(".navbar-fixed-top").addClass("top-nav-collapse");	
				}
			}else{
				if($(".navbar-fixed-top").hasClass("top-nav-collapse")){
					$(".navbar-fixed-top").removeClass("top-nav-collapse");	
				}
			}

			$(window).scroll(function() {
				if($(window).width() > 768){						
						if ($(".navbar").offset().top > 50) {
							$(".navbar-fixed-top").addClass("top-nav-collapse");
						} else {
							$(".navbar-fixed-top").removeClass("top-nav-collapse");					
						}
					}else{
						$(".navbar-fixed-top").addClass("top-nav-collapse");
					}		
			});

	};
	
	scrollEffect();

	if(options == "dropdown"){
		$('.navbar-nav .dropdown').onePageNav({
			currentClass : 'active-sub',
			changeHash : true,
			scrollSpeed : 750,
			scrollOffset : 0,
			scrollThreshold : 0.5,
			easing : 'easeOutExpo',
			filter : ':not(.ex)'
		});
	}else{
		$('.navbar-nav').onePageNav({
			currentClass : 'active',
			changeHash : true,
			scrollSpeed : 750,
			scrollOffset : 0,
			scrollThreshold : 0.5,
			easing : 'easeOutExpo',
			filter : ':not(.ex)'
		});
	};

};
/****************************************************************************************************
 * PRELOADER
 *
 *
 *
****************************************************************************************************/
Trype.preloader = function() {


		
		$(window).load(function() {
			$('#preloader').fadeOut(800, function() {
				$('body').css('overflow', 'visible');
			});
		});
			
};

/****************************************************************************************************
 * SUPERSLIDES
 *
 *
 *
****************************************************************************************************/
Trype.slider = function(selector, options){
	
	$(window).load(function() {			
		$(selector).superslides(options);
	});
	
};
	
/****************************************************************************************************
 * OWL CAROUSEL
 *
 *
 *
****************************************************************************************************/
Trype.owlCarousel = function (options){
	
	$.each(options, function(index,value) {
          
          if(value != null){
          	//if carousel has parameters 
         	$(index).owlCarousel(value);
          }else{
          	//if there are no parameters
          	$(index).owlCarousel();
          }
              
       });


		
};
/****************************************************************************************************
 * MAGNIFIC
 *
 *
 *
****************************************************************************************************/
Trype.magnific = function (options){
	
	$.each(options, function(index,value) {
          if(value != null){
          	//if carousel has parameters 
         	$(index).magnificPopup(value);
          }else{
          	//if there are no parameters
          	$(index).magnificPopup();
          }
              
       });


		
};
/****************************************************************************************************
 * TOOLTIP
 *
 *
 *
****************************************************************************************************/
Trype.tooltip = function(selector){
	$(selector).tooltip(); 
};

/****************************************************************************************************
 * SLIDE DOWN HEAD
 *
 *
 *
****************************************************************************************************/
Trype.slideDownHead = function(option){
	if(option){
		$(document).ready(function(){
			$(".pageHead").css({
				"top":"-500px",
				"opacity":"0"
			});
			$(".pageHead .hero h1, .pageHead .hero h3").css({
				"opacity":"0"
			});
		});
		$(window).load(function(){
			$(".pageHead").stop(true,true).delay(500).animate({"top":"0px", "opacity":"1"},500, "easeOutCubic", function(){
				$(".pageHead .hero h1").animate({"opacity":"1"},500, function(){
					$(".pageHead .hero h3").animate({"opacity":"1"},300);
				});
			});
		});
	}
};

/****************************************************************************************************
 * PARALLAX
 *
 *
 *
****************************************************************************************************/
Trype.parallax = function(option){
	
		if(option){
			if (!Modernizr.touch){
				var s = skrollr.init({
					mobileDeceleration: 1,
					constants: {
				
					},
					edgeStrategy: 'set',
					forceHeight: false,
					smoothScrolling: true,
					easing: {
						WTF: Math.random,
							inverted: function(p) {
							return 1-p;
							}
					}
				});
			} 	
		};	
};
/****************************************************************************************************
 * ANIMATED KNOBS
 *
 *
 *
****************************************************************************************************/
Trype.knobs = function(animated){
		
		if(animated == "animated"){
				if (!/Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent)) {
					// Triggering only when it is inside viewport
					$('.knob').waypoint(function() {
						// Triggering now
						var $this = $(this);
						var myVal = $this.attr("rel");
						$this.knob({
						});
						$({
							value : 0
						}).animate({
							value : myVal
						}, {
							duration : 1000,
							easing : 'swing',
							step : function() {
								$this.val(Math.ceil(this.value)).trigger('change');
							}
						})
					}, {
						triggerOnce : true,
						offset : function() {
							return $(window).height() - $(this).outerHeight();
						}
					});
				} else {
					$(".knob").each(function() {
						var $this = $(this);
						var myVal = $this.attr("rel");
						$(this).knob();
						$(this).val(myVal);
						$this.val(Math.ceil(myVal)).trigger('change');
					});	
		
				}
		
		};
		
};
/****************************************************************************************************
 * YOUTUBE VIDEO PLAYER
 *
 *
 *
****************************************************************************************************/
Trype.videoBgYT = function(selector,video){
//	if(!Modernizr.touch){
//		$(selector).tubular({videoId:video,wrapperZIndex: 9999,mute: false, repeat: false}); 	
//	}else{
//		$(".mobileonly").show();
//		$(selector).remove();
//	};

	$("#video-wrapper").tubular({videoId: "idiH8I7-RBM", mute: false, wrapperZIndex: 9999});
};
/****************************************************************************************************
 * Magnify (Magnifying Glass)
 *
 *
 *
****************************************************************************************************/
Trype.magnify = function(option, selector){
	
	if (option){
						
		$(document).ready(function(){
				var native_width = 0;
				var native_height = 0;
	
			//Now the mousemove function
			$(selector).mousemove(function(e){
				if(!native_width && !native_height)
				{
					var image_object = new Image();
					image_object.src = $(".small").attr("src");
					
					native_width = image_object.width;
					native_height = image_object.height;
				}
				else
				{
					var magnify_offset = $(this).offset();
					var mx = e.pageX - magnify_offset.left;
					var my = e.pageY - magnify_offset.top;
					
					if(mx < $(this).width() && my < $(this).height() && mx > 0 && my > 0)
					{
						$(".large").fadeIn(100);
					}
					else
					{
						$(".large").fadeOut(100);
					}
					if($(".large").is(":visible"))
					{
						var rx = Math.round(mx/$(".small").width()*native_width - $(".large").width()/2)*-1;
						var ry = Math.round(my/$(".small").height()*native_height - $(".large").height()/2)*-1;
						var bgp = rx + "px " + ry + "px";
						var px = mx - $(".large").width()/2;
						var py = my - $(".large").height()/2;
						$(".large").css({left: px, top: py, backgroundPosition: bgp});
					}
				}
			})
		})
	}
	

	
};

/****************************************************************************************************
 * header carousel
 *
 *
 *
****************************************************************************************************/
Trype.bootstrapCarousel = function (options){
	
		$.each(options, function(index,value) {
          
          if(value != null){
          	//if carousel has parameters 
         	$(index).carousel(value);
          }else{
          	//if there are no parameters
          	$(index).carousel();
          }
              
       });

};
/****************************************************************************************************
 * ANIMATED NUMBERS
 *
 *
 *
****************************************************************************************************/	
Trype.counter = function (selector){
	
	$(selector).waypoint(function() {

			$(selector).countTo({
			            from: 50,
			            to: 9732,
			            speed: 1000,
			            refreshInterval: 50,
			            onComplete: function(value) {
			            }
	        	});
	        	
	      });
	      
};
/****************************************************************************************************
 * FITVIDS
 *
 *
 *
****************************************************************************************************/	
Trype.fitVids = function (selector){	
	$(selector).fitVids();	      
};
/****************************************************************************************************
 *  SCROLLING ANIMATIONS
 *	
 *	takes data-animation, data-animation-delay as data attributes. Element needs to have class animation
 *
****************************************************************************************************/			
Trype.scrollAnim = function(option){	
		$(window).load(function() {
			if(option == "yes"){		
					//trigger css3 animations
					// Handle appear event for animated elements
					var wpOffset = 80;
					if (!/Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent)) {
						wpOffset = 100;

						$.fn.waypoint.defaults = {
							context : window,
							continuous : true,
							enabled : true,
							horizontal : false,
							offset : 0,
							triggerOnce : false
						};

						$('.animated').waypoint(function() {
							var elem = $(this);
							var animation = elem.data('animation');
							if (!elem.hasClass('visible') && elem.attr('data-animation') !== undefined) {
								if (elem.attr('data-animation-delay') !== undefined) {
									var timeout = elem.data('animation-delay');
									setTimeout(function() {
										elem.addClass(animation + " visible");
									}, timeout);
								} else {
									elem.addClass(elem.data('animation') + " visible");
								}
							}
						}, {
							offset : wpOffset + '%'
						});
					} else {
						//if mobile, don't do it just display elements
						$('.animated').each(function() {
							$(this).css("visibility", "visible");
						});
					}



				}else{
				//don't trigger css3 animation, but display elements
						$('.animated').each(function() {
							$(this).css("visibility", "visible");
						});
				}
		}); //window load
};
/****************************************************************************************************
 * HELPER
 *
 *
 *
****************************************************************************************************/
	if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) {

		$(".background-middle-full").removeClass("fixed");
	};



/****************************************************************************************************
 * GOOGLE MAPS INTEGRATION
 *
 *
 *
****************************************************************************************************/
Trype.map = function (options){


		var settings = $.extend({
            type		: 	"color",
            selector	: 	"map-container"
        }, options);
        

		var mapSelector = settings.selector;
		
		if (document.getElementById(mapSelector)) {
				var mapOptions = {
				location : $("#" + mapSelector).attr("data-location"),
				infoBoxText : $("#" + mapSelector).attr("data-text"),
				zoomLevel : $("#" + mapSelector).attr("data-zoom"),
				mapType : $("#" + mapSelector).attr("data-mapType"),
				
				};	
				initmap(mapSelector, mapOptions);
				
		}
		




		function initmap(selector, mapOptions) {

			var address = mapOptions.location;
			
			if(settings.type != "color"){
				//black and white
			var mapStyleOptions = [ { "stylers": [ { "featureType": "all" }, { "saturation": -100 }, { "weight": 0.2 }, { "gamma": 1.2 }, {"lightness": 30 } ] } ];

			}else{
				//color
				var mapStyleOptions = [{
				featureType : "all",
				elementType : "all"
				}]
			}

			var map = new google.maps.Map(document.getElementById(selector), {
				mapTypeId : google.maps.MapTypeId.mapType,
				scrollwheel : false,
				draggable : false,
				disableDefaultUI : true,
				zoom : parseInt(mapOptions.zoomLevel),
				styles :mapStyleOptions
			});

			//responsive center
			google.maps.event.addDomListener(window, "resize", function() {
				var center = map.getCenter();
				google.maps.event.trigger(map, "resize");
				map.setCenter(center);
			});

			var map_pin = "img/assets/map-marker.png";
			var geocoder = new google.maps.Geocoder();
			geocoder.geocode({
				'address' : address
			}, function(results, status) {
				if (status == google.maps.GeocoderStatus.OK) {
					var marker = new google.maps.Marker({
						position : results[0].geometry.location,
						map : map,
						icon : map_pin
					});

					map.setCenter(results[0].geometry.location);

					/*CREATE INFOBOX*/
					
					var boxText = document.createElement("div");
					boxText.innerHTML = "<div class='infoBox'>" + "<div class='content'>" + mapOptions.infoBoxText + "</div>" + "</div>";
					var myOptions1 = {
						content : boxText,
						disableAutoPan : false,
						pixelOffset : new google.maps.Size(30, 0),
						boxClass : 'map-box',
						alignBottom : true,
						pane : "floatPane"
					};
					var ib = new InfoBox(myOptions1);
					ib.open(map, marker);
					google.maps.event.addListener(marker, "click", function() {
						ib.open(map, marker);
					});

				}
			});
		}
		
		
};



/****************************************************************************************************
 * CONTACT FORM
 *
 *
 *
****************************************************************************************************/
Trype.contactForm = function (){


		$("#contact-submit").on('click touchstart', function(e) {
			e.preventDefault();
			$("#contact-submit").html("<i class='fa fa-cog fa-spin'></i> SENDING").prop('disabled', true);
			var $contact_form = $('#contact-form');
			var fields = $contact_form.serialize();
			$.ajax({
				type : "POST",
				url : "contact",
				data : fields,
				dataType : 'json',
				success : function(response) {
					if (response.status) {
						$('#contact-form input').val('');
						$('#contact-form textarea').val('');
					}
					$('#contact-form-response').empty().html(response.html);
					$("#contact-submit").html("<i class='fa fa-check'></i> SUBMIT").prop('disabled', false);
				}
			});
			return false;
		});
		
};

/****************************************************************************************************
 * NEWSLETTER FORM
 *
 *
 *
****************************************************************************************************/
Trype.newsletterForm = function (expand){
	
	if(expand == "expand"){
		$("#newsletter .expand-button").click(function(){
			if($(this).hasClass("expanded")){
				$(this).removeClass("fa-angle-double-up");
				$(this).addClass("fa-angle-double-down");
				$("#newsletter .expand").slideUp("slow", function(){
					$.scrollTo('#newsletter', 1000, {
						easing : 'easeOutExpo',
						axis : 'y',
						offset : -50
					});
				});
				$(this).removeClass("expanded");
			}else{
				$(this).removeClass("fa-angle-double-down");
				$(this).addClass("fa-angle-double-up");
				$("#newsletter .expand").slideDown("slow", function(){
					$.scrollTo('#newsletter #emailInputNewsletter', 1000, {
						easing : 'easeOutExpo',
						axis : 'y',
						offset : -50
						});
				});
				$(this).addClass("expanded");
			}
			
			
			
					
		});
	}else{
		$("#newsletter .expand").css("display","block");
	}
	
	/*
	 * Regular Newsletter Code
	 */
	$("#newsletter-submit").on('click touchstart', function(e) {
		e.preventDefault();
		$("#newsletter-submit").html("<i class='fa fa-cog fa-spin'></i> SENDING").prop('disabled', true);
		var $newsletter_form = $('#emailInputNewsletter');
		var fields = $newsletter_form.serialize();
		$.ajax({
			type : "POST",
			url : "newsletter",
			data : fields,
			dataType : 'json',
			success : function(response) {
				if (response.status) {
					$("#emailInputNewsletter").text('')
				}
				$("#newsletter-submit").html("<i class='fa fa-check'></i> SUBMIT").prop('disabled', false);
				$('#newsletter-form-response').empty().html(response.html);
			}
		});
		return false;
	}); 
};



 }(jQuery)); 