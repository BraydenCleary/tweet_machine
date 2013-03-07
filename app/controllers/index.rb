before do
  session[:oauth] ||= {}

  host = request.host
  host << ":9292" if request.host == "localhost"

  consumer_key = ENV["TWITTER_KEY"]       # what twitter.com/apps says   
  consumer_secret = ENV["TWITTER_SECRET"] # shhhh, its a secret   

  @consumer = OAuth::Consumer.new(consumer_key, consumer_secret, :site => "https://api.twitter.com")

  # generate a request token for this user session if we haven't already
  request_token = session[:oauth][:request_token]   
  request_token_secret = session[:oauth][:request_token_secret]

  if request_token.nil? || request_token_secret.nil?
    # new user? create a request token and stick it in their session
    @request_token = @consumer.get_request_token(:oauth_callback => "http://#{host}/oauth")
    session[:oauth][:request_token] = @request_token.token
    session[:oauth][:request_token_secret] = @request_token.secret
  else
    # we made this user's request token before, so recreate the object
    @request_token = OAuth::RequestToken.new(@consumer, request_token, request_token_secret)
  end

  # this is what we came here for...   
  access_token = session[:oauth][:access_token]   
  access_token_secret = session[:oauth][:access_token_secret]
  unless access_token.nil? || access_token_secret.nil?
    # @access_token = OAuth::AccessToken.new(@consumer, access_token, access_token_secret)    
    @client = Twitter::Client.new oauth_token: access_token, oauth_token_secret: access_token_secret     
    if User.find_by_access_token(access_token) == nil
      user = User.create(:access_token => access_token, :access_token_secret => access_token_secret, :username => @client.user.username, :friend_count => @client.user.friend_count, :profile_image_url => @client.user.profile_image_url)
      session[:user_id] = user.id
    else
      user = User.find_by_access_token(access_token)
      session[:user_id] = user.id
    end  
  end
end

get '/' do
  session[:username] ||= @client.user.screen_name if @client
  @name = session[:username]
  erb :index
end

post '/tweets' do
  content_type :json
  begin
    @user = User.find(session[:user_id])
    id = @user.tweet(params[:tweet], params[:delay])
    message = "success"
  rescue Twitter::Error::Forbidden
    message = "error"
  end
  {:sidekiq_id => id, :twitter_message => message, :status => "incomplete"}.to_json
end

get '/status/:job_id' do 
  content_type :json
  unless job_is_complete(params[:job_id])
    status = 'incomplete'
  else
    status = 'complete'
  end
  {sidekiq_status: status}.to_json
end

def job_is_complete(jid)
  queue = Sidekiq::Queue.new("default")
  working = Sidekiq::Workers.new
  return false if queue.find { |job| job.jid == jid }
  return false if working.find { |worker, info| info["payload"]["jid"] == jid }
  true
end

get "/request" do
  redirect @request_token.authorize_url
end

get "/oauth" do
  @access_token = @request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
  session[:oauth][:access_token] = @access_token.token
  session[:oauth][:access_token_secret] = @access_token.secret
  redirect "/"
end

delete '/signout' do
  session.clear
end
