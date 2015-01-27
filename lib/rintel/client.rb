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

    # Returns COMM messages
    def plexts(tab, options = {})
      payload = {
        'v' => v,
        'tab' => tab,
        'minLatE6' =>  -90000000,
        'minLngE6' => -180000000,
        'maxLatE6' =>   90000000,
        'maxLngE6' =>  180000000,
        'maxTimestampMs' => -1,
        'minTimestampMs' => -1,
      }.merge(options).to_json

      begin
        login if csrftoken.nil?
        result = @agent.post 'https://www.ingress.com/r/getPlexts', payload,
                  'Content-Type' => 'application/json; charset=UTF-8',
                  'x-csrftoken' => csrftoken
        data = JSON.parse(result.body)
        return data['success']
      rescue JSON::ParserError, Mechanize::ResponseCodeError => e
        @log.error '%s. login and retry...' % e.class
        clear_cookie && retry
      rescue GoogleLoginError => e
        abort 'login failed.'
      end
    end

    private

    def clear_cookie
      @agent.cookie_jar.clear
    end

    def login
      clear_cookie

      page = @agent.get('https://www.ingress.com/intel')
      page = @agent.click page.link_with(:text => /Sign in/)
      page = page.form_with(:action => /ServiceLoginAuth/) do |form|
        form.Email  = @username
        form.Passwd = @password
      end.click_button

      if csrftoken
        @agent.cookie_jar.save(@@cookie_path)
      else
        raise GoogleLoginError
      end
    end

    def csrftoken
      token_cookie = @agent.cookies.find {|c| c.name == 'csrftoken' }
      token_cookie && token_cookie.value
    end

    def v
      return @v if @v
      script = @agent.get 'https://www.ingress.com/jsc/gen_dashboard.js'
      @v = script.body.match(/v="([a-f0-9]{40})";/)[1]
    end
  end
end
