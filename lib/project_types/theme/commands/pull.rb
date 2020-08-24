# frozen_string_literal: true
module Theme
  module Commands
    class Pull < ShopifyCli::Command
      options do |parser, flags|
        parser.on('--password=PASSWORD') { |p| flags[:password] = p }
        parser.on('--store=STORE') { |url| flags[:store] = url }
        parser.on('--themeid=THEME_ID') { |id| flags[:theme_id] = id }
      end

      def call(args, _name)
        form = Forms::Pull.ask(@ctx, args, options.flags)
        return @ctx.puts(self.class.help) if form.nil?

        ShopifyCli::Project.write(@ctx,
                                  project_type: 'theme',
                                  organization_id: nil)

        Themekit.pull(@ctx, store: form.store, password: form.password, themeid: form.theme_id)
      end

      def self.help
        ShopifyCli::Context.message('theme.pull.help', ShopifyCli::TOOL_NAME, ShopifyCli::TOOL_NAME) # TODO: message
      end
    end
  end
end
