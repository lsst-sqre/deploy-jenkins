desc "generate new eyaml keys"
task :createkeys do |t|
  sh "eyaml #{t}"
end

desc "decrypt common.eyaml -> common.yaml"
task :decrypt do |t|
  sh "eyaml #{t} -f hieradata/common.eyaml > hieradata/common.yaml"
end

desc "edit common.eyaml (requires keys)"
task :edit do |t|
  sh "eyaml #{t} hieradata/common.eyaml"
  Rake::Task[:decrypt].invoke
end
