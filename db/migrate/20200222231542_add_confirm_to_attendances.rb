class AddConfirmToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :confirm, :integer, null: false ,default: 0
    add_column :attendances, :overtime_confirm, :integer, null: false ,default: 0
  end
end
