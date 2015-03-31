+++
date = "2014-10-28T13:52:51-07:00"
draft = false
title = "test"
layout = "page"
+++

hello world

{{ range .Site.Data.papers }}
    {{ . }}
{{ end }}