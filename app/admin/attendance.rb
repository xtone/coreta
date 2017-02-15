ActiveAdmin.register Attendance do
  index do
    column :user_id
    column :date
    column :scheduled_at
    column :attended_at
    actions
  end

  filter :date
end