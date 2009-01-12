-module Smurftp #:nodoc:
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 9
    TINY  = 4

    STRING = [MAJOR, MINOR, TINY].join('.')
    URLIFIED = STRING.tr('.', '_')

    # requirements_met? can take a hash with :major, :minor, :tiny set or
    # a string in the format "major.minor.tiny"
    def self.requirements_met?(minimum_version = {})
      major = minor = tiny = 0
      if minimum_version.is_a?(Hash)
        major = minimum_version[:major].to_i if minimum_version.has_key?(:major)
        minor = minimum_version[:minor].to_i if minimum_version.has_key?(:minor)
        tiny = minimum_version[:tiny].to_i if minimum_version.has_key?(:tiny)
      else
        major, minor, tiny = minimum_version.to_s.split('.').collect { |v| v.to_i }
      end
      met = false
      if Smurftp::VERSION::MAJOR > major
        met = true
      elsif Smurftp::VERSION::MAJOR == major
        if Smurftp::VERSION::MINOR > minor
          met = true
        elsif Smurftp::VERSION::MINOR == minor
          met = Smurftp::VERSION::TINY >= tiny
        end
      end
      met
    end
  end
end
