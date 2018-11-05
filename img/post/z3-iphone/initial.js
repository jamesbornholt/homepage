var z3_initial = {
  "width": 500,
  "height": 120,
  "data": {
    "values": [
      {"System": "iPhone XS", "time": "21.277"},
      {"System": "i7-7700K",  "time": "23.900"}
    ]
  },
  "mark": "bar",
  "encoding": {
    "x": {"field": "time", "type": "quantitative", "title": "Time (secs)"},
    "y": {"field": "System", "type": "nominal", "sort": "ascending", "title": "System", "axis": {"title": null}},
    "color": {"field": "System", "scale": {"range": ["#377eb8", "#e41a1c"]}, "legend": null}
  },
  "config": {
    "autosize": {
      "type": "fit",
      "contains": "padding"
    },
    "axis": {
      "labelFontSize": 14,
      "titleFontSize": 14
    },
    "legend": {
      "labelFontSize": 14
    },
    "text": {
      "fontSize": 14
    }
  }
};