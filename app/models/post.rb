class Post

	attr_reader :id, :message, :date, :author_name, :author_id, :user_name, :user_id, :photo
	attr_accessor :comments

	def initialize(hash)
		@id = hash["id"]
		@message = hash["content"]
		@user_id = hash["user_id"]
		@user_name = hash["user_name"]
		@author_id = hash["author_id"]
		@author_name = hash["name"]
		@photo = hash["photo"]
		@date = DateTime.iso8601(hash["date"])
		@comments=[]
	end

	def pretty_date
		# @date.strftime("%b %d, %Y at %l:%M%p") if @date != nil
		a = (DateTime.now.to_time - @date.to_time).to_i

	    case a
	      when 0 then 'just now'
	      when 1 then 'a second ago'
	      when 2..59 then a.to_s+' seconds ago' 
	      when 60..119 then 'a minute ago' #120 = 2 minutes
	      when 120..3540 then (a/60).to_i.to_s+' minutes ago'
	      when 3541..7100 then 'an hour ago' # 3600 = 1 hour
	      when 7101..82800 then ((a+99)/3600).to_i.to_s+' hours ago' 
	      when 82801..172000 then 'a day ago' # 86400 = 1 day
	      when 172001..518400 then ((a+800)/(60*60*24)).to_i.to_s+' days ago'
	      when 518400..1036800 then 'a week ago'
	      else ((a+180000)/(60*60*24*7)).to_i.to_s+' weeks ago'
	    end
	end
	
end