class AddChanges < ActiveRecord::Migration
  def up
    change_column :questions,  :ans_status, :string , :default =>  "no_ans"
    remove_column :answers ,  :answer_id
  end

  def down
  end
end
