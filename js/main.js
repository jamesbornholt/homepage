function enableMailto() {
    var contact = document.getElementById("contact");
    if (contact !== null) {
        var spans = contact.querySelectorAll("span");
        for (var i = 0; i < spans.length; i++) {
            spans[i].parentNode.removeChild(spans[i]);
        }
        var txt = contact.innerText.trim();
        contact.setAttribute("href", "mailto:" + txt);
    }
}

function highlightRosette() {
    // hack to highlight rosette code
    var keywords = ["define-symbolic", "solve", "assert", "synthesize"];
    var elts = document.querySelectorAll(".nf");
    for (var i = 0; i < elts.length; i++) {
        var txt = elts[i].innerHTML;
        for (var j = 0; j < keywords.length; j++) {
            if (txt.indexOf(keywords[j]) > -1) {
                elts[i].classList.remove("nf");
                elts[i].classList.add("k");
                break;
            }
        }
    }
}

function init() {
    enableMailto();
    highlightRosette();
}

document.addEventListener("DOMContentLoaded", init);
