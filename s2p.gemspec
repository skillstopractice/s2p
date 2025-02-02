require_relative "lib/s2p/version"

PKG_FILES = Dir.glob([
  'bin/*',
  'lib/**/*.rb',
  'data/**/*',
  'examples/**/*',
  "LICENSE",
])

Gem::Specification.new do |s|
  s.name        = "s2p"
  s.version     = S2P::VERSION
  s.summary     = "Experimental dev utilies from skillstopractice.com"
  s.description = "Experimental dev utilies from skillstopractice.com. Will eventually find homes in their own gems if they pan out."
  s.authors     = ["Gregory Brown"]
  s.email       = "gregory@practicingdeveloper.com"
  s.files       = PKG_FILES

  s.licenses = ['MIT']
end
