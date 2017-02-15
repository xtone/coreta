class Attendance < ApplicationRecord
  belongs_to :user

  scope :status_ok, -> { where('scheduled_at <= attended_at') }
  scope :status_late, -> { where('scheduled_at > attended_at') }

  # 出社する
  # @param [Time] at
  # @return [TrueClass]
  def attend!(at = Time.zone.now)
    update_attributes!(attended_at: at)
  end

  # 遅刻判定
  # @return [TrueClass | FalseClass]
  def late?
    return true if self.scheduled_at.nil?
    return Time.zone.now < self.scheduled_at if self.attended_at.nil?
    self.scheduled_at < self.attended_at
  end
end
