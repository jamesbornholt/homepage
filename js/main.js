$(function() {
    // fix up the mailto links
    $("#contact span").remove();
    $("#contact").attr("href", "mailto:" + $.trim($("#contact").text()));

    // hack to highlight rosette code
    var keywords = ["define-symbolic", "solve", "assert"];
    for (var i = 0; i < keywords.length; i++)
        $(".n:contains('" + keywords[i] + "')").removeClass("n").addClass("k");
});