require "rintel/version"
require "rintel/client"

module Rintel
  class GoogleLoginError < StandardError
  end

  class PlextsResponseError < StandardError
  end

  class EntitiesResponseError < StandardError
  end

  class PortalDetailsResponseError < StandardError
  end
end
