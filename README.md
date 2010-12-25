ichiro
====

Ruby/Sinatra BBS

Installing
------------

Replace "mytxtsite" with the name of the site you will be creating.

    $ git clone git://github.com/tslocum/ichiro.git mytxtsite
    $ cd mytxtsite
	$ cp config.default.rb config.rb
	$ nano config.rb
    $ heroku create mytxtsite
	$ git add -f config.rb
	$ git commit -m "heroku"
    $ git push heroku master
	
Updating
------------

	$ git pull
	$ git push heroku master