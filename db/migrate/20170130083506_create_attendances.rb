class CreateAttendances < ActiveRecord::Migration[5.0]
  def change
    create_table :attendances do |t|
      t.integer :user_id
      t.date :date
      t.datetime :scheduled_at
      t.datetime :attended_at

      t.timestamps

      t.index [:user_id, :date], unique: true
    end
  end
end
