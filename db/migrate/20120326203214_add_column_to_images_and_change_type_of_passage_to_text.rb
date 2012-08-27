class AddColumnToImagesAndChangeTypeOfPassageToText < ActiveRecord::Migration
  def change
    add_column :answers,  :answer_id, :integer
    change_column :passages,  :passage, :text
    change_column :answers,  :status, :string , :default =>  "wrong"
    change_column :answers,  :status, :string , :default =>  "no_ans"
  end
end
