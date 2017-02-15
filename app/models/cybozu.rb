require 'faraday-cookie_jar'

class Cybozu
  LOGIN_FORM_PATH = '/login'
  LOGIN_JSON_PATH = '/api/auth/login.json'
  LOGIN_REDIRECT_PATH = '/api/auth/redirect.do'

  def initialize
    @scheme = ENV['CYBOZU_SCHEME'] || 'https'
    @host = ENV['CYBOZU_HOST']
    @admin_account = ENV['CYBOZU_ACCOUNT']
    @admin_password = ENV['CYBOZU_PASSWORD']
  end

  def scheme
    @scheme
  end

  def host
    @host
  end

  def admin_account
    @admin_account
  end

  def admin_password
    @admin_password
  end

  def base_url
    "#{@scheme}://#{@host}"
  end

  def connection
    @connection ||= Faraday::Connection.new(base_url) do |builder|
      builder.request :url_encoded
      builder.use :cookie_jar
      builder.options.params_encoder = Faraday::FlatParamsEncoder
      builder.adapter Faraday.default_adapter
    end
  end

  # ログインする
  def login
    response = connection.get(LOGIN_FORM_PATH)
    md = /cybozu\.data\.REQUEST_TOKEN = '([^']*)'/.match(response.body)
    raise 'Unknown request token' if md.nil?

    request_token = md[1]
    response = connection.post do |req|
      req.path = LOGIN_JSON_PATH
      req.headers['Referer'] = LOGIN_FORM_PATH
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        '__REQUEST_TOKEN__': request_token,
        keepUsername: false,
        password: admin_password,
        redirect: '',
        username: admin_account
      }.to_json
    end
    raise 'Login error' unless response.status == 200

    response = connection.post do |req|
      req.path = LOGIN_REDIRECT_PATH
      req.body = {
        username: admin_account,
        password: admin_password,
        redirect: base_url + '/'
      }.to_json
    end
    raise 'Login error' unless [200, 302].include?(response.status)
  end

  # 日付を指定して社員の出社予定を取得
  # @param [Date] date
  def get_schedules(date = Date.today)
    head = 0
    loop do
      rows = get_schedule_table_rows(date: date, head: head)
      break if rows.size.zero?
      rows.each do |tr|
        anchor = tr.css('td.usercell')[0].css('a')[0]
        user_id = anchor.get_attribute('href').match(/UID=(\d+)/).to_a[1].to_i
        user = User.find_or_create_by(id: user_id) do |user|
          user.name = anchor.content
        end
        next if user.skip
        col = tr.css('td.eventcell')[0]
        # 「休み」・「直行」が設定されていたら、Attendanceレコードを生成しない
        next if find_holiday(col)
        next if find_direct(col)
        # 出社予定時間取得
        time = get_scheduled_time(col)
        attendance = Attendance.where(user_id: user_id, date: date).first_or_create
        if time.present?
          attendance.scheduled_at = Time.zone.local(date.year, date.month, date.day, time[0], time[1])
          attendance.save!
        end
      end
      head += 50
    end
  end

  private

  # Cybozuのスケジュールを取得する
  # @param [Date] date 取得する日付。省略すると今日の日付になる
  # @param [Integer] head offset値
  # @return [Nokogiri::XML::Node]
  def get_schedule_table_rows(date: nil, head: 0)
    params = { 'page' => 'ScheduleIndex', 'Head' => head }
    params['Date'] = "da.#{date.strftime('%Y.%-m.%-d')}" if date.is_a?(Date)
    response = connection.get('/o/ag.cgi', params)
    html = response.body.force_encoding('UTF-8')
    doc = Nokogiri.HTML(html)
    doc.css('tr.eventrow')
  end

  # 出社予定時刻をDOMから抽出する
  # @param [Nokogiri::XML::Node] dom
  # @return [Integer, Integer] hour, minute
  def get_scheduled_time(dom)
    # [出社]タグの検索
    div = dom.css('div.scheduleMarkEventItem5')
    if div.size.positive?
      # Cybozuの時間設定がされているパターン
      span = div.css('span.eventDateTime')
      if span.size.positive?
        md = /\A(\d+):(\d+)/.match(span[0].content)
        return md[1].to_i, md[2].to_i
      end

      # Cybozuの時間設定はされていないがフリーテキストで時間が書かれているパターン
      anchor = div.css('a.event')
      if anchor.size.positive?
        time_str = anchor[0].content
        md = /(\d+)時/.match(time_str)
        return md[1].to_i, 0 if md.present?

        md = /(\d+):(\d+)/.match(time_str)
        return md[1].to_i, md[2].to_i if md.present?
      end
    end

    # [出社]タグ使われてない場合
    dom.css('div.scheduleMarkTitle0').each do |div|
      if /出社/.match(div.css('a.event')[0].content)
        span = div.css('span.eventDateTime')
        if span.size.positive?
          md = /\A(\d+):(\d+)/.match(span[0].content)
          return md[1].to_i, md[2].to_i
        end
      end
    end
    # 抽出できないならnilを返す
    nil
  end

  # 休日スケジュールが設定されているか？
  def find_holiday(dom)
    # [休日]タグの検索
    div = dom.css('div.scheduleMarkEventItem4')
    return true if div.size.positive?

    false
  end

  # 直行スケジュールが設定されているか？
  def find_direct(dom)
    dom.css('div.scheduleMarkTitle0').each do |div|
      return true if div.css('a.event')[0].content == '直行'
    end

    false
  end
end
