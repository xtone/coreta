namespace :app do
  desc 'CYBOZUから出社予定を取得する'
  task import_cybozu: :environment do
    cybozu = Cybozu.new
    cybozu.login
    cybozu.get_schedules
  end
end
