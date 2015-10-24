
module JSON
  def self.parse_nil(json)
    JSON.parse(json) if json && json.length >= 2
  end
end

module Oj
  def self.load_nil(json)
    Oj.load(json) if json && json.length >= 2
  end
end

