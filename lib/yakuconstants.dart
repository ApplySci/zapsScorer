///
///

// ---------------------------------------------
// Never use Ctrl-Alt-L to reformat this file!
// ---------------------------------------------

import 'utils.dart';

const int PANTHEON_RIICHI = 33;
const int PANTHEON_PINFU = 8;
const int PANTHEON_CHITOITSU = 31;
const int PANTHEON_TSUMO = 36;
const int HAND_IS_CLOSED = 99;

const List<int> YAKU_BUTTON_ORDER = [
  PANTHEON_RIICHI, 35, PANTHEON_TSUMO, 34,
  -1, -2, -3, 13,
  PANTHEON_PINFU, 23,PANTHEON_CHITOITSU,9,
  11, 3, 4, 5,
  1, 12, 27, 28,
  24, 25, 18, 2,
  37, 41, 42, 38,
  10, 43, 7, 32,
  26, 21, 30, 22,
  29, 6, 39, 40,
  19, 20, PAO_FLAG,
];
const Map<int, Map<String, dynamic>> YAKU_DETAILS = {
  -3: {'romaji': 'uradora', 'score': 0, 'riichi': true},
  -2: {'romaji': 'kandora', 'score': 0},
  -1: {'romaji': 'riichi dora', 'score': 0},
  1: {'romaji': 'Toitoi', 'score': 2},
  2: {'romaji': 'Honroutou', 'score': 2},
  3: {'romaji': 'Sanankou', 'score': 2},
  4: {'romaji': 'Sanshoku dokou', 'score': 2},
  5: {'romaji': 'Sankantsu', 'score': 2},
  6: {'romaji': 'Suukantsu', 'score': 1013},
  7: {'romaji': 'Suuankou', 'score': 1013, 'open': false},
  PANTHEON_PINFU: {'romaji': 'Pinfu', 'score': 1, 'open': false},
  9: {'romaji': 'Iippeiko', 'score': 1, 'open': false},
  10: {'romaji': 'Ryanpeikou', 'score': 3, 'open': false},
  11: {'romaji': 'Sanshoku', 'score': 2, 'open': -1},
  12: {'romaji': 'Ikkitsuukan', 'score': 2, 'open': -1},
  13: {'romaji': 'Yakuhai', 'score': 0},
  18: {'romaji': 'Shousangen', 'score': 2},
  19: {'romaji': 'Daisangen', 'score': 1013},
  20: {'romaji': 'Shousuushi', 'score': 1013},
  21: {'romaji': 'Daisuushi', 'score': 1013},
  22: {'romaji': 'Tsuuiisou', 'score': 1013},
  23: {'romaji': 'Tanyao', 'score': 1},
  24: {'romaji': 'Chanta', 'score': 2, 'open': -1},
  25: {'romaji': 'Junchan', 'score': 3, 'open': -1},
  26: {'romaji': 'Chinroutou', 'score': 1013},
  27: {'romaji': 'Honitsu', 'score': 3, 'open': -1},
  28: {'romaji': 'Chinitsu', 'score': 6, 'open': -1},
  29: {'romaji': 'Chuuren Potou', 'score': 1013, 'open': false},
  30: {'romaji': 'Ryuuiisou', 'score': 1013},
  PANTHEON_CHITOITSU: {'romaji': 'Chiitoitsu', 'score': 2, 'open': false},
  32: {'romaji': 'Kokushi Musou', 'score': 1013, 'open': false},
  PANTHEON_RIICHI: {'romaji': 'Riichi', 'score': 1, 'riichi': true},
  34: {'romaji': 'Double riichi', 'score': 1, 'riichi': true},
  35: {'romaji': 'Ippatsu', 'score': 1, 'riichi': true},
  PANTHEON_TSUMO: {'romaji': 'Menzen Tsumo', 'score': 1, 'open': false},
  37: {'romaji': 'Haitei', 'score': 1},
  38: {'romaji': 'Rinshan Kaihou', 'score': 1},
  39: {'romaji': 'Tenhou', 'score': 1013, 'open': false},
  40: {'romaji': 'Chihou', 'score': 1013, 'open': false},
  41: {'romaji': 'Houtei', 'score': 1},
  42: {'romaji': 'Chankan', 'score': 1},
  43: {'romaji': 'Renhou', 'score': 5, 'open': false},
  PAO_FLAG: {'romaji': 'Pao', 'score': 1},
};

// use symmetry.py to check that the below map is symmetric

