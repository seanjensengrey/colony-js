var a;
print("Let's do somethng cool here.");
a = function(args) {
  var x, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = args.length; _i < _len; _i++) {
    x = args[_i];
    _results.push(print(x));
  }
  return _results;
};
a([5, 6, 7]);
