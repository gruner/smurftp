Gem::Specification.new do |s|
  s.name = %q{smurftp}
  s.version = "0.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andrew Gruner"]
  s.date = %q{2009-02-05}
  s.default_executable = %q{smurftp}
  s.description = %q{Smurftp is a command-line utility that searches a specified directory and creates a queue of recently modified files for quickly uploading to a remote server over FTP.}
  s.email = %q{andrew@divineflame.com}
  s.executables = ["smurftp"]
  s.files = ["VERSION.yml", "README.mkdn", "bin/smurftp", "lib/smurftp", "lib/smurftp/shell.rb", "lib/smurftp/version.rb", "lib/smurftp/templates", "lib/smurftp/templates/smurftp_multisite_config.yaml", "lib/smurftp/templates/smurftp_config.yaml", "lib/smurftp/configuration.rb", "lib/smurftp.rb", "test/shell_test.rb", "test/configuration_test.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/divineflame/smurftp}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Command-line utility for uploading recently modified files to a server}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
    else
    end
  else
  end
end
