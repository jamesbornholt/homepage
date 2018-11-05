var z3_sweep = {
  "width": 500,
  "height": 300,
  "layer": [{
    "data": {
      "values": [
        {"proc": "A7",  "type": "Apple", "date": "2013-09-10", "speedup": "1.0"},
        {"proc": "A8",  "type": "Apple", "date": "2014-09-09", "speedup": "1.3783"},
        {"proc": "A9",  "type": "Apple", "date": "2015-09-09", "speedup": "2.3924"},
        {"proc": "A10", "type": "Apple", "date": "2016-09-07", "speedup": "2.7301"},
        {"proc": "A11", "type": "Apple", "date": "2017-09-12", "speedup": "3.5482"},
        {"proc": "A12", "type": "Apple", "date": "2018-09-12", "speedup": "4.5532"},
        {"proc": "i7-6700K", "type": "Intel", "date": "2015-08-05", "speedup": "4.5200"},
        {"proc": "i7-7700K", "type": "Intel", "date": "2017-01-03", "speedup": "4.9696"},
      ]
    },
    "layer": [{
      "mark": {
        "type": "line",
        "point": true
      }
    }, {
      "mark": {
        "type": "text",
        "align": "left",
        "baseline": "top",
        "dx": 4
      },
      "encoding": {
        "text": {"field": "proc", "type": "ordinal"}
      }
    }],
    "encoding": {
      "x": {
        "field": "date",
        "type": "temporal",
        "title": "Release Date",
        "axis": {
          "tickCount": 6
        }
      },
      "y": {
        "field": "speedup",
        "type": "quantitative",
        "title": "Speedup over A7",
        "scale": {
          "type": "log",
          "nice": false,
          "domain": [1, 6]
        }
      },
      "color": {
        "field": "type",
        "type": "nominal",
        "legend": {
          "title": null
        },
        "scale": {"range": ["#e41a1c", "#377eb8"]}
      }
    }
  }],
  "config": {
    "autosize": {
      "type": "fit",
      "contains": "padding"
    },
    "axis": {
      "labelFont": "Carlito",
      "labelFontSize": 14,
      "titleFont": "Carlito",
      "titleFontSize": 14
    },
    "legend": {
      "labelFont": "Carlito",
      "labelFontSize": 14
    },
    "text": {
      "font": "Carlito",
      "fontSize": 14,
    }
  }
};