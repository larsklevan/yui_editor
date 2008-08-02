
module YUIEditor
  mattr_accessor :default_config

  module ClassMethods
    def uses_yui_editor(options = {})
      yui_editor_options = options.delete(:options)
      proc = Proc.new do |c|
        c.instance_variable_set(:@yui_editor_options, yui_editor_options)
        c.instance_variable_set(:@uses_yui_editor, true)
      end
      before_filter(proc, options)
    end
  end

  def self.included(base)
    if YUIEditor.default_config.nil?
      config_file = File.join(RAILS_ROOT, 'config', 'yui_editor.yml')
      YUIEditor.default_config = File.readable?(config_file) ? YAML.load_file(config_file).symbolize_keys : {}  
    end

    base.extend(ClassMethods)
    base.helper YUIEditorHelper
  end

  module YUIEditorHelper
    attr_accessor :yui_default_options

    def using_yui_editor?
      !@using_yui_editor.nil?
    end

    def yui_editor_init(options = @yui_editor_options)
      options ||= {}
      version = options[:version] || '2.5.2'

      editor_selector = options.delete(:selector) || 'rich_text_editor'
      editor_class = options.delete(:editor_class) || 'Editor' #other valid option is SimpleEditor

      compression = RAILS_ENV == 'development' ? '' : '-min'

      result = ''
      result << stylesheet_link_tag("//yui.yahooapis.com/#{version}/build/assets/skins/sam/skin.css") + "\n"

      result << javascript_include_tag("//yui.yahooapis.com/#{version}/build/yahoo-dom-event/yahoo-dom-event.js") + "\n"
      result << javascript_include_tag("//yui.yahooapis.com/#{version}/build/element/element-beta#{compression}.js") + "\n"
      result << javascript_include_tag("//yui.yahooapis.com/#{version}/build/container/container_core#{compression}.js") + "\n"
      result << javascript_include_tag("//yui.yahooapis.com/#{version}/build/menu/menu#{compression}.js") + "\n"
      result << javascript_include_tag("//yui.yahooapis.com/#{version}/build/button/button#{compression}.js") + "\n"
      result << javascript_include_tag("//yui.yahooapis.com/#{version}/build/editor/editor-beta#{compression}.js") + "\n"
      result << javascript_include_tag("//yui.yahooapis.com/#{version}/build/connection/connection#{compression}.js") + "\n"

      js = <<JAVASCRIPT
YAHOO.util.Event.onDOMReady(function(){
  new YAHOO.util.Element(document.getElementsByTagName('body')[0]).addClass('yui-skin-sam');
  
  var textAreas = document.getElementsByTagName('textarea');
  for (var i=0; i<textAreas.length; i++) {
    var textArea = textAreas[i];
    if (new YAHOO.util.Element(textArea).hasClass('#{editor_selector}')) {
      var editor = new YAHOO.widget.#{editor_class}(textArea.id,{
        handleSubmit: true
      });
      //callbacks?
      editor.render();
    }
  }
});
JAVASCRIPT
#       
#       # this was adding an extra /li at the end of uls (see http://sourceforge.net/tracker/index.php?func=detail&aid=1926238&group_id=165715&atid=836476)
#       js << "YAHOO.widget.Editor.prototype.filter_invalid_lists = function(html) { return html; };\n"
# 
      result << javascript_tag(js)

      result
    end

    def include_yui_editor_if_used
      yui_editor_init if @uses_yui_editor
    end
  end
end

ActionController::Base.send(:include, YUIEditor)
ActionView::Base.send :include, YUIEditor::YUIEditorHelper