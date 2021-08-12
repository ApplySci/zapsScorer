del mjserver\mj.sqlite
rmdir migrations\ /Q /S
flask db init
flask db migrate
flask db upgrade
py resetdb.py
../stop
../start
