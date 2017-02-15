class Administrator < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :omniauthable, 
  # :recoverable, :rememberable, :trackable and :validatable
  devise :database_authenticatable
end
