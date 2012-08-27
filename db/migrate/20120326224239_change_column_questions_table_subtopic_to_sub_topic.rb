class ChangeColumnQuestionsTableSubtopicToSubTopic < ActiveRecord::Migration
  def up
   rename_column :questions, :subtopic_id, :sub_topic_id
  end

  def down
  end
end
