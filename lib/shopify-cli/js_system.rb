require 'shopify_cli'

module ShopifyCli
  ##
  # ShopifyCli::JsSystem allows conditional system calls of npm or yarn commands.
  #
  class JsSystem
    include SmartProperties

    YARN_CORE_COMMAND = 'yarn'
    NPM_CORE_COMMAND = 'npm'

    class << self
      ##
      # Proxy to instance method `ShopifyCli::JsSystem.new.yarn?`
      #
      # #### Parameters
      # - `ctx`: running context from your command
      #
      # #### Example
      #
      #   ShopifyCli::JsSystem.yarn?(ctx)
      #
      def yarn?(ctx)
        JsSystem.new(ctx: ctx).yarn?
      end

      ##
      # Proxy to instance method `ShopifyCli::JsSystem.new.call`
      #
      # #### Parameters
      # - `ctx`: running context from your command
      # - `yarn`: The proc, array, or string command to run if yarn is available
      # - `npm`: The proc, array, or string command to run if npm is available
      #
      # #### Example
      #
      #   ShopifyCli::JsSystem.call(ctx, yarn: ['install', '--silent'], npm: ['install', '--no-audit'])
      #
      def call(ctx, yarn:, npm:)
        JsSystem.new(ctx: ctx).call(yarn: yarn, npm: npm)
      end
    end

    property :ctx, accepts: ShopifyCli::Context

    ##
    # Returns the name of the JS package manager being used
    #
    # #### Example
    #
    #   ShopifyCli::JsSystem.new(ctx: ctx).package_manager
    #
    def package_manager
      yarn? ? YARN_CORE_COMMAND : NPM_CORE_COMMAND
    end

    ##
    # Returns true if yarn is available and false otherwise
    #
    # #### Example
    #
    #   ShopifyCli::JsSystem.new(ctx: ctx).yarn?
    #
    def yarn?
      @has_yarn ||= begin
        _, status = CLI::Kit::System.capture2('which', 'yarn')
        File.exist?(File.join(ctx.root, 'yarn.lock')) && status.success?
      end
    end

    ##
    # Runs a command with the proper JS package manager depending on the result of `yarn?`
    #
    # #### Parameters
    # - `ctx`: running context from your command
    # - `yarn`: The proc, array, or string command to run if yarn is available
    # - `npm`: The proc, array, or string command to run if npm is available
    #
    # #### Example
    #
    #   ShopifyCli::JsSystem.new(ctx: ctx).call(yarn: ['install', '--silent'], npm: ['install', '--no-audit'])
    #
    def call(yarn:, npm:, with_capture: false)
      yarn? ? call_command(yarn, YARN_CORE_COMMAND, with_capture) : call_command(npm, NPM_CORE_COMMAND, with_capture)
    end

    private

    def call_command(command, core_command, with_capture)
      if command.is_a?(String) || command.is_a?(Array)
        with_capture ? call_with_capture(command, core_command) : call_without_capture(command, core_command)
      else
        command.call
      end
    end

    def call_with_capture(command, core_command)
      CLI::Kit::System.capture3(core_command, *command, chdir: ctx.root)
    end

    def call_without_capture(command, core_command)
      CLI::Kit::System.system(core_command, *command, chdir: ctx.root).success?
    end
  end
end
