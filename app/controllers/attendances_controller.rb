class AttendancesController < ApplicationController
  def index
    respond_to do |format|
      format.json do
        @attendances = Attendance.where(date: Date.today, attended_at: nil)
                           .includes(:user)
                           .all
      end
      format.html {  }
    end
  end

  def update
    attendance = Attendance.find(params[:id])
    attendance.attend!
    head 200
  end
end
