class ORM
	
	attr_reader :db

	SQL_CREATE_USER = "INSERT INTO users (name, email, password, photo) VALUES (?, ?, ?, ?);"
	SQL_GET_USER_BY_LOGIN = "SELECT * FROM users WHERE email = ? and password = ?;"
	SQL_GET_USER_BY_ID = "SELECT * FROM users WHERE id = ?;"
	SQL_USER_EMAIL_EXIST = "SELECT count(*) FROM users WHERE email = ?;"
	SQL_USER_NAME_EXIST = "SELECT count(*) FROM users WHERE name = ?;"
	SQL_ADD_FRIEND = "INSERT INTO friends (user_id_1, user_id_2, status) VALUES (?, ?, ?);"
	SQL_SELECT_FRIENDS1 = "SELECT users.id, users.name, users.email, users.photo FROM users INNER JOIN friends ON friends.user_id_1 = users.id WHERE friends.user_id_2 = ?;"
	SQL_SELECT_FRIENDS2 = "SELECT users.id, users.name, users.email, users.photo FROM users INNER JOIN friends ON friends.user_id_2 = users.id WHERE friends.user_id_1 = ?;"
	SQL_INSERT_POST = "INSERT INTO posts (user_id, content, author_id, date) VALUES (?, ?, ?, ?);"
	SQL_SELECT_USER_POSTS = "SELECT * FROM posts INNER JOIN users ON users.id = posts.author_id WHERE user_id = ? ORDER BY date DESC;"
	SQL_SELECT_POST_BY_ID = "SELECT * FROM posts INNER JOIN users ON users.id = posts.author_id WHERE posts.ID = ?;"
	SQL_SELECT_FRIENDS_POST = "SELECT * FROM posts WHERE posts.user_id in (?) ORDER BY date DESC;"
	SQL_UPDATE_USER = "UPDATE users SET name = ?, email = ? WHERE id =?;"
	SQL_UPDATE_PASSWORD = "UPDATE users SET password = ? WHERE id =?;"

	def initialize(db_path = "app/data/social.db")
		puts db_path
		@db = SQLite3::Database.new(db_path)
		@db.execute 'PRAGMA foreign_keys = true;'
		@db.results_as_hash = true
	end

	def user_email_exist?(email)
		result = @db.get_first_value SQL_USER_EMAIL_EXIST, [email]
		puts "user_email_exist = #{result}"
		return result.to_i > 0
	end

	def user_name_exist?(name)
		result = @db.get_first_value SQL_USER_NAME_EXIST, [name]
		puts "user_name_exist = #{result}"
		return result.to_i > 0
	end

	def create_user(name, email, password)
		@db.execute SQL_CREATE_USER, [name, email, password, "no_photo.jpg"]
		return get_user_login(email, password)
	end

	def get_user_login(email, password)
		row = @db.get_first_row SQL_GET_USER_BY_LOGIN, [email, password]
		return nil if row == nil
		User.new row
	end

	def get_user_by_id(id)
		row = @db.get_first_row SQL_GET_USER_BY_ID, [id]
		puts row
		return nil if row == nil
		User.new row
	end

	def find_users(criteria)
		sql_request = "SELECT * FROM users WHERE name LIKE '%#{criteria}%' or email = ?;"
		results = @db.execute sql_request, [criteria]
		results.map do |row|
			User.new row
		end
	end

	def add_friend(user, user_id_to_connect)
		@db.execute SQL_ADD_FRIEND, [user.id, user_id_to_connect, 1]
		load_friends(user)
	end

	def load_friends(user)
		users = []
		result = @db.execute(SQL_SELECT_FRIENDS1, [user.id])
		result.each do |row|
			users << User.new(row)
		end
		result = @db.execute(SQL_SELECT_FRIENDS2, [user.id])
		result.each do |row|
			users << User.new(row)
		end
		user.friends = users
	end

	def create_post(user_id, message, author_id )
		post_date = DateTime.now
		@db.execute SQL_INSERT_POST, [user_id, message, author_id, post_date.to_s]
	end

	def get_user_posts(user_id)
		results = @db.execute SQL_SELECT_USER_POSTS, [user_id]
		results.map do |row|
			Post.new row
		end
	end

	def get_news(user)
		ids_str = ""
		user.friends.each do |friend|
			ids_str += "#{friend.id}, "
		end
		ids_str += "#{user.id}"
		sql_request = "SELECT posts.id, 
								posts.content, 
								posts.user_id, 
								posts.author_id, 
								posts.date, 
								author.name as name,
								user_wall.name as user_name
							FROM posts 
							INNER JOIN users as author ON author.id = posts.author_id 
							INNER JOIN users as user_wall ON user_wall.id = posts.user_id 
							WHERE posts.user_id in (#{ids_str}) ORDER BY date DESC;"
		puts sql_request
		results = @db.execute sql_request
		results.map do |row|
			Post.new row
		end
	
	end

	def update_user(user)
		@db.execute SQL_UPDATE_USER, [user.name, user.email, user.id]
	end

	def update_password(user, password)
		@db.execute SQL_UPDATE_PASSWORD, [password, user.id]
	end

end