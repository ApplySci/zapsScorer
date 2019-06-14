from mjserver.models import User, Game, UsersGames
from mjserver import db

def create_defaults():
    if 'query' in dir(User) and not User.query.get(0):
        db.session.add(User(user_id=0, name='unassigned'))
        db.session.commit()
        
if __name__ == "__main__":
    # execute only if run as a script
    create_defaults()
