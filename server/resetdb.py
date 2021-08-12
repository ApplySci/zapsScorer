from mjserver.models import Player, Game, PlayersGames, Season, SeasonsPlayers
from mjserver import db

from datetime import datetime, timedelta

def create_players():
    p1 = Player(name='groucho', pin=1234)
    p1.create_token()
    p2 = Player(name='harpo', pin=2345)
    p3 = Player(name='chico', pin=3456)
    p4 = Player(name='zeppo', pin=4567)
    p5 = Player(name='gummo', pin=5678)
    db.session.add(p1)
    db.session.add(p2)
    db.session.add(p3)
    db.session.add(p4)
    db.session.add(p5)
    db.session.commit()

def create_user():
    p1 = Player(name='a', pin='0000', )
    p1.create_token()
    p1.set_password('b')
    db.session.add(p1)
    db.session.commit()

def create_season():
    dt = datetime.utcnow()
    dt = dt.replace(hour=6, minute=0, second=0, microsecond=0)
    s1 = Season(name='test season',
                start_date=dt,
                ranking=1.5,
                country='ie',
                end_date=dt + timedelta(days=90),
                note='This is a long note attached to a tournament \n with line breaks'
                )
    db.session.add(s1)
    db.session.commit()

def create_games():
    g1 = Game(description='Game 1',
              started=datetime.utcnow() - timedelta(hours=25),
              season_id=1,
              is_active=False,
              )
    g2 = Game(description='Game 2',
              started=datetime.utcnow(),
              is_active=False,
              )
    db.session.add(g1)
    db.session.add(g2)
    db.session.commit()

def assign():

    a = Player.query.get(1)
    b = Game.query.get('1')
    pg1 = PlayersGames(score=-200, place=4, player=a, game=b)
    sg1 = SeasonsPlayers(season_id=1, player=a, place=2, score=-200)

    rel2 = PlayersGames(score=-100, place=3)
    a = Player.query.get(2)
    rel2.player = a
    rel2.game = b

    rel3 = PlayersGames(score= 300, place=2)
    a = Player.query.get(3)
    rel3.player = a
    rel3.game = b

    rel4 = PlayersGames(score= 400, place=1)
    a = Player.query.get(4)
    rel4.player = a
    rel4.game = b

    b = Game.query.get('2')
    rel5 = PlayersGames(score=200, place=4)
    rel5.player = a
    rel5.game = b

    a = Player.query.get(5)
    rel6 = PlayersGames(score=-100, place=3)
    rel6.player = a
    rel6.game = b

    a = Player.query.get(1)
    rel7 = PlayersGames(score= 300, place=2)
    rel7.player = a
    rel7.game = b

    a = Player.query.get(2)
    rel8 = PlayersGames(score= -400, place=1)
    rel8.player = a
    rel8.game = b

    db.session.commit()

if __name__ == "__main__":
    # execute only if run as a script
    create_players()
    create_user()
    create_season()
    create_games()
    assign()