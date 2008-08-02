require 'erb'

config = File.dirname(__FILE__) + '/../../../config/yui_editor.yml'

unless File.exist? initializer
  initializer_template = IO.read(File.dirname(__FILE__) + '/yui_editor.yml.tpl')
  File.open(initializer, 'w') { |f| f << ERB.new(initializer_template).result }
end

puts IO.read(File.join(File.dirname(__FILE__), 'README'))
