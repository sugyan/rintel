#!/usr/bin/env ruby

require 'rintel'
require 'dotenv'
require 'time'

Dotenv.load
client = Rintel::Client.new(
  ENV['GOOGLE_USERNAME'],
  ENV['GOOGLE_PASSWORD'],
)

maxTimestampMs = nil
3.times do
  payload = {
    "maxLatE6" => 35660300,
    "maxLngE6" => 139704829,
    "minLatE6" => 35656734,
    "minLngE6" => 139697839,
    "tab" => "all",
  }
  payload["maxTimestampMs"] = maxTimestampMs - 1 if maxTimestampMs

  client.plexts(payload).each do |data|
    plext = data[2]["plext"]
    player  = plext["markup"].select{|e| e[0] == "PLAYER"}[0]
    portals = plext["markup"].select{|e| e[0] == "PORTAL"}
    puts '%s - %s [player: %s(%s), portal: %s]' % [
      Time.at(data[1] / 1000.0),
      plext["text"],
      player[1]["plain"],
      player[1]["team"],
      portals.map{|p| "%s(%f, %f)" % [p[1]["name"], p[1]["latE6"] / 1e6, p[1]["lngE6"] / 1e6] }.join(", "),
    ]
    maxTimestampMs = maxTimestampMs ? [maxTimestampMs, data[1]].min : data[1]
  end

  sleep 1
end
