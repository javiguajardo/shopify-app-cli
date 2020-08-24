# frozen_string_literal: true
module Theme
  class Project < ShopifyCli::ProjectType
    hidden_feature
    creator 'Theme App', 'Theme::Commands::Create'
    register_command('Theme::Commands::Serve', "serve")
    register_command('Theme::Commands::Pull', "pull")

    require Project.project_filepath('messages/messages')
    register_messages(Theme::Messages::MESSAGES)
  end

  module Commands
    autoload :Create, Project.project_filepath('commands/create')
    autoload :Pull, Project.project_filepath('commands/pull')
    autoload :Serve, Project.project_filepath('commands/serve')
  end

  module Tasks
    autoload :EnsureThemekitInstalled, Project.project_filepath('tasks/ensure_themekit_installed')
  end

  module Forms
    autoload :Create, Project.project_filepath('forms/create')
    autoload :Pull, Project.project_filepath('forms/pull')
  end

  autoload :Themekit, Project.project_filepath('themekit')
end
