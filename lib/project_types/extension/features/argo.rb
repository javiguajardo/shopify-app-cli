# frozen_string_literal: true
require 'base64'
require 'shopify_cli'
require 'json'

module Extension
  module Features
    class Argo
      include SmartProperties

      GIT_ADMIN_TEMPLATE = 'https://github.com/Shopify/argo-admin-template.git'
      GIT_CHECKOUT_TEMPLATE = 'https://github.com/Shopify/argo-checkout-template.git'

      ARGO_CHECKOUT_RENDERER_PACKAGE = '@shopify/argo-checkout'
      ARGO_ADMIN_RENDERER_PACKAGE = '@shopify/argo-admin'
      ARGO_RENDERER_PACKAGES = [ARGO_ADMIN_RENDERER_PACKAGE, ARGO_CHECKOUT_RENDERER_PACKAGE]

      LIST_COMMAND = %w(list).freeze
      NPM_LIST_PARAMETERS = %w(--json --prod=true --depth=0).freeze
      YARN_LIST_PARAMETERS = %w(--pattern).freeze

      SCRIPT_PATH = %w(build main.js).freeze

      class << self
        def admin
          @admin ||= Argo.new(
            setup: ArgoSetup.new(git_template: GIT_ADMIN_TEMPLATE),
            renderer_package: ARGO_ADMIN_RENDERER_PACKAGE,
          )
        end

        def checkout
          @checkout ||= Argo.new(
            setup: ArgoSetup.new(
              git_template: GIT_CHECKOUT_TEMPLATE,
              dependency_checks: [ArgoDependencies.node_installed(min_major: 10, min_minor: 16)]
            ),
            renderer_package: ARGO_CHECKOUT_RENDERER_PACKAGE,
          )
        end
      end

      property! :setup, accepts: Features::ArgoSetup
      property! :renderer_package, accepts: ARGO_RENDERER_PACKAGES

      def create(directory_name, identifier, context)
        setup.call(directory_name, identifier, context)
      end

      def config(context)
        filepath = File.join(context.root, SCRIPT_PATH)
        context.abort(context.message('features.argo.missing_file_error')) unless File.exist?(filepath)
        begin
          {
            renderer_version: extract_argo_renderer_version(context),
            serialized_script: Base64.strict_encode64(File.open(filepath).read.chomp),
          }
        rescue StandardError
          context.abort(context.message('features.argo.script_prepare_error'))
        end
      end

      private

      def extract_argo_renderer_version(context)
        js_system = ShopifyCli::JsSystem.new(ctx: context)
        result, error, _stat = js_system.call(
          yarn: [LIST_COMMAND, YARN_LIST_PARAMETERS, ARGO_CHECKOUT_RENDERER_PACKAGE],
          npm: [LIST_COMMAND, ARGO_ADMIN_RENDERER_PACKAGE, NPM_LIST_PARAMETERS],
          with_capture: true
        )
        context.abort(
          context.message('features.argo.dependencies.argo_renderer_package_error', error)
        ) unless error.nil?
        if renderer_package == ARGO_ADMIN_RENDERER_PACKAGE
          hash_contents = JSON.parse(result)
          version = hash_contents["dependencies"][renderer_package]["version"]
        elsif renderer_package == ARGO_CHECKOUT_RENDERER_PACKAGE
          packages = result.to_json.split('\n')
          packages.each do |package|
            if package.match(/#{renderer_package}@/)
              values = package.split('@')
              version = values[2]
            end
          end
        end
        version
      end
    end
  end
end
