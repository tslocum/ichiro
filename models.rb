require 'datamapper'

DataMapper.setup(:default, "sqlite3:ichiro.db")

class PostThread
	include DataMapper::Resource

	has n, :posts, 'Post',
		:parent_key => [ :id ],      # local to this model (Blog)
		:child_key  => [ :thread_id ],  # in the remote model (Post)
		:order => :id.asc
	
	property :id,			Serial,		:key => true
	property :lastbump,		DateTime
	property :permasage,	Boolean,	:default => false
	property :sticky,		Boolean,	:default => false
	
	def self.imageboard
		all(:order => :sticky.desc, :order => :lastbump.desc)
	end
end

class Post
	include DataMapper::Resource

	belongs_to :postthread, 'PostThread',
		:parent_key => [ :id ],       # in the remote model (Blog)
		:child_key  => [ :thread_id ],  # local to this model (Post)
		:required   => true
	
	property :id,		Serial
	property :time,		DateTime
	property :ip,		String,		:length => 15
	property :name,		String,		:length => 50
	property :trip,		String,		:length => 10
	property :email,	String,		:length => 50
	property :subject,	String,		:length => 50
	property :message,	String
	property :password,	String,		:length => 32
	property :file,		String,		:required => false
	property :filemd5,	String,		:length => 32,		:required => false
	property :filename,	String,		:length => 25,		:required => false
	property :filesize,	String,		:required => false
	property :width,	Integer,	:required => false
	property :height,	Integer,	:required => false
	property :twidth,	Integer,	:required => false
	property :theight,	Integer,	:required => false
end

DataMapper.auto_upgrade!