module Smurftp
  class Configuration
    attr_accessor :exclusions, :queue_limit, :required

    def initialize
      self.exclusions = []
      self.required = %w[server server_root document_root login password]
      self.queue_limit = 15
    end
    
  end
end