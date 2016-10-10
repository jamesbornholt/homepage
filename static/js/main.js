$(function() {
    // fix up the mailto links
    $("#contact span").remove();
    $("#contact").attr("href", "mailto:" + $.trim($("#contact").text()));

    // hack to highlight rosette code
    $(".n:contains('define-symbolic')").removeClass("n").addClass("k");
});