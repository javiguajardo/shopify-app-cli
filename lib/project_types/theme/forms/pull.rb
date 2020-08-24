module Theme
  module Forms
    class Pull < ShopifyCli::Form
      flag_arguments :theme_id, :password, :store

      def ask # TODO: move messages from create to forms
        self.store ||= CLI::UI::Prompt.ask(ctx.message('theme.forms.create.ask_store'), allow_empty: false)
        ctx.puts(ctx.message('theme.forms.create.private_app', self.store))
        self.password ||= CLI::UI::Prompt.ask(ctx.message('theme.forms.create.ask_password'), allow_empty: false)
        ctx.system(Themekit::THEMEKIT, "get --list ---store=#{store} --password=#{password}")
        self.theme_id ||= CLI::UI::Prompt.ask("theme id:") # TODO: change to multiple choice
      end
    end
  end
end
