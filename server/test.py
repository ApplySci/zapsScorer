from mjserver.models import User, Game, UsersGames
from mjserver import db

def create_users():
    p1 = User(name='groucho', pin=1234)
    p1.create_token()
    p2 = User(name='harpo', pin=2345)
    p3 = User(name='chico', pin=3456)
    p4 = User(name='zeppo', pin=4567)
    p5 = User(name='gummo', pin=5678)
    db.session.add(p1)
    db.session.add(p2)
    db.session.add(p3)
    db.session.add(p4)
    db.session.add(p5)
    db.session.commit()

def create_games():
    g1 = Game(game_id='1', description='Game 1')
    g2 = Game(game_id='2', description='Game 2')
    db.session.add(g1)
    db.session.add(g2)
    db.session.commit()

def assign():

    rel1 = UsersGames(score=-200, place=4)
    a = User.query.get(1)
    b = Game.query.get('1')
    rel1.player = a
    rel1.game = b

    rel2 = UsersGames(score=-100, place=3)
    a = User.query.get(2)
    rel2.player = a
    rel2.game = b

    rel3 = UsersGames(score= 300, place=2)
    a = User.query.get(3)
    rel3.player = a
    rel3.game = b

    rel4 = UsersGames(score= 400, place=1)
    a = User.query.get(4)
    rel4.player = a
    rel4.game = b

    b = Game.query.get('2')
    rel5 = UsersGames(score=-2000, place=4)
    rel5.player = a
    rel5.game = b

    a = User.query.get(5)
    rel6 = UsersGames(score=-1000, place=3)
    rel6.player = a
    rel6.game = b

    a = User.query.get(1)
    rel7 = UsersGames(score= 3000, place=2)
    rel7.player = a
    rel7.game = b

    a = User.query.get(2)
    rel8 = UsersGames(score= 4000, place=1)
    rel8.player = a
    rel8.game = b

    db.session.commit()

if __name__ == "__main__":
    # execute only if run as a script
    create_users()
    create_games()
    assign()