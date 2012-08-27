class Question < ActiveRecord::Base
  has_many :answers
  has_one :image
  belongs_to :sub_topic
  belongs_to :topic
  belongs_to :passage
end
