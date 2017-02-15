json.array!(@attendances) do |attendance|
  json.id attendance.id
  json.name attendance.user.name
  json.scheduled_at attendance.scheduled_at&.strftime('%R')
  json.late attendance.late?
end