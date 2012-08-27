class CreateSubTopics < ActiveRecord::Migration
  def change
    create_table :sub_topics do |t|
      t.string :subtopic
      t.integer :topic_id

      t.timestamps
    end
  end
end
