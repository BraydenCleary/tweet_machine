var TweetForm = {
  init: function(){
    $('#tweet-form').on('submit',function(e){
      e.preventDefault();

      TweetForm.handleTweet();
    }); 
  },

  tweet: function() {
    return $('#tweet-form').children("textarea[name=tweet]").val();
  },

  delay: function() {
    return $('#tweet-form').find("select[name=time]").val();
  },

  reset: function() {
    $('#tweet-form').children("textarea[name=tweet]").val(''); 
    $('div.spinner').toggle(); 
  },

  success: function() {
    $('.messages').html('Tweet it up!!!');
  },

  validate: function(tweet){
    if (tweet === "") return false;
    return true;
  },

  insertError: function(){
    $('.messages').html('Invalid Tweet.');
  },

  checkFormStatus: function(sidekiq_id){
    $.get('/status/' + sidekiq_id, function(data){
      if(data['sidekiq_status'] == 'complete') {
        console.log('this should not fire')
        TweetForm.success();
      } else {
        console.log('incomplete');
        $('.messages').append('checking sidekiq');
        setTimeout(function() { TweetForm.checkFormStatus(sidekiq_id)}, 500);
      }
    });
  },

  post: function(){
    $('.load').toggle();
    $.ajax({
      type: "POST",
      url: "/tweets",
      data: { tweet: TweetForm.tweet(), delay: TweetForm.delay() },
    }).done(function(response) {
      TweetForm.reset();
      setTimeout(function() { TweetForm.checkFormStatus(response['sidekiq_id'])}, 50);
    });
  },

  handleTweet: function() {
    if (TweetForm.validate(TweetForm.tweet())){
      TweetForm.post();
    } 
    else {
      TweetForm.insertError();
    }
  }
};

$(document).ready(function(){
  TweetForm.init();

  $("#signout").on("click", function(e){
    e.preventDefault();

    $.ajax({
      type: "DELETE",
      url: "/signout"
    }).done(function(data){
      console.log("done");
      $(location).attr("href", "/");
    });
  });


});
