module Smurftp
  class Configuration
    attr_accessor :exclusions

    def initialize
      self.exclusions = {}
    end
  end
end