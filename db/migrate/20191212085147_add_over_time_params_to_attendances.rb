class AddOverTimeParamsToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :tommorow_index, :boolean
    add_column :attendances, :overtime_memo, :string
    add_column :attendances, :name, :string
  end
end
