#!/usr/bin/env ruby
#
# Usage:
#   portal_info.rb PORTAL_LINK
#
# Example:
#   portal_info.rb 'https://www.ingress.com/intel?ll=35.658581,139.745433&z=19&pll=35.658598,139.745458'
#

require 'rintel'
require 'dotenv'
require 'uri'
require 'json'

Dotenv.load
client = Rintel::Client.new(
  ENV['GOOGLE_USERNAME'],
  ENV['GOOGLE_PASSWORD'],
)

portal_link = ARGV[0]

qs = Hash[ URI::decode_www_form(URI::parse(portal_link).query) ]
(lat, lng) = qs['pll'].split(',').map! {|d| d.to_f }
target_tile_key = Rintel.tile_key(lat, lng, 18)

entities = client.entities([target_tile_key])
if ENV['DUMP']
  puts JSON.pretty_generate(entities)
end

lati = lat.to_s.delete('.').to_i
lngi = lng.to_s.delete('.').to_i
guid = ''
portal_info = []
entities.each do |tile_key, data|
  data['gameEntities'].each do |entity|
    if entity[2][0] == 'p' && entity[2][2] == lati && entity[2][3] == lngi
      guid = entity[0]
      portal_info = client.portal_details(guid)
      break
    end
  end
end

puts <<EOP
name  : #{portal_info[8]}
guid  : #{guid}
belong: #{portal_info[1]}
owner : #{portal_info[14]}
level : #{portal_info[4]}
mods  :
EOP
portal_info[12].each_with_index do |mod, i|
  if mod.nil?
    puts "  #{i}"
  else
    puts "  #{i} #{mod[1]} (#{mod[2]})"
  end
end
