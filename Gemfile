source 'http://rubygems.org'

# Declare your gem's dependencies in mound.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# jquery-rails is used by the dummy application
gem 'rainbow'
# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

group :test do
  # Yeah, minitest is bundled in 1.9, but we want newer goodness.
  gem 'minitest'
  gem 'minitest-reporters', '>= 0.8.0'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rake'
end

platforms :jruby do
  gem 'activerecord-jdbcsqlite3-adapter'
end

platforms :mri_19 do
  gem 'sqlite3'
end

group :development do
  platforms :mri_19 do
    gem 'debugger'
  end

end
