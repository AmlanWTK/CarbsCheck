/// Maps common food units to approximate gram values
/// These are estimation values used for nutrition calculation
/// NOT medical measurements

final Map<String, Map<String, double>> unitToGram = {
  'apple': {
    '1 medium apple': 182,
    '1 small apple': 149,
    '1 large apple': 223,
    '100 g': 100,
  },
  'banana': {
    '1 medium banana': 118,
    '1 small banana': 101,
    '1 large banana': 136,
    '100 g': 100,
  },
  'rice (cooked)': {
    '1 cup cooked': 158,
    '1 bowl': 200,
    '100 g': 100,
  },
  'bread': {
    '1 slice': 30,
    '2 slices': 60,
    '100 g': 100,
  },
  'chicken curry': {
    '1 piece': 120,
    '1 bowl': 250,
    '100 g': 100,
  },
};
