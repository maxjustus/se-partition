$LOAD_PATH.unshift 'lib'

Gem::Specification.new do |s|
  s.name              = "se-partition"
  s.version           = '0.0.1'
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Automagic database partitioning plugin for Postgres."
  s.homepage          = "http://github.com/maxjustus/se-partition"
  s.email             = "maxjustus@gmail.com"
  s.authors           = [ "Max Spransy" ]
  s.has_rdoc          = false

  s.files             = %w( README.md )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("man/**/*")
  s.files            += Dir.glob("test/**/*")

  s.description       = <<desc
  Automagic database partitioning plugin for Postgres.
desc
end