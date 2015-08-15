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

  ZOOM_TO_NUM_TILES_PER_EDGE = [64, 64, 64, 64, 256, 256, 256, 1024, 1024, 1536, 4096, 4096, 6500, 6500, 6500]

  def self.tile_key(lat, lng, zoom = 17, min_level = 0, max_level = 8, max_health = 100)
    z = ZOOM_TO_NUM_TILES_PER_EDGE[zoom] || 32000;
    lg = ((lng + 180) / 360 * z).to_i
    lt =  ((1 - Math.log(Math.tan(lat * Math::PI / 180) + 1 / Math.cos(lat * Math::PI / 180)) / Math::PI) / 2 * z).to_i

    return [zoom, lg, lt, min_level, max_level, max_health].join('_')
  end
end
