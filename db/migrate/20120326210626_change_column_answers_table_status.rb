class ChangeColumnAnswersTableStatus < ActiveRecord::Migration
  def up
     change_column :answers,  :status, :string , :default =>  "wrong"
  end

  def down
  end
end
