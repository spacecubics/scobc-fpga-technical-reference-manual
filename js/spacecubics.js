function collapse_toc_elements_on_click(nav_li_a) {
    /* When an `a' element in the TOC is clicked, its parent `li'
     * element's active attribute is toggled.  This causes the element
     * to toggle between minimized and maximized states.  The active
     * attribute is documented in bootstrap.
     * https://getbootstrap.com/docs/4.0/components/navbar/#nav
     */
    $(nav_li_a).parent().toggleClass("active");
}

$(document).ready(function() {
    /* Bootstrap ScrollSpy requires it */
    $('#text-table-of-contents ul').addClass('nav');

    /* When the document is loaded and ready, bind the function
     * `collapse_toc_elements_on_click' to the `a' elements in the
     * table of contents.
     */
    $("#text-table-of-contents a").click(function() {
        collapse_toc_elements_on_click(this);
    });

    /* Spy on the body and update the TOC */
    $('body').scrollspy({
        target: '#text-table-of-contents'
    });

});
