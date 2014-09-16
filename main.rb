require 'rack'
require 'typhoeus'
require 'json'
require 'ap'
require 'sqlite3'
require 'date'
require 'erubis'
require_relative 'social'


class App
    def initialize()
        @socialDb = Social::SocialDb.new
        @user_login = nil
        @user_display = nil
        @errors = []
        @user_posts = []
        @news = []
    end

	def call(env)

        request = Rack::Request.new(env)
        response = Rack::Response.new

        case request.path_info
        when '/', "/index" #OK
            @errors = []
            if @user_login
                @user_login.print
                @user_display = @user_login
                get_user_posts
                response.write render("index", {"posts" =>@user_posts})
            else
                response.redirect '/user/connect'
            end

        when '/user/search' #OK
            results = search_users(request)
            response.write render("user/search", {"users" =>results, "user_search" => request.GET['user_search']})

        when '/user/add_friend' #OK revoir html
            add_friend(request)
            response.redirect '/friends'

        when '/post/create' #OK
            create_post(request)
            if @user_display != @user_login
                response.redirect "/user/wall?id=#{@user_display.id}"
            else
                response.redirect '/index'
            end

        when '/friends'
            response.write render('friends')

        when '/user/wall'
            puts request.GET["id"]
            @user_display = @socialDb.get_user_by_id(request.GET["id"])
            get_user_posts
            response.write render('user/wall', {"friend" =>@user_display, "posts" =>@user_posts})

        when '/news'
            get_all_posts
            response.write render('news', {"posts" =>@user_posts})

        when '/user/connect' #OK
            response.write render('user/connect')

        when '/user/new' #OK
            response.write render "user/new"

        when '/user/create' #OK
            check_create_user_form(request)
            if @errors.empty?
                add_user(request)
                response.redirect '/index'
            else
                response.redirect '/user/new'
            end

        when '/user/login' #OK
            login(request)
            if @errors.empty?
                response.redirect '/index'
            else
                response.redirect '/user/connect'
            end

        when '/user/logout' #OK
            @user_login = nil
            response.redirect '/index'
        end
    
        response.finish

	end

    def check_create_user_form(request)
        ap request.POST
        @errors = []
        ["name", "email", "password"].each do |var|
            @errors << "#{var.capitalize} required" if (request.POST[var] == nil || request.POST[var] == "")
        end
        @errors << "Password confirmation does not match password" if (request.POST['password'] != request.POST['password_confirm'])
        @errors << "Email already exists" if @socialDb.user_email_exist?request.POST['email']
        @errors << "Name already exists" if @socialDb.user_name_exist?request.POST['name']
    end

    def add_user(request)
        @user_login = @socialDb.create_user(
                                request.POST['name'], 
                                request.POST['email'], 
                                request.POST['password']
                                )
    end

    def login(request)
        @errors = []
        if request.POST['email'] == "" or request.POST['password'] == ""
            @errors << "Please enter your e-mail and your password" 
        else
            @user_login = @socialDb.get_user_login(
                                    request.POST['email'], 
                                    request.POST['password']
                                    )
            if @user_login == nil
                @errors << "Wrong email or pasword"
            else
                @socialDb.load_friends(@user_login)
            end
        end
    end

    def search_users(request)
        puts "Search: #{request.GET['user_search']}"
        if request.GET['user_search'] != nil && request.GET['user_search'] != ""
            return @socialDb.find_users(request.GET['user_search'])
        else
            return []
        end
    end

    def create_post(request)
        @socialDb.create_post(@user_display.id, request.POST['message'], @user_login.id)
    end

    def get_user_posts
        @user_posts = @socialDb.get_user_posts(@user_display.id)
    end

    def get_all_posts
        @user_posts = @socialDb.get_news(@user_login)
    end

    def add_friend(request)
        @socialDb.add_friend(@user_login, request.GET['id'])
    end

    def render(name, locals={})
        locals["errors"] = @errors
        locals["user"] = @user_login
        file = File.read("views/"+name+".erb")
        Erubis::Eruby.new(file).result(locals)
    end

end


