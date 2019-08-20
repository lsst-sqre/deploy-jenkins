# frozen_string_literal: true

require 'rake/clean'

EYAML_FILES = FileList['hieradata/**/*.eyaml']
CLEAN.include(EYAML_FILES.ext('.yaml'))

desc 'checkout eyaml keys'
task :checkoutkeys do |_t|
  c_dir = '.lsst-certs'
  s_dir = 'keys'
  lock_file = "#{c_dir}/.git/info/sparse-checkout"

  Dir.mkdir(c_dir) unless Dir.exist?(c_dir)
  unless File.exist?(lock_file)
    Dir.chdir(c_dir) do
      sh <<~TLS
        git init
        git remote add origin ~/Dropbox/lsst-sqre/git/lsst-certs.git
        git config core.sparseCheckout true
        echo "eyaml-keys/" >> .git/info/sparse-checkout
        git pull --depth=1 origin master
      TLS
    end
  end
  File.symlink("#{c_dir}/eyaml-keys", s_dir) unless Dir.exist?(s_dir)
end

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
  sh "eyaml #{t} --no-preamble #{args[:file]}"
  Rake::Task[:decrypt].invoke
end

task default: %i[
  checkoutkeys
  decrypt
]