const Map<int, List<int>> INCOMPATIBLE_YAKU = {
  PANTHEON_RIICHI: [],
  -3: [6, 7, 19, 20, 21, 22, 26, 29, 30, 32, 39, 40, 43, PAO_FLAG,],
  -2: [6, 7, 19, 20, 21, 22, 26, 29, 30, 32, 39, 40, 43, PAO_FLAG,],
  -1: [6, 7, 19, 20, 21, 22, 26, 29, 30, 32, 39, 40, PAO_FLAG,],
  1: [6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 19, 20, 21, 22, 24, 25, 26, 29, 30, PANTHEON_CHITOITSU, 32, PANTHEON_TSUMO, 39, 40, 43, PAO_FLAG,],
  2: [6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 19, 20, 21, 22, 23, 24, 25, 26, 28, 29, 30, 32, PANTHEON_TSUMO, 39, 40, 43, PAO_FLAG,],
  3: [6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 19, 20, 21, 22, 26, 29, 30, PANTHEON_CHITOITSU, 32, 39, 40, 43, PAO_FLAG,],
  4: [6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 18, 19, 20, 21, 22, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 39, 40, 43, PAO_FLAG,],
  5: [6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 19, 20, 21, 22, 26, 29, 30, PANTHEON_CHITOITSU, 32, 39, 40, 43, PAO_FLAG,],
  6: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 39, 40, 41, 42, 43, PAO_FLAG,],
  7: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 39, 40, 41, 42, 43, PAO_FLAG,],
  PANTHEON_PINFU: [1, 2, 3, 4, 5, 6, 7, 13, 18, 19, 20, 21, 22, 26, 29, 30, PANTHEON_CHITOITSU, 32, 38, 39, 40, 43, PAO_FLAG,],
  9: [1, 2, 3, 4, 5, 6, 7, 10, 19, 20, 21, 22, 26, 29, 30, PANTHEON_CHITOITSU, 32, 39, 40, 43, PAO_FLAG,],
  10: [1, 2, 3, 4, 5, 6, 7, 9, 11, 12, 13, 18, 19, 20, 21, 22, 26, 29, 30, PANTHEON_CHITOITSU, 32, 38, 39, 40, 43, PAO_FLAG,],
  11: [1, 2, 3, 4, 5, 6, 7, 10, 12, 18, 18, 19, 20, 21, 22, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 39, 40, 43, PAO_FLAG,],
  12: [1, 2, 3, 4, 5, 6, 7, 10, 11, 18, 19, 20, 21, 22, 23, 24, 25, 26, 29, 30, PANTHEON_CHITOITSU, 32, 39, 40, 43, PAO_FLAG,],
  13: [6, 7, PANTHEON_PINFU, 10, 19, 20, 21, 22, 23, 25, 26, 28, 29, 30, PANTHEON_CHITOITSU, 32, 39, 40, 43, PAO_FLAG,],
  18: [4, 6, 7, PANTHEON_PINFU, 10, 11, 12, 19, 20, 21, 22, 23, 25, 26, 28, 28, 29, 30, PANTHEON_CHITOITSU, 32, 39, 40, 43, PAO_FLAG,],
  19: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 39, 40, 41, 42, 43,],
  20: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 39, 40, 41, 42, 43,],
  21: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 39, 40, 41, 42, 43, PAO_FLAG,],
  22: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 21, 23, 24, 25, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 39, 40, 41, 42, 43, PAO_FLAG,],
  23: [2, 6, 7, 12, 13, 18, 19, 20, 21, 22, 24, 25, 26, 27, 29, 30, 32, 39, 40, 43, PAO_FLAG,],
  24: [1, 2, 6, 7, 12, 19, 20, 21, 22, 23, 25, 26, 28, 29, 30, PANTHEON_CHITOITSU, 32, 39, 40, 43, PAO_FLAG,],
  25: [1, 2, 6, 7, 12, 13, 18, 19, 20, 21, 22, 23, 24, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 39, 40, 43, PAO_FLAG,],
  26: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 39, 40, 41, 42, 43, PAO_FLAG,],
  27: [4, 6, 7, 11, 19, 20, 21, 22, 23, 25, 26, 28, 29, 30, 32, 39, 40, 43, PAO_FLAG,],
  28: [2, 4, 6, 7, 11, 13, 18, 19, 20, 21, 22, 24, 25, 26, 27, 29, 30, 32, 39, 40, 43, PAO_FLAG,],
  29: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 30, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 39, 40, 41, 42, 43, PAO_FLAG,],
  30: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 39, 40, 41, 42, 43, PAO_FLAG,],
  PANTHEON_CHITOITSU: [1, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 24, 25, 26, 29, 30, 32, 38, 39, 40, 43, PAO_FLAG,],
  32: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 34, 35, 37, 38, 39, 40, 41, 42, 43, PAO_FLAG,],
  34: [6, 7, 19, 20, 21, 22, 26, 29, 30, 32, 39, 40, 43, PAO_FLAG,],
  35: [6, 7, 19, 20, 21, 22, 26, 29, 30, 32, 39, 40, 43, PAO_FLAG,],
  PANTHEON_TSUMO: [1, 2, 41, 43,],
  37: [6, 7, 19, 20, 21, 22, 26, 29, 30, 32, 38, 39, 40, 41, 42, 43, PAO_FLAG,],
  38: [6, 7, PANTHEON_PINFU, 10, 19, 20, 21, 22, 26, 29, 30, PANTHEON_CHITOITSU, 32, 37, 37, 37, 39, 40, 41, 42, 43, PAO_FLAG,],
  39: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 40, 41, 42, 43, PAO_FLAG,],
  40: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 39, 41, 42, 43, PAO_FLAG,],
  41: [6, 7, 19, 20, 21, 22, 26, 29, 30, 32, PANTHEON_TSUMO, 37, 38, 39, 40, 42, 43, PAO_FLAG,],
  42: [6, 7, 19, 20, 21, 22, 26, 29, 30, 32, 37, 38, 39, 40, 41, 43, PAO_FLAG,],
  43: [-11, -3, -2, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 34, 35, PANTHEON_TSUMO, 37, 38, 39, 40, 41, 42, PAO_FLAG,],
  PAO_FLAG: [-11, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, PANTHEON_PINFU, 9, 10, 11, 12, 13, 18, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, PANTHEON_CHITOITSU, 32, 34, 35, 37, 38, 39, 40, 41, 42, 43,],
};
