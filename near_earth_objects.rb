require 'faraday'
require 'figaro'
require 'pry'
# Load ENV vars via Figaro
Figaro.application = Figaro::Application.new(environment: 'production', path: File.expand_path('../config/application.yml', __FILE__))
Figaro.load

class NearEarthObjects
  def self.find_neos_by_date(date)
    {
      asteroid_list: formatted_asteroid_data(date),
      biggest_asteroid: largest_asteroid_diameter(date),
      total_number_of_asteroids: total_asteroid_count(date)
    }
  end

  def self.connect_to_api(date)
      conn = Faraday.new(
      url: 'https://api.nasa.gov',
      params: { start_date: date, api_key: ENV['nasa_api_key']}
    )
  end

  def self.parsed_asteroid_data(date)
    asteroids_list_data = connect_to_api(date).get('/neo/rest/v1/feed')
    JSON.parse(asteroids_list_data.body, symbolize_names: true)[:near_earth_objects][:"#{date}"]
  end

  def self.largest_asteroid_diameter(date)
    parsed_asteroid_data(date).max_by do |asteroid|
      diameter(asteroid)
    end
  end

  def self.total_asteroid_count(date)
    parsed_asteroid_data(date).length
  end

  def self.formatted_asteroid_data(date)
    parsed_asteroid_data(date).map do |asteroid|
      {
        name: asteroid[:name],
        diameter: "#{diameter(asteroid)} ft",
        miss_distance: "#{miss_distance(asteroid)} miles"
      }
    end
  end

  def self.diameter(asteroid)
    asteroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i
  end

  def self.miss_distance(asteroid)
    asteroid[:close_approach_data][0][:miss_distance][:miles].to_i
  end
end
