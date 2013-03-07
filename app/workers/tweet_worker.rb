class TweetWorker
  include Sidekiq::Worker

  def perform(user_id, status)
    user  = User.find(user_id)
    # tweet = user.tweets.find(tweet_id)
    puts "hey I'm posting to Twitter"
    access_token = user.access_token 
    access_token_secret = user.access_token_secret
    @client = Twitter::Client.new oauth_token: access_token, oauth_token_secret: access_token_secret     
    @client.update(status)
    puts "hey I just update Twitter"

    # set up Twitter OAuth client here
    # actually make API call
    # Note: this does not have access to controller/view helpers
    # You'll have to re-initialize everything inside here
  end
end
