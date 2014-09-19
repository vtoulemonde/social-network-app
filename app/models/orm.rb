class ORM
	
	attr_reader :db

	SQL_INSERT_USER = "INSERT INTO users (name, email, password, photo) VALUES (?, ?, ?, ?);"
	SQL_GET_USER_BY_LOGIN = "SELECT * FROM users WHERE email = ? and password = ?;"
	SQL_GET_USER_BY_ID = "SELECT * FROM users WHERE id = ?;"
	SQL_USER_EMAIL_EXIST = "SELECT count(*) FROM users WHERE email = ?;"
	SQL_USER_NAME_EXIST = "SELECT count(*) FROM users WHERE name = ?;"
	SQL_ADD_FRIEND = "INSERT INTO friends (user_id_1, user_id_2, status) VALUES (?, ?, ?);"
	SQL_SELECT_FRIENDS1 = "SELECT users.* FROM users INNER JOIN friends ON friends.user_id_1 = users.id WHERE friends.user_id_2 = ?;"
	SQL_SELECT_FRIENDS2 = "SELECT users.* FROM users INNER JOIN friends ON friends.user_id_2 = users.id WHERE friends.user_id_1 = ?;"
	SQL_INSERT_POST = "INSERT INTO posts (user_id, content, author_id, date) VALUES (?, ?, ?, ?);"
	SQL_SELECT_USER_POSTS = "SELECT posts.*, users.name, users.photo FROM posts INNER JOIN users ON users.id = posts.author_id WHERE user_id = ? ORDER BY date DESC;"
	SQL_SELECT_POST_BY_ID = "SELECT * FROM posts INNER JOIN users ON users.id = posts.author_id WHERE posts.ID = ?;"
	SQL_SELECT_FRIENDS_POST = "SELECT * FROM posts WHERE posts.user_id in (?) ORDER BY date DESC;"
	SQL_UPDATE_USER = "UPDATE users SET name = ?, email = ?, photo= ?, description=? WHERE id =?;"
	SQL_UPDATE_PASSWORD = "UPDATE users SET password = ? WHERE id =?;"
	SQL_SELECT_ALL_USERS = "SELECT * FROM users ORDER BY name;"
	SQL_SELECT_COMMENTS = "SELECT comments.*, users.name, users.photo FROM comments INNER JOIN users ON users.id = comments.author_id WHERE post_id = ?;"
	SQL_INSERT_COMMENT = "INSERT INTO comments (post_id, content, author_id, date) VALUES (?, ?, ?, ?);"
	SQL_DELETE_POST = "DELETE FROM posts WHERE id=?;"
	SQL_DELETE_POST_COMMENTS = "DELETE FROM comments WHERE post_id = ?;"
	SQL_DELETE_FRIEND = "DELETE FROM friends WHERE user_id_1=? AND user_id_2=?;"

	def initialize(db_path = "app/data/social.db")
		@db = SQLite3::Database.new(db_path)
		@db.execute 'PRAGMA foreign_keys = true;'
		@db.results_as_hash = true
	end

	def user_email_exist?(email)
		result = @db.get_first_value SQL_USER_EMAIL_EXIST, [email]
		return result.to_i > 0
	end

	def user_name_exist?(name)
		result = @db.get_first_value SQL_USER_NAME_EXIST, [name]
		return result.to_i > 0
	end

	def create_user(name, email, password)
		@db.execute SQL_INSERT_USER, [name, email, password, "no_photo.jpg"]
		return get_user_login(email, password)
	end

	def get_user_login(email, password)
		row = @db.get_first_row SQL_GET_USER_BY_LOGIN, [email, password]
		return nil if row == nil
		User.new row
	end

	def get_user_by_id(id)
		row = @db.get_first_row SQL_GET_USER_BY_ID, [id]
		return nil if row == nil
		User.new row
	end

	def find_users(criteria)
		sql_request = "SELECT * FROM users WHERE name LIKE '%#{criteria}%' or email = ? ORDER BY name;"
		results = @db.execute sql_request, [criteria]
		results.map do |row|
			User.new row
		end
	end

	def find_all_users
		results = @db.execute SQL_SELECT_ALL_USERS
		results.map do |row|
			User.new row
		end
	end

	def add_friend(user, user_id_to_connect)
		@db.execute SQL_ADD_FRIEND, [user.id, user_id_to_connect, 1]
	end

	def delete_friend(user, friend_id)
		@db.execute SQL_DELETE_FRIEND, [user.id, friend_id]
		@db.execute SQL_DELETE_FRIEND, [friend_id, user.id]
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

	def update_user(user)
		@db.execute SQL_UPDATE_USER, [user.name, user.email, user.photo, user.description, user.id]
	end

	def update_password(user, password)
		@db.execute SQL_UPDATE_PASSWORD, [password, user.id]
	end

	def create_post(user_id, message, author_id )
		post_date = DateTime.now
		@db.execute SQL_INSERT_POST, [user_id, message, author_id, post_date.to_s]
	end

	def get_user_posts(user_id)
		posts = []
		results = @db.execute SQL_SELECT_USER_POSTS, [user_id]
		results.each do |row|
			post = Post.new row
			get_post_comments(post)
			posts << post
		end
		posts
	end

	def get_all_posts(user)
		load_friends(user)
		ids_str = ""
		user.friends.each do |friend|
			ids_str += "#{friend.id}, "
		end
		ids_str += "#{user.id}"
		sql_request = "SELECT posts.* ,
								author.name as name,
								author.photo as photo,
								user_wall.name as user_name
							FROM posts 
							INNER JOIN users as author ON author.id = posts.author_id 
							INNER JOIN users as user_wall ON user_wall.id = posts.user_id 
							WHERE posts.user_id in (#{ids_str}) ORDER BY date DESC;"
		results = @db.execute sql_request
		posts = []
		results.each do |row|
			post = Post.new row
			get_post_comments(post)
			posts << post
		end
		posts
	end

	def get_post_comments(post)
		comments = []
		results = @db.execute SQL_SELECT_COMMENTS, [post.id]
		results.each do |row|
			comments << Comment.new(row)
		end
		post.comments = comments
	end

	def create_comment(post_id, content, author_id)
		post_date = DateTime.now
		@db.execute SQL_INSERT_COMMENT, [post_id, content, author_id, post_date.to_s]
	end

	def delete_post(id)
		@db.execute SQL_DELETE_POST_COMMENTS, [id]
		@db.execute SQL_DELETE_POST, [id]
	end

end