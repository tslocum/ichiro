require 'rubygems'
require 'digest/md5'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'erb'
require 'maruku'

load 'config.rb'
load 'models.rb'
load 'funcs.rb'
# set :logging, :true

before do
	@resmode = false
	@resid = "0"
	@page = 0
	@pages = (PostThread.count.to_f / settings.threads.to_f).ceil
end

get "/" do
	@threads = PostThread.board(@page)
	erb :index
end

get %r{^/([0-9]+)} do |res|
	@resmode = true
	thread = Post.get(res).postthread
	@resid = thread.id
	@threads = [ thread ]
	erb :index
end

post "/post" do
	bump = true
	thread = false
	if params["parent"] and params["parent"] != "0" then
		thread = PostThread.get(params["parent"])
		if thread then
			if params["email"].downcase == "sage" then
				bump = false
			end
		end
	end
	
	if not thread then
		thread = PostThread.new
		thread.subject = sanitizestr(params["subject"])
	end
	
	post = Post.new
	post.attributes = { :postthread => thread, :time => Time.now, :ip => request.env["REMOTE_ADDR"], :name => sanitizestr(params["name"]), :email => sanitizestr(params["email"]), :message => formatstr(sanitizestr(params["message"])) }
	
	if post.save then
		if bump then
			thread.lastbump = Time.now
		end
		thread.save
		
		redirect '/'
	else
		post.errors.each do |e|
			p e
		end
		"Error"
	end
end