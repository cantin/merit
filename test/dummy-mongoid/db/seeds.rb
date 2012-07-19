commenter = MessagingUser.create(:name => 'the-commenter-guy')
social = MessagingUser.create(:name => 'social-skilled-man')
bored  = MessagingUser.create(:name => 'bored-or-speechless')

(1..9).each do |i|
  Comment.create(
    :name    => "Title #{i}",
    :comment => "Comment #{i}",
    :messaging_user_id => social.id,
    :votes   => 3
  )
  Comment.create(
    :name    => "Title #{i}",
    :comment => "Comment #{i}",
    :messaging_user_id => commenter.id
  )
end