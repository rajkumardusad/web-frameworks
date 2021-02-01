# frozen_string_literal: true

require 'git'

namespace :ci do
  task :matrix do
    base = ENV['BASE_COMMIT']
    last = ENV['LAST_COMMIT']
    frameworks = []

    files = []

    workdir = ENV.fetch('GITHUB_WORKSPACE') { Dir.pwd }
    if base && last
      git = Git.open(Dir.pwd)
      diff = git.gtree(last).diff(base).each { |diff| files << diff.path }
    end

    if files.empty?
      Dir.glob('*/*/config.yaml').each do |path|
        parts = path.split(File::SEPARATOR)
        frameworks << parts[0..1].join(File::SEPARATOR)
      end
    else
      files.each do |path|
        parts = path.split(File::SEPARATOR)

        next unless parts.last == 'config.yaml'

        if parts.count == 2
          Dir.glob("#{parts.first}/*/config.yaml").each do |subpath|
            subparts = subpath.split(File::SEPARATOR)
            frameworks << subparts[0..1].join(File::SEPARATOR)
          end
        else
          frameworks << parts[0..1].join(File::SEPARATOR)
        end
      end
    end

    matrix = { include: [] }
    frameworks.uniq.each do |framework|
      matrix[:include] << { directory: framework, framework: framework }
    end

    puts matrix.to_json
  end
end
