$(window).on("load", function () {
    $('#main-slider').flexslider({
        animation: "fade",
        slideshow: true,
        slideshowSpeed: 6000,
        animationSpeed: 500,
        pauseOnHover: true,
        pauseOnAction: false,
        controlNav: false,
        directionNav: false,
        touch: true
    });
});