class User < ActiveRecord::Base
  has_many :tweets

  def tweet(status, delay)
    if delay == nil
      TweetWorker.perform_async(self.id, status)
    else
      TweetWorker.perform_in(1.minute.from_now, self.id, status)
      puts "scheduling tweet for in 1 minute"
    end
  end

end


# id = user.tweet("djd")

# {:job_id => id}.to_json


# get('worker/d')
