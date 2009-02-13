Gem::Specification.new do |s|
  s.name = %q{waldo}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Henry Wagner"]
  s.date = %q{2009-02-12}
  s.description = %q{Ruby gem to create a mosaic image from a series of smaller images.}
  s.email = %q{hjw3001@gmail.com}
  s.extra_rdoc_files = ["lib/waldo.rb", "README.rdoc"]
  s.files = ["init.rb", "lib/waldo.rb", "Rakefile", "README.rdoc", "Manifest", "waldo.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/hjw3001/waldo}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Waldo", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{waldo}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Ruby gem to create a mosaic image from a series of smaller images.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
    else
    end
  else
  end
end
