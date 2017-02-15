ActiveAdmin.register User do
  permit_params :name, :skip

  index do
    selectable_column
    id_column
    column :name
    column :skip
    column :created_at
    actions
  end

  filter :skip
  filter :created_at

  form do |f|
    f.inputs "Admin Details" do
      f.input :skip
    end
    f.actions
  end

end
