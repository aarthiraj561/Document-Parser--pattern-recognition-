class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.string :question
      t.integer :topic_id
      t.integer :subtopic_id
      t.string :direction
      t.integer :positive_id
      t.integer :negative_id
      t.string :difficulty_id
      t.integer :passage_id
      t.string :question_type
      t.string :ans_status

      t.timestamps
    end
  end
end
