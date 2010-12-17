require 'rubygems'
require 'digest/md5'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'erb'

load 'models.rb'
# set :logging, :true

before do
	@resmode = false
	@resid = "0"
end

get "/" do
	@threads = PostThread.imageboard
	erb :index
end

get %r{/res/([0-9]+)} do |res|
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
	end
	
	if not thread then
		thread = PostThread.new
	end
	
	post = Post.new
	post.attributes = { :postthread => thread, :time => Time.now, :ip => request.env["REMOTE_ADDR"], :name => params["name"], :email => params["email"], :subject => params["subject"], :message => params["message"], :password => Digest::MD5.hexdigest(params["password"]) }
	
	if post.save then
		if bump then
			thread.lastbump = Time.now
		end
		thread.save
		
		redirect '/'
	end
end