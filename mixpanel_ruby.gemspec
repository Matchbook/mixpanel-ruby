Gem::Specification.new do |s|
  s.name     = 'mixpanel_ruby'
  s.version  = '0.1'
  s.platform = Gem::Platform::RUBY
  s.homepage = 'https://github.com/Matchbook/mixpanel_ruby'
  s.summary  = 'Mixpanel API'
  s.author   = 'Matchbook'
  s.email    = 'proxy@matchbook.co'

  s.files        = Dir.glob('lib/*') + %w(README.md)
  s.require_path = 'lib'
end
