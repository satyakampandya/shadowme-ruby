require 'erb'

module ShadowMe
  class AdminView
    def self.render(api_key:)
      template_path = File.expand_path('admin.html.erb', __dir__)
      template = File.read(template_path)
      ERB.new(template).result_with_hash(api_key: api_key)
    end
  end
end
