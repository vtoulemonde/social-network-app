require 'minitest/autorun'
require 'sqlite3'
require 'rack'
require 'typhoeus'
require 'json'
require 'date'
require 'erubis'

require_relative '../app/models/orm'
require_relative '../app/models/post'
require_relative '../app/models/user'
require_relative '../app/models/comment'

class TestUsers < MiniTest::Unit::TestCase

    DB_PATH = "test_social.db"

    def setup
        if File.exist? DB_PATH
            File.delete DB_PATH
        end
        @orm = ORM.new(DB_PATH)
        @orm.db.execute_batch File.read('../app/data/schema.sql')
    end

    def test_create_user()
        result = @orm.create_user("Test", "test@mail.com", "test")
        assert_equal "Test", result.name
        assert_equal "test@mail.com", result.email
    end

    def test_user_email_exist()
        result = @orm.create_user("Test2", "test2@mail.com", "test2")
        assert_equal true, @orm.user_email_exist?("test2@mail.com")
        assert_equal false, @orm.user_email_exist?("valentine@mail.com")
    end

    def test_user_name_exist()
        assert_equal false, @orm.user_name_exist?("Test3")
        result = @orm.create_user("Test3", "test3@mail.com", "test3")
        assert_equal true, @orm.user_name_exist?("Test3")
    end

    def test_get_user_login
        @orm.create_user("Test4", "test4@mail.com", "test4")
        user = @orm.get_user_login("test4@mail.com", "test4")
        assert_equal "Test4", user.name
        assert_equal "test4@mail.com", user.email
    end

    def test_get_user_by_id
        @orm.create_user("Test5", "test5@mail.com", "test5")
        user1 = @orm.get_user_login("test5@mail.com", "test5")
        user2 = @orm.get_user_by_id(user1.id)
        assert_equal user1.name, user2.name
        assert_equal user1.email, user2.email
        assert_equal user1.id, user2.id
    end

    def test_find_users
        @orm.create_user("Lisa Pacino", "pacino@mail.com", "pacino")
        @orm.create_user("Pitt Lisa Fornel", "pitt@mail.com", "pitt")
        @orm.create_user("Brad Al", "lisa@mail.com", "pacino")
        @orm.create_user("July", "july@mail.com", "july")
        result = @orm.find_users("lisa")
        assert_equal 2, result.count
        result = @orm.find_users("july@mail.com")
        assert_equal 1, result.count
    end

    def test_friends
        kevin = @orm.create_user("Kevin Spacey", "kevin@mail.com", "kevin")
        robert = @orm.create_user("Robert Redfort", "robert@mail.com", "robert")
        meryl = @orm.create_user("Meryl Streep", "meryl@mail.com", "meryl")
        @orm.add_friend(kevin, robert.id)
        @orm.add_friend(kevin, meryl.id)
        assert_equal 2, kevin.friends.count
        @orm.load_friends(meryl)
        assert_equal 1, meryl.friends.count
    end

    def test_update_users
        user = @orm.create_user("Test6", "test6@mail.com", "test6")
        user.name = "Test7"
        user.email = "test7@mail.com"
        user.description = "I am Test7 now!"
        user.photo = "my_photo.jpg"
        @orm.update_user(user)
        new_user = @orm. get_user_by_id(user.id)

        assert_equal "Test7", new_user.name
        assert_equal "test7@mail.com", new_user.email
        assert_equal "my_photo.jpg", new_user.photo
        assert_equal "I am Test7 now!", new_user.description
        assert_equal user.id, new_user.id

        user_login = @orm.get_user_login("test7@mail.com", "test6")
        assert_equal user_login.id, user.id
    end

    def test_update_password
        user = @orm.create_user("Test8", "test8@mail.com", "test8")
        user.name = "Test7"
        user.email = "test7@mail.com"
        user.description = "I am Test7 now!"
        user.photo = "test7_photo.jpg"
        @orm.update_password(user, "new_password")
        new_user = @orm. get_user_by_id(user.id)

        # Test that nothing as change except the password
        assert_equal "Test8", new_user.name
        assert_equal "test8@mail.com", new_user.email
        assert_equal "no_photo.jpg", new_user.photo
        assert_equal nil, new_user.description
        assert_equal user.id, new_user.id

        user_login = @orm.get_user_login("test8@mail.com", "new_password")
        assert_equal user_login.id, user.id
    end

end

class TestPosts < MiniTest::Unit::TestCase

    DB_PATH = "test_social.db"

    def setup
        if File.exist? DB_PATH
            File.delete DB_PATH
        end
        @orm = ORM.new(DB_PATH)
        @orm.db.execute_batch File.read('../app/data/schema.sql')

        @kevin = @orm.create_user("Kevin Spacey", "kevin@mail.com", "kevin")
        @robert = @orm.create_user("Robert Redfort", "robert@mail.com", "robert")
        @meryl = @orm.create_user("Meryl Streep", "meryl@mail.com", "meryl")
        @orm.add_friend(@kevin, @robert.id)
        @orm.add_friend(@kevin, @meryl.id)
    end

    def create_post
        @orm.create_post(@kevin.id, "Post by kevin on kevin", @kevin.id)
        @orm.create_post(@kevin.id, "Post by kevin on kevin", @robert.id)
        @orm.create_post(@meryl.id, "Post by kevin on kevin", @kevin.id)
        @orm.create_post(@meryl.id, "Post by kevin on kevin", @meryl.id)

        result = get_user_posts(@kevin.id)
        assert_equal 2, result.count
        result = get_user_posts(@meryl.id)
        assert_equal 1, result.count
    end

    def get_all_post
        result = get_all_posts(@kevin.id)
        assert_equal 3, result.count
    end

end



