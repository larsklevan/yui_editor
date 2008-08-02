module YuiEditor
  mattr_accessor :default_options
  BUTTONS = %w{fontname fontsize bold italic underline subscript superscript forecolor backcolor removeformat hiddenelements justifyleft justifycenter justifyright justifyfull heading indent outdent insertunorderedlist insertorderedlist createlink insertimage}

  module ClassMethods
    def uses_yui_editor(options = {})
      yui_editor_options = options.delete(:editor)
      proc = Proc.new do |c|
        c.instance_variable_set(:@yui_editor_options, yui_editor_options)
        c.instance_variable_set(:@uses_yui_editor, true)
      end
      before_filter(proc, options)
    end
  end

  def self.included(base)
    if YuiEditor.default_options.nil?
      config_file = File.join(RAILS_ROOT, 'config', 'yui_editor.yml')
      YuiEditor.default_options = File.readable?(config_file) ? YAML.load_file(config_file).symbolize_keys : {}  
    end

    base.extend(ClassMethods)
    base.helper YuiEditorHelper
  end

  module YuiEditorHelper
    def using_yui_editor?
      !@using_yui_editor.nil?
    end

    def yui_editor_init
      options = YuiEditor.default_options.merge(@yui_editor_options || {})

      version = options.delete(:version) || '2.5.2'
      editor_selector = options.delete(:selector) || 'rich_text_editor'
      editor_class = options.delete(:simple_editor) ? 'SimpleEditor' : 'Editor'
      callbacks = (options.delete(:editor_extension_callbacks) || '')
      body_class = options.delete(:body_class) || 'yui-skin-sam'

      compression = RAILS_ENV == 'development' ? '' : '-min'

      result = ''
      result << stylesheet_link_tag("//yui.yahooapis.com/#{version}/build/assets/skins/sam/skin.css") + "\n" if body_class == 'yui-skin-sam'
      
      result << javascript_include_tag("//yui.yahooapis.com/#{version}/build/yahoo-dom-event/yahoo-dom-event.js") + "\n"
      %w{element/element-beta container/container_core menu/menu button/button editor/editor-beta connection/connection}.each do |script|
        result << javascript_include_tag("//yui.yahooapis.com/#{version}/build/#{script}#{compression}.js") + "\n"
      end
      (options[:editor_extension_javascripts] || []).each do |js|
        result << javascript_include_tag(js) + "\n"
      end

      js = <<JAVASCRIPT
YAHOO.util.Event.onDOMReady(function(){
  new YAHOO.util.Element(document.getElementsByTagName('body')[0]).addClass('#{body_class}');
  
  var textAreas = document.getElementsByTagName('textarea');
  for (var i=0; i<textAreas.length; i++) {
    var textArea = textAreas[i];
    if (new YAHOO.util.Element(textArea).hasClass('#{editor_selector}')) {
      var editor = new YAHOO.widget.#{editor_class}(textArea.id,#{options[:editor_config_javascript] || '{}'});
      #{callbacks};
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

ActionController::Base.send(:include, YuiEditor)
ActionView::Base.send :include, YuiEditor::YuiEditorHelper