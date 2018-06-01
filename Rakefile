# frozen_string_literal: true

require 'rake/clean'

EYAML_FILES = FileList['hieradata/**/*.eyaml']
CLEAN.include(EYAML_FILES.ext('.yaml'))

desc 'generate new eyaml keys'
task :createkeys do |t|
  sh "eyaml #{t}"
end

rule '.yaml' => '.eyaml' do |t|
  puts "#{t.name} #{t.source}"
  sh "eyaml decrypt -f #{t.source} > #{t.name}"
end

desc 'decrypt all eyaml files (*.eyaml -> *.yaml'
task decrypt: EYAML_FILES.ext('.yaml')

desc 'edit .eyaml file (requires keys)'
task :edit, [:file] do |t, args|
  sh "eyaml #{t} #{args[:file]}"
  Rake::Task[:decrypt].invoke
end

desc 'run librarian-puppet'
task :librarian do
  sh 'librarian-puppet install --destructive'
end

desc 'run puppet-lint'
task :puppet_lint do
  cmd = <<~PL
    puppet-lint --fail-on-warnings \
      jenkins_demo \
      environments/jenkins/manifests
  PL
  sh cmd do |ok, res|
    unless ok
      # exit without verbose rake error message
      exit res.exitstatus
    end
  end
end

task default: %i[
  decrypt
  librarian
]
