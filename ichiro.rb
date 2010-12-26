require 'rubygems'
require 'digest/md5'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'erb'

load 'config.rb'
load 'models.rb'
load 'funcs.rb'

enable :sessions

configure :production do
	not_found do
		erb :'404'
	end

	error do
		erb :'500'
	end
end

before do
	@resmode = false
	@resid = "0"
	@sysop = false
	
	if settings.sysop == "" then
		return displayerror("Please set a sysop password in config.rb")
	end
end

get %r{^/([A-Za-z0-9]+)/([0-9]+)/?} do |boarddir, res|
	@board = Board.first(:dir => boarddir)
	if @board then
		@resmode = true
		thread = PostThread.get(res)
		@resid = thread.id
		@threads = [ thread ]
		erb :board
	else
		return displayerror("No such board.")
	end
end

get %r{^/([A-Za-z0-9]+)/list/?} do |boarddir|
	@board = Board.first(:dir => boarddir)
	if @board then
		@threads = PostThread.all(:board_id => @board.id).list
		erb :list
	else
		return displayerror("No such board.")
	end
end

get "/manage" do
	erb :manage, :locals => {:page => ""}
end

get "/manage/:page" do |page|
	if page == "logout" then
		session["sysop"] = ""
	else
		if session["sysop"] == settings.sysop then
			if page == "newboard" && params["dir"] != nil && params["name"] != nil then
				board = Board.first(:dir => params["dir"])
				if board then
					return displayerror("A board with that directory already exists.")
				else
					board = Board.new
					board.attributes = { :name => params["name"], :dir => params["dir"], :header => "<h1>" + params["name"] + "</h1>" }
					if board.save then
						return displaymessage('Board successfully created.<br><a href="/' + params["dir"] + '/">Visit /' + params["dir"] + '/</a>')
					else
						return displayerror("Unable to create board.")
					end
				end
			elsif page == "delete" && params["thread"] != nil && params["post"] != nil then
				p params["thread"]
				thread = PostThread.get(params["thread"])
				if thread then
					if params["post"] == "0" then
						thread.posts.destroy
						thread.destroy
						return displaymessage("Thread deleted.")
					else
						post = thread.posts.first(:order => :id.asc, :offset => (params["post"].to_i - 1))
						if post then
							if !post.deleted then
								post.deleted = true
								post.save
								return displaymessage("Post deleted.")
							else
								return displayerror("Post has already been deleted.")
							end
						else
							return displayerror("Invalid post ID supplied.")
						end
					end
				else
					return displayerror("Invalid thread ID supplied.")
				end
			end
		end
	end
	erb :manage, :locals => {:page => page}
end

post "/manage" do
	if params["sysop"] != "" then
		if params["sysop"] == settings.sysop then
			session["sysop"] = params["sysop"]
			redirect '/manage'
		else
			return displayerror("Invalid sysop password.")
		end
	end
end

post "/post" do
	if params["board"] then
		@board = Board.first(:dir => params["board"])
	end
	
	if not @board then
		return displayerror("No such board.")
	end

	bump = true
	thread = false
	newthread = false
	if params["parent"] and params["parent"] != "0" then
		thread = PostThread.get(params["parent"])
		if thread then
			if params["email"].downcase == "sage" then
				bump = false
			end
		else
			return displayerror("No such thread.")
		end
	end
	
	if not thread then
		thread = PostThread.new
		thread.board = @board
		thread.lastbump = Time.now
		thread.subject = sanitizestr(params["subject"])
		if thread.subject == "" then
			return displayerror("Subject can not be blank.")
		end
	end
	
	message = formatstr(sanitizestr(params["message"]))
	if message == "" then
		return displayerror("Message can not be blank.")
	end
	
	post = Post.new
	post.attributes = { :postthread => thread, :time => Time.now, :ip => request.env["REMOTE_ADDR"], :name => sanitizestr(params["name"]), :email => sanitizestr(params["email"]), :message => message }
	
	if post.save then
		if bump && !thread.permasage then
			thread.lastbump = Time.now
		end
		if thread.save then
			redirect '/' + @board.dir + '/'
		else
			@error = ""
			thread.errors.each do |e|
				@error += e + "<br>"
			end
			erb :error
			halt
		end
	else
		return displayerror("Unable to save post.")
	end
end

get %r{^/([A-Za-z0-9]+)/([0-9\-l\,]+)/?} do |boarddir,modifier|
	# TODO
	@board = Board.first(:dir => boarddir)
	if @board then
		@threads = PostThread.all(:board_id => @board.id).board
		erb :board
	else
		erb :'404'
	end
end

get %r{^/([A-Za-z0-9]+)/?} do |boarddir|
	@board = Board.first(:dir => boarddir)
	if @board then
		@threads = PostThread.all(:board_id => @board.id).board
		erb :board
	else
		erb :'404'
	end
end

get "/" do
	erb :index
end