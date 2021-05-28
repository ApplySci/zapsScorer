$(() {

const YAKU_DETAILS = {
  '-3': {'name': 'uradora', 'score': 0},
  '-2': {'name': 'kandora', 'score': 0},
  '-1': {'name': 'riichi dora', 'score': 0},
  '1': {'name': 'Toitoi', 'score': 2},
  '2': {'name': 'Honroutou', 'score': 2},
  '3': {'name': 'Sanankou', 'score': 2},
  '4': {'name': 'Sanshoku dokou', 'score': 2},
  '5': {'name': 'Sankantsu', 'score': 2},
  '6': {'name': 'Suukantsu', 'score': 1013},
  '7': {'name': 'Suuankou', 'score': 1013},
  '8': {'name': 'Pinfu', 'score': 1},
  '9': {'name': 'Iippeiko', 'score': 1},
  '10': {'name': 'Ryanpeikou', 'score': 3},
  '11': {'name': 'Sanshoku', 'score': 2, 'open': -1},
  '12': {'name': 'Ikkitsuukan', 'score': 2, 'open': -1},
  '13': {'name': 'Yakuhai', 'score': 0},
  '18': {'name': 'Shousangen', 'score': 2},
  '19': {'name': 'Daisangen', 'score': 1013},
  '20': {'name': 'Shousuushi', 'score': 1013},
  '21': {'name': 'Daisuushi', 'score': 1013},
  '22': {'name': 'Tsuuiisou', 'score': 1013},
  '23': {'name': 'Tanyao', 'score': 1},
  '24': {'name': 'Chanta', 'score': 2, 'open': -1},
  '25': {'name': 'Junchan', 'score': 3, 'open': -1},
  '26': {'name': 'Chinroutou', 'score': 1013},
  '27': {'name': 'Honitsu', 'score': 3, 'open': -1},
  '28': {'name': 'Chinitsu', 'score': 6, 'open': -1},
  '29': {'name': 'Chuuren Potou', 'score': 1013},
  '30': {'name': 'Ryuuiisou', 'score': 1013},
  '31': {'name': 'Chiitoitsu', 'score': 2},
  '32': {'name': 'Kokushi Musou', 'score': 1013},
  '33': {'name': 'Riichi', 'score': 1},
  '34': {'name': 'Double riichi', 'score': 1},
  '35': {'name': 'Ippatsu', 'score': 1},
  '36': {'name': 'Menzen Tsumo', 'score': 1},
  '37': {'name': 'Haitei', 'score': 1},
  '38': {'name': 'Rinshan Kaihou', 'score': 1},
  '39': {'name': 'Tenhou', 'score': 1013},
  '40': {'name': 'Chihou', 'score': 1013},
  '41': {'name': 'Houtei', 'score': 1},
  '42': {'name': 'Chankan', 'score': 1},
  '43': {'name': 'Renhou', 'score': 5},
  '99': {'name': 'Closed', 'score': -1},
  '8888': {'name': 'Pao', 'score': 1},
};
const seats=['b', 'r', 't', 'l'];

var lastHand = -1;
stream.onmessage = function(e) {
    console.log(e.data);
    var json=JSON.parse(e.data);
     for (let i=0;i<4;i++) {
         $('#' + seats[i] + 'score').text = json.scores[i];
     }
     $('#right').text(json.scoresheet);
   
};
    
});