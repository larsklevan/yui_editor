require 'erb'

config = File.dirname(__FILE__) + '/../../../config/yui_editor.yml'

unless File.exist? config
  config_template = IO.read(File.dirname(__FILE__) + '/yui_editor.yml.tpl')
  File.open(config, 'w') { |f| f << ERB.new(config_template).result }
end

puts IO.read(File.join(File.dirname(__FILE__), 'README'))
