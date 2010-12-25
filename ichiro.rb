require 'rubygems'
require 'digest/md5'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'erb'

load 'config.rb'
load 'models.rb'
load 'funcs.rb'
#set :logging, :true

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
end

get %r{^/([A-Za-z0-9]+)/([0-9]+)/?} do |boarddir, res|
	@board = Board.first(:dir => boarddir)
	if @board then
		@resmode = true
		thread = Post.get(res).postthread
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

=begin
get "/newboard" do
	board = Board.new
	board.attributes = { :name => "Testing", :dir => "test", :header => "<h1>Testing</h1>" }
	board.save
end
=end

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

get %r{^/([A-Za-z0-9]+)/?} do |boarddir|
	@board = Board.first(:dir => boarddir)
	if @board then
		@threads = PostThread.all(:board_id => @board.id).board
		erb :board
	else
		erb :'404'
	end
end