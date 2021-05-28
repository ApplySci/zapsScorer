from mjserver.models import User, Game, UsersGames
from mjserver import db

def create_defaults():
    if 'query' in dir(User) and not User.query.get(0):
        db.session.add(User(user_id=0, name='unassigned'))
        db.session.add(User(user_id=-1, name='player 1'))
        db.session.add(User(user_id=-2, name='player 2'))
        db.session.add(User(user_id=-3, name='player 3'))
        db.session.add(User(user_id=-4, name='player 4'))
        azps = User(name='azps', pin='1234')
        azps.set_password('azps')
        db.session.add(azps)
        db.session.commit()

if __name__ == "__main__":
    # execute only if run as a script
    create_defaults()
