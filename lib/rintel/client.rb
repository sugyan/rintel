require 'logger'
require 'mechanize'
require 'pathname'
require 'tmpdir'

module Rintel
  class Client

    @@cookie_path = Pathname.new(Dir.tmpdir) + 'rintel_cookie.yml'

    def initialize(username, password, restore_cookie = false)
      @username = username
      @password = password
      @agent = Mechanize.new
      @agent.user_agent_alias = 'Windows Chrome'
      @log = Logger.new(STDERR)

      if restore_cookie && File.exists?(@@cookie_path)
        @agent.cookie_jar.load(File.new(@@cookie_path))
      end
    end

    # Returns COMM messages
    def plexts(tab, options = {})
       begin
        login if csrftoken.nil?
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

        res = @agent.post 'https://www.ingress.com/r/getPlexts', payload,
                  'Content-Type' => 'application/json; charset=UTF-8',
                  'x-csrftoken' => csrftoken
        data = JSON.parse(res.body)
        if result = data['result']
          return result
        else
          raise PlextsResponseError
        end
      rescue JSON::ParserError, Mechanize::ResponseCodeError => e
        @log.error '%s. login and retry...' % e.class
        clear_cookie && retry
      rescue GoogleLoginError => e
        abort 'login failed.'
      end
    end

    # result.map:
    # {
    #   TILE_KEY: {
    #     'gameEntities': [
    #       [
    #         0: guid of portal
    #         1: ?
    #         2: [
    #           0: "p"(portal) | "e"(link) | "r"(CF)
    #           1: "R" | "E"
    #           2: lat
    #           3: lng
    #           4: lv
    #           5: %
    #           6: ?
    #           7: image URL
    #           8: portal name
    #           9: []
    #         ],
    #       ],
    #       ...
    #     ],
    #     'deletedGameEntityGuids': [ guid guid ... ],
    #   },
    #   TILE_KEY: {
    #     'error': 'TIMEOUT',
    #   },
    #   ...
    # }
    def entities(tile_keys = [])
      begin
        login if csrftoken.nil?
        payload = {
            'v'        => v,
            'tileKeys' => tile_keys,
        }.to_json
        res = @agent.post 'https://www.ingress.com/r/getEntities', payload,
                  'Content-Type' => 'application/json; charset=UTF-8',
                  'x-csrftoken' => csrftoken
        data = JSON.parse(res.body)
        if result = data['result']['map']
          return result
        else
          raise EntitiesResponseError
        end
      rescue JSON::ParserError, Mechanize::ResponseCodeError => e
        @log.error '%s. login and retry...' % e.class
        clear_cookie && retry
      rescue GoogleLoginError => e
        abort 'login failed.'
      end
    end

    # result:
    # [
    #   0: "p"
    #   1: "R" | "E"
    #   2: lat
    #   3: lng
    #   4: lv
    #   5: %
    #   6: ?
    #   7: image URL
    #   8: portal name
    #   9: [] (always blank?)
    #   10: ?
    #   11: ?
    #   12: [ MOD MOD ... ]
    #   13: [ RESONATOR RESONATOR RESONATOR ... ]
    #   14: owner agent name
    # ]
    #
    # MOD: null or Array
    # [
    #   0: agent name
    #   1: mods name
    #   2: grade ("COMMON", ...)
    #   3: { params of mod } ("MITIGATION", "REMOVAL_STICKINESS", ...)
    # ]
    #
    # RESONATORS: null or Array
    # [
    #   0: agent name
    #   1: lv
    #   2: energy
    # ]
    def portal_details(guid = '')
      begin
        login if csrftoken.nil?
        payload = {
            'v'    => v,
            'guid' => guid,
        }.to_json
        res = @agent.post 'https://www.ingress.com/r/getPortalDetails', payload,
                  'Content-Type' => 'application/json; charset=UTF-8',
                  'x-csrftoken' => csrftoken
        data = JSON.parse(res.body)
        if result = data['result']
          return result
        else
          raise PortalDetailsResponseError
        end
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

      if page.uri.to_s =~ /SecondFactor/
        print 'Input PIN => '
        pin = STDIN.gets.chomp
        page = page.form_with(:action => /SecondFactor/) do |form|
          form.smsUserPin = pin
          form.checkbox_with(name: 'PersistentCookie').check
        end.click_button
      end

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
      script = @agent.get 'https://www.ingress.com/intel'
      @v = script./('script').last.attributes['src'].value.match('/jsc/gen_dashboard_([a-f0-9]{40})\.js$')[1]
    end
  end
end
