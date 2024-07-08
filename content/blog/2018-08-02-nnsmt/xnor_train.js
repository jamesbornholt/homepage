var xnor_train = {
  "width": 500,
  "data": {
    "values": [
      {"time": "30.66", "digit": "8", "accuracy": "0.356"},
      {"time": "97.55", "digit": "7", "accuracy": "0.584"},
      {"time": "112.59", "digit": "6", "accuracy": "0.42"},
      {"time": "127.38", "digit": "8", "accuracy": "0.552"},
      {"time": "128.7", "digit": "9", "accuracy": "0.476"},
      {"time": "236.39", "digit": "8", "accuracy": "0.644"},
      {"time": "258.12", "digit": "6", "accuracy": "0.604"},
      {"time": "268.38", "digit": "6", "accuracy": "0.608"},
      {"time": "427.99", "digit": "7", "accuracy": "0.612"},
      {"time": "431.95", "digit": "6", "accuracy": "0.6"},
      {"time": "435.72", "digit": "8", "accuracy": "0.644"},
      {"time": "497.02", "digit": "7", "accuracy": "0.68"},
      {"time": "557.49", "digit": "6", "accuracy": "0.592"},
      {"time": "559.34", "digit": "8", "accuracy": "0.636"},
      {"time": "712.83", "digit": "9", "accuracy": "0.484"},
      {"time": "834.33", "digit": "9", "accuracy": "0.568"},
      {"time": "915.02", "digit": "9", "accuracy": "0.532"},
      {"time": "969.06", "digit": "8", "accuracy": "0.688"},
      {"time": "978.93", "digit": "7", "accuracy": "0.74"},
      {"time": "1100.18", "digit": "7", "accuracy": "0.704"},
      {"time": "1123.04", "digit": "7", "accuracy": "0.76"},
      {"time": "1216.32", "digit": "6", "accuracy": "0.584"},
      {"time": "1351.15", "digit": "6", "accuracy": "0.648"},
      {"time": "1358.28", "digit": "8", "accuracy": "0.68"},
      {"time": "1460.01", "digit": "9", "accuracy": "0.636"},
      {"time": "1464.97", "digit": "9", "accuracy": "0.592"},
      {"time": "1946.14", "digit": "8", "accuracy": "0.664"},
      {"time": "2098.83", "digit": "7", "accuracy": "0.744"},
      {"time": "2205.53", "digit": "9", "accuracy": "0.608"},
      {"time": "3218.14", "digit": "8", "accuracy": "0.64"},
      {"time": "3342.14", "digit": "6", "accuracy": "0.62"},
      {"time": "3374.63", "digit": "9", "accuracy": "0.592"},
      {"time": "3428.31", "digit": "6", "accuracy": "0.668"},
      {"time": "4454.1", "digit": "6", "accuracy": "0.628"},
      {"time": "4478.51", "digit": "8", "accuracy": "0.652"},
      {"time": "4978.14", "digit": "8", "accuracy": "0.692"},
      {"time": "5343", "digit": "6", "accuracy": "0.636"},
      {"time": "6796.41", "digit": "9", "accuracy": "0.636"},
      {"time": "9199.68", "digit": "6", "accuracy": "0.652"}
    ]
  },
  "mark": {
    "type": "line",
    "point": true
  },
  "encoding": {
    "y": {"field": "accuracy", "type": "quantitative", "title": "Accuracy"},
    "x": {"field": "time", "type": "quantitative", "sort": "ascending", "title": "Training Time (s)"},
    "color": {"field": "digit", "type": "nominal", "title": "Digit"}
  },
  "config": {
    "autosize": {
      "type": "fit",
      "contains": "padding"
    }
  }
};