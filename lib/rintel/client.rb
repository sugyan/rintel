require 'logger'
require 'mechanize'
require 'pathname'
require 'tmpdir'

module Rintel
  class Client

    @@cookie_path = Pathname.new(Dir.tmpdir) + 'rintel_cookie.yml'

    def initialize(username, password)
      @username = username
      @password = password
      @agent = Mechanize.new
      @agent.user_agent_alias = 'Windows Chrome'
      @log = Logger.new(STDERR)

      if File.exists?(@@cookie_path)
        @agent.cookie_jar.load(File.new(@@cookie_path))
      end
    end

    def login
      @agent.cookie_jar.clear

      page = @agent.get('https://www.ingress.com/intel')
      page = @agent.click page.link_with(:text => /Sign in/)
      page = page.form_with(:action => /ServiceLoginAuth/) do |form|
        form.Email  = @username
        form.Passwd = @password
      end.click_button

      @agent.cookie_jar.save(@@cookie_path)
    end

    def csrftoken
      if @agent.cookie_jar.empty?
        login
      end
      @agent.cookies.find{|c| c.name == 'csrftoken' }.value
    end

    def plexts(payload)
      payload['v'] = v
      payload['tab'] ||= 'all'
      payload['minLatE6'] ||=  -90000000
      payload['minLngE6'] ||= -180000000
      payload['maxLatE6'] ||=   90000000
      payload['maxLngE6'] ||=  180000000
      payload['maxTimestampMs'] ||= -1
      payload['minTimestampMs'] ||= -1
      json = payload.to_json

      begin
        result = @agent.post 'https://www.ingress.com/r/getPlexts', json,
                  'Content-Type' => 'application/json; charset=UTF-8',
                  'x-csrftoken' => csrftoken
        data = JSON.parse(result.body)
        return data['success']
      rescue JSON::ParserError, Mechanize::ResponseCodeError => e
        p e
        @log.error('%s. login and retry...' % e.class)
        login && retry
      end
    end

    def v
      return @v if @v
      script = @agent.get 'https://www.ingress.com/jsc/gen_dashboard.js'
      @v = script.body.match(/v="([a-f0-9]{40})";/)[1]
    end
  end
end
