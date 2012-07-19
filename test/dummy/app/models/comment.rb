class Comment < ActiveRecord::Base
  belongs_to :user

  attr_accessible :name, :comment, :messaging_user_id, :votes

  validates :name, :comment, :messaging_user_id, :presence => true
end
