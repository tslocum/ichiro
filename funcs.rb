require 'digest/md5'

def sanitizestr (inputstr)
	return inputstr.strip.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
end

def threadsummary (thread)
	output = []
	posts = thread.posts.all(:order => :id.desc).all(:limit => settings.replies)
	posts.each do |post|
		output << post
	end
	output << thread.posts.first
	output.reverse
end

def formatstr (inputstr)
	allowedtags = ["b", "i", "u", "s", "sub", "sup"]
	allowedtags.each do |tag|
		inputstr.gsub!(/&lt;#{tag}&gt;(.+?)&lt;\/#{tag}&gt;/im, "<#{tag}>\\1</#{tag}>")
	end
	inputstr.gsub!("\n", "<br>")
	inputstr
end

def displayerror (message)
	@error = message
	erb :error
end

def displaymessage (message)
	@message = message
	erb :message
end